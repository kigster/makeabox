import { Controller } from "@hotwired/stimulus"
import { isoBox, tabCount } from "lib/iso_box"
import { load, trace } from "lib/laser_trace"

const STORAGE_KEY = "makeabox:settings:v1"
const SIDES = ["width", "height", "depth"]
const MM_PER_INCH = 25.4
// Sheet thicknesses people actually buy, as [label, value].
const STOCK = {
  in: [["1/8″", 0.125], ["3/16″", 0.1875], ["1/4″", 0.25]],
  mm: [["3 mm", 3], ["4.5 mm", 4.5], ["6 mm", 6]]
}
const STEP = { in: { side: 0.25, thickness: 0.005, notch: 0.05 }, mm: { side: 5, thickness: 0.1, notch: 1 } }
// The narrowest notch worth cutting. The widest is a third of the shortest
// side; on a box too small for both, the narrowest is half the widest. Both
// ends are rounded down to NOTCH_SCALE, exactly as BoxRequest does.
const NOTCH_MIN = { in: 0.2, mm: 5 }
const NOTCH_SCALE = { in: 100, mm: 10 }
const MAX_NOTCHES = 150 // BoxRequest::MAX_NOTCHES
// The kerf slider runs from 0 to 0.1 in and says how a box usually fits: green
// from 0.026 to 0.045 in, yellow around that out to 0.02 and 0.065 in, red
// beyond. Less kerf is looser, more is tighter. Inches here, scaled for mm.
const KERF = { max: 0.1, green: [0.026, 0.045], yellow: [0.02, 0.065] }
const KERF_FIT = {
  red: ["Too loose, requires glue or screws", "Likely not fit at all"],
  yellow: ["Likely to be loose", "Likely to be too tight"],
  green: ["About just right", "About just right"]
}
const KERF_STEP = { in: 0.0005, mm: 0.01 }
// What "Reset to defaults" under Width puts back, in inches.
const STARTING_BOX = { width: 5, height: 4, depth: 3, thickness: 0.125, kerf: 0.026 }
const TRACE_MS = 1500

const clean = (number) => Number(number.toFixed(4))
// Reads a number the way the server does: a decimal comma is fine, "5 in" is not.
const parse = (text) => {
  const trimmed = String(text ?? "").trim().replace(",", ".")
  const value = trimmed === "" ? NaN : Number(trimmed)
  return Number.isFinite(value) ? value : NaN
}
// What an event from the stream carries. The server is ours, but a proxy in between is not.
const payload = (message) => { try { return JSON.parse(message.data) || {} } catch (error) { return {} } }
const STOPPED = "makeabox stopped answering. Try again in a moment."
const short = (name) => name.replace(/^box\[(.+)\]$/, "$1")
const label = (key) => (key === "thickness" ? "Thickness" : key[0].toUpperCase() + key.slice(1))

// The box form: keeps the preview in step with the fields, remembers the
// settings in this browser, and runs the Generate dialog.
export default class extends Controller {
  static targets = ["preview", "form", "hint", "number", "unit", "chips", "range", "units", "lid", "settings", "optional", "pageSize",
                    "go", "cut", "cutTitle", "cutMaterial", "drawing", "specs", "phase", "count", "bar", "download",
                    "kerfSlider", "kerfFit", "metadata"]
  static values = { settings: Object, streamUrl: String, downloadUrl: String, countUrl: String }

  connect() {
    this.unit = "in"
    this.hot = null
    this.restore()
    this.refresh()
    this.resized = new ResizeObserver(() => this.fit())
    this.resized.observe(this.formTarget)
  }

  disconnect() {
    this.stop()
    this.resized?.disconnect()
  }

  // ── reading the form ──

  get fields() {
    const fields = {}
    for (const [name, value] of new FormData(this.formTarget)) fields[short(name)] = value
    return fields
  }

  number(key) {
    return parse(this.fields[key]) || 0
  }

  input(key) {
    return this.formTarget.elements[`box[${key}]`]
  }

  get query() {
    const query = new URLSearchParams()
    for (const [name, value] of new FormData(this.formTarget)) if (value !== "") query.set(name, value)
    return query.toString()
  }

  problem() {
    for (const key of [...SIDES, "thickness"]) if (!(this.number(key) > 0)) return `${label(key)} needs a number above zero.`
    if (this.number("thickness") >= Math.min(...SIDES.map((key) => this.number(key)))) return "Thickness has to be smaller than the shortest side of the box."
    if (this.notchProblem()) return `Notch length has to be between ${this.notchRange().join(" and ")} ${this.unit}, or blank to let makeabox choose.`
    const notches = tabCount(Math.max(...SIDES.map((key) => this.number(key))), this.number("notch") || 3 * this.number("thickness"))
    if (notches > MAX_NOTCHES) return `That is ${notches} notches along the longest side, and ${MAX_NOTCHES} is the most we draw. Use thicker material or a longer notch.`
    return ""
  }

  // [narrowest, widest] notch, the same numbers as BoxRequest#notch_range.
  notchRange() {
    const scale = NOTCH_SCALE[this.unit], down = (value) => Math.floor(value * scale + 1e-6) / scale
    const widest = down(Math.min(...SIDES.map((key) => this.number(key))) / 3)
    return [Math.min(NOTCH_MIN[this.unit], down(widest / 2)), widest]
  }

  notchProblem() {
    if (String(this.fields.notch ?? "").trim() === "") return false
    const [narrowest, widest] = this.notchRange()
    return !(this.number("notch") >= narrowest - 1e-9 && this.number("notch") <= widest + 1e-9)
  }

  // Where a nudge or a drag starts from, and how far it may go.
  start(key) {
    return this.number(key) || (key === "notch" ? 3 * this.number("thickness") : 0)
  }

  clamp(key, value) {
    const [low, high] = key === "notch" ? this.notchRange() : [this.step(key), Infinity]
    return clean(Math.min(high, Math.max(low, value)))
  }

  // ── field events ──

  edit() {
    this.refresh()
  }

  focus(event) {
    this.hot = event.target.closest("[data-key]").dataset.key
    event.target.select()
    this.draw()
  }

  blur() {
    this.hot = null
    this.draw()
  }

  nudge(event) {
    if (event.key !== "ArrowUp" && event.key !== "ArrowDown") return
    event.preventDefault()
    const key = event.target.closest("[data-key]").dataset.key
    const by = this.step(key) * (event.shiftKey ? 4 : 1) * (event.key === "ArrowUp" ? 1 : -1)
    event.target.value = this.clamp(key, this.start(key) + by)
    this.refresh()
  }

  // Dragging a label left or right changes its number.
  scrub(event) {
    const label = event.currentTarget, key = label.closest("[data-key]").dataset.key, input = this.input(key)
    const from = event.clientX, base = this.start(key)
    event.preventDefault()
    label.setPointerCapture(event.pointerId)
    this.hot = key
    const move = (drag) => {
      input.value = this.clamp(key, base + Math.round((drag.clientX - from) / 6) * this.step(key))
      this.refresh()
    }
    label.addEventListener("pointermove", move)
    label.addEventListener("pointerup", () => {
      label.removeEventListener("pointermove", move)
      this.hot = null
      this.draw()
    }, { once: true })
  }

  // The slider writes the kerf into its field; the field is what is sent.
  slideKerf(event) {
    this.input("kerf").value = clean(Number(event.target.value))
    this.refresh()
  }

  // Back to a 5 × 4 × 3 in box of 1/8″ material with the default kerf.
  // Everything else on the form is left as it is.
  restart() {
    if (this.unit !== "in") this.pageSizeTarget.value = "" // a page size in mm has no match in inches
    this.unitsTargets.forEach((radio) => { radio.checked = radio.value === "in" })
    for (const [key, value] of Object.entries(STARTING_BOX)) this.input(key).value = value
    this.refresh()
  }

  stock(event) {
    const value = event.target.dataset.value
    if (!value) return
    this.input("thickness").value = value
    this.refresh()
  }

  convert(event) {
    const to = event.target.value
    if (to === this.unit) return
    const factor = to === "mm" ? MM_PER_INCH : 1 / MM_PER_INCH, digits = to === "mm" ? 2 : 4
    for (const input of [...this.numberTargets, ...this.optionalTargets]) {
      const value = parse(input.value)
      if (Number.isFinite(value)) input.value = Number((value * factor).toFixed(digits))
    }
    this.unit = to
    this.pageSizeTarget.value = ""
    this.refresh()
  }

  step(key) {
    return STEP[this.unit][key in STEP[this.unit] ? key : "side"]
  }

  // ── dialogs ──

  openSettings() {
    this.settingsTarget.showModal()
  }

  close(event) {
    event.target.closest("dialog").close()
  }

  // A click on the dialog itself, not its contents, landed on the backdrop.
  backdrop(event) {
    if (event.target === event.currentTarget) event.currentTarget.close()
  }

  reset() {
    try { localStorage.removeItem(STORAGE_KEY) } catch (error) { /* storage is optional */ }
    this.formTarget.reset()
    this.unit = "in"
    this.refresh()
  }

  // ── keeping the page in step ──

  refresh() {
    const unit = this.unit = this.unitsTargets.find((radio) => radio.checked)?.value || "in"
    this.unitTargets.forEach((element) => { element.textContent = unit })
    this.chipsTarget.replaceChildren(...STOCK[unit].map(([text, value]) => {
      const chip = document.createElement("button")
      chip.type = "button"
      chip.textContent = text
      chip.dataset.value = value
      chip.setAttribute("aria-pressed", Math.abs(value - this.number("thickness")) < 1e-6)
      return chip
    }))
    this.optionalTargets.forEach((input) => {
      const fallback = this.settingsValue.defaults[unit][short(input.name)]
      if (fallback !== undefined) input.placeholder = fallback
    })
    this.pageSizes(unit)
    this.kerf(unit)
    this.numberTargets.forEach((input) => input.closest(".field").classList.toggle("bad", !(parse(input.value) > 0)))
    this.rangeTarget.textContent = this.notchRange()[1] > 0 ? `${this.notchRange().join(" to ")} ${unit}` : ""
    this.rangeTarget.closest(".field").classList.toggle("bad", this.notchProblem())

    const problem = this.problem()
    this.hintTarget.textContent = problem
    this.goTarget.disabled = Boolean(problem)
    this.fit()
    this.draw()
    this.save()
  }

  // Long numbers, like 101.6 mm, shrink until they fit their field, down to
  // half the usual size. Each is measured in a hidden copy of its own font.
  fit() {
    const ruler = this.ruler ??= Object.assign(document.createElement("span"), { ariaHidden: "true" })
    ruler.style.cssText = "position: absolute; visibility: hidden; white-space: pre; left: -9999px"
    if (!ruler.isConnected) document.body.append(ruler)
    for (const input of this.formTarget.querySelectorAll(".num input")) {
      input.style.fontSize = input.style.paddingTop = ""
      const style = getComputedStyle(input)
      for (const property of ["fontFamily", "fontSize", "fontWeight", "fontStretch", "letterSpacing", "fontVariantNumeric"]) ruler.style[property] = style[property]
      ruler.textContent = input.value || input.placeholder
      const room = input.clientWidth, needed = ruler.getBoundingClientRect().width
      if (!(room > 0 && needed > room)) continue
      const full = parseFloat(style.fontSize), size = Math.max(0.5, (0.97 * room) / needed) * full
      input.style.fontSize = `${size}px`
      input.style.paddingTop = `${0.95 * (full - size)}px` // keeps it on the same baseline as its neighbours
    }
  }

  // Moves the slider to the kerf in the field, or the default when it is blank,
  // and colours it green, yellow or red.
  kerf(unit) {
    const slider = this.kerfSliderTarget, scale = unit === "mm" ? MM_PER_INCH : 1
    const field = this.input("kerf"), value = parse(field.value)
    const kerf = Number.isFinite(value) ? value : parse(field.placeholder) || 0
    Object.assign(slider, { max: KERF.max * scale, step: KERF_STEP[unit] })
    slider.value = kerf
    const inches = kerf / scale, within = ([low, high]) => inches >= low - 1e-9 && inches <= high + 1e-9
    const zone = slider.dataset.zone = within(KERF.green) ? "green" : within(KERF.yellow) ? "yellow" : "red"
    this.kerfFitTarget.textContent = KERF_FIT[zone][inches < KERF.green[0] ? 0 : 1]
    this.kerfFitTarget.dataset.zone = zone
  }

  pageSizes(unit) {
    const select = this.pageSizeTarget
    if (select.dataset.unit === unit) return
    const chosen = select.value
    select.replaceChildren(new Option("Fit the box", ""), ...this.settingsValue.pageSizes[unit].map(([name, width, height]) => new Option(`${name}  ${width} × ${height}`, name)))
    select.value = chosen
    select.dataset.unit = unit
  }

  // Only a box that passes problem() is drawn: the rest would be nonsense, or
  // so many notches that building the preview stalls the page.
  draw() {
    if (this.problem()) return
    const { viewBox, markup } = isoBox({
      width: this.number("width"), height: this.number("height"), depth: this.number("depth"), thickness: this.number("thickness"),
      notch: this.number("notch"), units: this.unit, lid: this.lidTarget.value, hot: this.hot
    })
    this.previewTarget.setAttribute("viewBox", viewBox)
    this.previewTarget.classList.toggle("hot-thickness", this.hot === "thickness" || this.hot === "notch")
    this.previewTarget.innerHTML = markup // numbers and fixed class names only, see iso_box.js
  }

  save() {
    try { localStorage.setItem(STORAGE_KEY, JSON.stringify(this.fields)) } catch (error) { /* storage is optional */ }
  }

  restore() {
    let saved = {}
    try { saved = JSON.parse(localStorage.getItem(STORAGE_KEY) || "{}") } catch (error) { return }
    if (!saved || typeof saved !== "object") return
    const unit = saved.units === "mm" ? "mm" : "in"
    this.unitsTargets.forEach((radio) => { radio.checked = radio.value === unit })
    this.pageSizes(unit) // the saved page size needs its option to exist first
    for (const [key, value] of Object.entries(saved)) {
      if (key === "metadata") { this.metadataTarget.checked = value !== "0"; continue }
      const field = this.input(key)
      if (!field || key === "units") continue
      field.value = value
      // A saved choice that is gone or disabled (a lid, a page size) falls back to the first one.
      if (field.tagName === "SELECT" && (field.selectedIndex < 0 || field.selectedOptions[0].disabled)) field.selectedIndex = 0
    }
  }

  // ── generating ──

  generate(event) {
    event.preventDefault()
    if (this.problem()) return
    this.stop()
    this.svg = null
    this.describe()
    this.downloadTargets.forEach((button) => { button.disabled = true })
    this.drawingTarget.replaceChildren()
    this.progress("Working out the tabs…", 0, 0)
    this.cutTarget.classList.remove("failed")
    this.cutTarget.showModal()

    this.source = new EventSource(`${this.streamUrlValue}?${this.query}`)
    this.source.addEventListener("progress", (message) => {
      const { done, total } = payload(message)
      if (total) this.progress("Working out the tabs…", done, total)
    })
    this.source.addEventListener("drawn", (message) => {
      const { svg, filename } = payload(message)
      this.source.close()
      if (!svg) return this.fail(STOPPED)
      this.svg = svg
      this.filename = filename
      try {
        const still = window.matchMedia("(prefers-reduced-motion: reduce)").matches
        this.cancelTrace = trace(load(this.drawingTarget, svg), {
          duration: still ? 0 : TRACE_MS,
          onStep: (done, total) => this.progress("Cutting…", done, total),
          onDone: () => this.ready()
        })
      } catch (error) {
        // The files are fine even when the picture of them is not.
        console.error(error)
        this.ready("Ready. The drawing could not be shown here, but the files are good.")
      }
    })
    this.source.addEventListener("failed", (message) => this.fail(payload(message).message || STOPPED))
    // Reached for a server that is down, a gateway error, or a stream cut short.
    this.source.onerror = () => { if (!this.svg) this.fail(STOPPED) }
  }

  describe() {
    const unit = this.unit, sides = SIDES.map((key) => this.number(key)).join(" × ")
    const tab = this.number("notch") ? `${this.number("notch")} ${unit}` : `auto, about ${clean(3 * this.number("thickness"))} ${unit}`
    this.cutTitleTarget.textContent = `${sides} ${unit} box`
    this.cutMaterialTarget.textContent = `${this.number("thickness")} ${unit} material`
    const rows = [["Inside", `${sides} ${unit}`], ["Material", `${this.number("thickness")} ${unit}`], ["Notch length", tab],
                  ["Top", this.lidTarget.selectedOptions[0].textContent], ["Page", this.pageSizeTarget.value || "fits the box"]]
    this.specsTarget.replaceChildren(...rows.flatMap(([term, detail]) => {
      const dt = document.createElement("dt"), dd = document.createElement("dd")
      dt.textContent = term
      dd.textContent = detail
      return [dt, dd]
    }))
  }

  progress(phase, done, total) {
    this.phaseTarget.textContent = phase
    this.countTarget.textContent = total ? `${done.toLocaleString()} of ${total.toLocaleString()} lines` : ""
    this.barTarget.style.width = total ? `${(done / total) * 100}%` : "0"
  }

  ready(text = "Ready") {
    this.phaseTarget.textContent = text
    this.downloadTargets.forEach((button) => { button.disabled = false })
    this.downloadTargets[0].focus()
  }

  fail(message) {
    console.error(`makeabox: ${message}`)
    this.stop()
    this.cutTarget.classList.add("failed")
    this.phaseTarget.textContent = message
    this.countTarget.textContent = ""
    this.barTarget.style.width = "0"
  }

  // The dialog's `close` event arrives a moment after it closes. By then the
  // next Generate may have reopened it, and that run must not be stopped.
  closed() {
    if (!this.cutTarget.open) this.stop()
  }

  stop() {
    this.source?.close()
    this.cancelTrace?.()
    this.source = this.cancelTrace = null
  }

  // The drawing is already in the browser, so the SVG is saved from memory.
  downloadSvg() {
    this.track("svg_download", this.filename)
    this.hand(new Blob([this.svg], { type: "image/svg+xml" }), this.filename)
    this.finish()
    this.countSvg()
  }

  // The PDF is drawn again on the server from the same settings. It is fetched
  // rather than navigated to, so a refusal shows in the dialog and not on a bare page.
  async downloadPdf(event) {
    const filename = this.filename.replace(/\.svg$/, ".pdf")
    this.track("pdf_download", filename)
    const button = event.currentTarget
    button.disabled = true
    try {
      const response = await fetch(`${this.downloadUrlValue}.pdf?${this.query}`)
      if (!response.ok) return this.fail(response.status === 422 ? await response.text() : STOPPED)
      this.hand(await response.blob(), filename)
      this.finish()
      this.counted() // the server counted the PDF as it sent it
    } catch (error) {
      this.fail(STOPPED)
    } finally {
      button.disabled = false
    }
  }

  // Hands the browser a file to save.
  hand(blob, filename) {
    const link = document.createElement("a")
    link.href = URL.createObjectURL(blob)
    link.download = filename
    link.click()
    setTimeout(() => URL.revokeObjectURL(link.href), 1000)
  }

  finish() {
    this.cutTarget.close()
  }

  // The server never sees an SVG saved from memory, so it is told. A count
  // that fails to arrive is not worth bothering anyone about.
  async countSvg() {
    const token = document.querySelector('meta[name="csrf-token"]')?.content
    try {
      await fetch(`${this.countUrlValue}?kind=svg`, { method: "POST", headers: { "X-CSRF-Token": token ?? "" } })
      this.counted()
    } catch {
      // The download itself already happened.
    }
  }

  // Tells the counter in the header to catch up.
  counted() {
    window.dispatchEvent(new CustomEvent("makeabox:downloaded"))
  }

  // Counts a click on a download button in Google Analytics, when it is loaded.
  // GA4 event names allow only letters, digits and underscores.
  track(name, filename) {
    window.gtag?.("event", name, { file_name: filename })
  }
}
