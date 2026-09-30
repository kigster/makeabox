import { Controller } from "@hotwired/stimulus"
import { isoBox } from "lib/iso_box"
import { load, trace } from "lib/laser_trace"

const STORAGE_KEY = "makeabox:settings:v1"
const SIDES = ["width", "height", "depth"]
const MM_PER_INCH = 25.4
// Sheet thicknesses people actually buy, as [label, value].
const STOCK = {
  in: [["1/8″", 0.125], ["3/16″", 0.1875], ["1/4″", 0.25]],
  mm: [["3 mm", 3], ["4.5 mm", 4.5], ["6 mm", 6]]
}
const STEP = { in: { side: 0.25, thickness: 0.005 }, mm: { side: 5, thickness: 0.1 } }
const TRACE_MS = 1500

const clean = (number) => Number(number.toFixed(4))
const short = (name) => name.replace(/^box\[(.+)\]$/, "$1")
const label = (key) => (key === "thickness" ? "Thickness" : key[0].toUpperCase() + key.slice(1))

// The box form: keeps the preview in step with the fields, remembers the
// settings in this browser, and runs the Generate dialog.
export default class extends Controller {
  static targets = ["preview", "form", "hint", "number", "unit", "chips", "units", "lid", "settings", "optional", "pageSize",
                    "go", "cut", "cutTitle", "cutMaterial", "drawing", "specs", "phase", "count", "bar", "download"]
  static values = { settings: Object, streamUrl: String, downloadUrl: String }

  connect() {
    this.unit = "in"
    this.hot = null
    this.restore()
    this.refresh()
  }

  disconnect() {
    this.stop()
  }

  // ── reading the form ──

  get fields() {
    const fields = {}
    for (const [name, value] of new FormData(this.formTarget)) fields[short(name)] = value
    return fields
  }

  number(key) {
    const value = parseFloat(String(this.fields[key] ?? "").replace(",", "."))
    return Number.isFinite(value) ? value : 0
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
    return ""
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
    event.target.value = clean(Math.max(this.step(key), this.number(key) + by))
    this.refresh()
  }

  // Dragging a label left or right changes its number.
  scrub(event) {
    const label = event.currentTarget, key = label.closest("[data-key]").dataset.key, input = this.input(key)
    const from = event.clientX, base = this.number(key)
    event.preventDefault()
    label.setPointerCapture(event.pointerId)
    this.hot = key
    const move = (drag) => {
      input.value = clean(Math.max(this.step(key), base + Math.round((drag.clientX - from) / 6) * this.step(key)))
      this.refresh()
    }
    label.addEventListener("pointermove", move)
    label.addEventListener("pointerup", () => {
      label.removeEventListener("pointermove", move)
      this.hot = null
      this.draw()
    }, { once: true })
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
      const value = parseFloat(input.value)
      if (Number.isFinite(value)) input.value = Number((value * factor).toFixed(digits))
    }
    this.unit = to
    this.pageSizeTarget.value = ""
    this.refresh()
  }

  step(key) {
    return STEP[this.unit][key === "thickness" ? "thickness" : "side"]
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
    this.numberTargets.forEach((input) => input.closest(".field").classList.toggle("bad", !(parseFloat(input.value) > 0)))

    const problem = this.problem()
    this.hintTarget.textContent = problem
    this.goTarget.disabled = Boolean(problem)
    if (!problem) this.draw()
    this.save()
  }

  pageSizes(unit) {
    const select = this.pageSizeTarget
    if (select.dataset.unit === unit) return
    const chosen = select.value
    select.replaceChildren(new Option("Fit the box", ""), ...this.settingsValue.pageSizes[unit].map(([name, width, height]) => new Option(`${name}  ${width} × ${height}`, name)))
    select.value = chosen
    select.dataset.unit = unit
  }

  draw() {
    const { viewBox, markup } = isoBox({
      width: this.number("width"), height: this.number("height"), depth: this.number("depth"), thickness: this.number("thickness"),
      notch: this.number("notch"), units: this.unit, lid: this.lidTarget.value, hot: this.hot
    })
    this.previewTarget.setAttribute("viewBox", viewBox)
    this.previewTarget.classList.toggle("hot-thickness", this.hot === "thickness")
    this.previewTarget.innerHTML = markup // numbers and fixed class names only, see iso_box.js
  }

  save() {
    try { localStorage.setItem(STORAGE_KEY, JSON.stringify(this.fields)) } catch (error) { /* storage is optional */ }
  }

  restore() {
    let saved = {}
    try { saved = JSON.parse(localStorage.getItem(STORAGE_KEY) || "{}") } catch (error) { return }
    const unit = saved.units === "mm" ? "mm" : "in"
    this.unitsTargets.forEach((radio) => { radio.checked = radio.value === unit })
    this.pageSizes(unit) // the saved page size needs its option to exist first
    for (const [key, value] of Object.entries(saved)) {
      const field = this.input(key)
      if (!field || key === "units") continue
      field.value = value
      // A lid this laser-cutter cannot draw yet falls back to the closed box.
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
      const { done, total } = JSON.parse(message.data)
      this.progress("Working out the tabs…", done, total)
    })
    this.source.addEventListener("drawn", (message) => {
      const { svg, filename } = JSON.parse(message.data)
      this.source.close()
      this.svg = svg
      this.filename = filename
      const still = window.matchMedia("(prefers-reduced-motion: reduce)").matches
      this.cancelTrace = trace(load(this.drawingTarget, svg), {
        duration: still ? 0 : TRACE_MS,
        onStep: (done, total) => this.progress("Cutting…", done, total),
        onDone: () => this.ready()
      })
    })
    this.source.addEventListener("failed", (message) => this.fail(JSON.parse(message.data).message))
    this.source.onerror = () => { if (!this.svg) this.fail("Lost the connection to makeabox. Check your network and generate again.") }
  }

  describe() {
    const unit = this.unit, sides = SIDES.map((key) => this.number(key)).join(" × ")
    const tab = this.number("notch") ? `${this.number("notch")} ${unit}` : `auto, about ${clean(3 * this.number("thickness"))} ${unit}`
    this.cutTitleTarget.textContent = `${sides} ${unit} box`
    this.cutMaterialTarget.textContent = `${this.number("thickness")} ${unit} material`
    const rows = [["Inside", `${sides} ${unit}`], ["Material", `${this.number("thickness")} ${unit}`], ["Tab width", tab],
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

  ready() {
    this.phaseTarget.textContent = "Ready"
    this.downloadTargets.forEach((button) => { button.disabled = false })
    this.downloadTargets[0].focus()
  }

  fail(message) {
    this.stop()
    this.cutTarget.classList.add("failed")
    this.phaseTarget.textContent = message
    this.countTarget.textContent = ""
    this.barTarget.style.width = "0"
  }

  stop() {
    this.source?.close()
    this.cancelTrace?.()
    this.source = this.cancelTrace = null
  }

  // The drawing is already in the browser, so the SVG is saved from memory.
  downloadSvg() {
    const link = document.createElement("a")
    link.href = URL.createObjectURL(new Blob([this.svg], { type: "image/svg+xml" }))
    link.download = this.filename
    link.click()
    setTimeout(() => URL.revokeObjectURL(link.href), 1000)
    this.finish("svg")
  }

  // The PDF is drawn again on the server from the same settings.
  downloadPdf() {
    window.location.assign(`${this.downloadUrlValue}.pdf?${this.query}`)
    this.finish("pdf")
  }

  finish(format) {
    window.gtag?.("event", "download", { event_category: "box", event_label: format })
    this.cutTarget.close()
  }
}
