import { Controller } from "@hotwired/stimulus"

// On a phone the nav folds into a drop-down behind a hamburger button. It
// closes when a link is chosen, on Escape, and on a tap anywhere else.
export default class extends Controller {
  static targets = ["button"]

  connect() {
    this.dismiss = (event) => {
      if (event.type === "keydown" ? event.key === "Escape" : !this.element.contains(event.target)) this.close()
    }
    document.addEventListener("click", this.dismiss)
    document.addEventListener("keydown", this.dismiss)
  }

  disconnect() {
    document.removeEventListener("click", this.dismiss)
    document.removeEventListener("keydown", this.dismiss)
  }

  toggle() {
    this.set(this.buttonTarget.getAttribute("aria-expanded") !== "true")
  }

  close() {
    this.set(false)
  }

  set(open) {
    this.buttonTarget.setAttribute("aria-expanded", String(open))
    this.element.classList.toggle("open", open)
  }
}
