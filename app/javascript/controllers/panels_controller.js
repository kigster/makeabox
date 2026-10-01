import { Controller } from "@hotwired/stimulus"

const SLIDE_MS = 450 // matches the transition in sections.css

// The sections below the first screen live in <dialog> panels that slide up
// over the controls. A link with data-panels-name-param opens one; Escape or
// the close button slides it back down. The panels are not modal, so the
// header stays usable and one panel can be swapped for another. The URL hash
// follows along, so #how still opens the right panel.
export default class extends Controller {
  static targets = ["panel"]

  connect() {
    this.follow = this.follow.bind(this)
    this.escape = (event) => { if (event.key === "Escape") this.panelTargets.filter((dialog) => dialog.open).forEach((dialog) => this.hide(dialog)) }
    window.addEventListener("hashchange", this.follow)
    window.addEventListener("keydown", this.escape)
    this.follow()
  }

  disconnect() {
    window.removeEventListener("hashchange", this.follow)
    window.removeEventListener("keydown", this.escape)
  }

  // The hash is the source of truth on arrival and when the back button moves it.
  follow() {
    const name = location.hash.slice(1)
    if (this.panelTargets.some((dialog) => dialog.id === name)) this.open({ params: { name } })
    else this.panelTargets.filter((dialog) => dialog.open).forEach((dialog) => this.hide(dialog, false))
  }

  open(event) {
    const panel = this.panelTargets.find((dialog) => dialog.id === event.params.name)
    if (!panel) return
    event.preventDefault?.()
    this.panelTargets.filter((dialog) => dialog !== panel && dialog.open).forEach((dialog) => this.hide(dialog, false))
    if (!panel.open) panel.show()
    requestAnimationFrame(() => panel.classList.add("up"))
    panel.focus()
    history.replaceState(null, "", `#${panel.id}`)
  }

  close(event) {
    this.hide(event.target.closest("dialog"))
  }

  hide(panel, clearHash = true) {
    panel.classList.remove("up")
    setTimeout(() => panel.open && panel.close(), SLIDE_MS)
    if (clearHash) history.replaceState(null, "", location.pathname)
  }
}
