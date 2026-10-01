import { Controller } from "@hotwired/stimulus"

const POLL_MS = 15000
const DIGITS = 8 // matches CounterHelper::COUNTER_DIGITS

// The download counter in the header. It asks for the total every few
// seconds while the page is visible, and at once when this page downloads
// a box (the "makeabox:downloaded" event from the generator).
export default class extends Controller {
  static targets = ["digits"]
  static values = { url: String, total: Number }

  connect() {
    this.refresh = this.refresh.bind(this)
    this.wake = () => { if (!document.hidden) this.refresh() }
    this.timer = setInterval(() => { if (!document.hidden) this.refresh() }, POLL_MS)
    window.addEventListener("makeabox:downloaded", this.refresh)
    document.addEventListener("visibilitychange", this.wake)
  }

  disconnect() {
    clearInterval(this.timer)
    window.removeEventListener("makeabox:downloaded", this.refresh)
    document.removeEventListener("visibilitychange", this.wake)
  }

  async refresh() {
    try {
      const response = await fetch(this.urlValue, { headers: { Accept: "application/json" } })
      if (!response.ok) return
      const { total } = await response.json()
      if (Number.isInteger(total) && total !== this.totalValue) this.totalValue = total
    } catch {
      // Offline for a moment: keep showing the last count.
    }
  }

  totalValueChanged(total, previous) {
    if (previous === undefined) return // drawn by the server already
    this.digitsTarget.replaceChildren(...groups(total))
    const label = `${total.toLocaleString("en-US")} boxes downloaded since 2015`
    this.element.setAttribute("aria-label", label)
    this.element.title = label
    this.element.classList.remove("tick")
    void this.element.offsetWidth // restarts the flash
    this.element.classList.add("tick")
  }
}

// The same digits CounterHelper#counter_digits draws: groups of three, each
// lit over a faint row of eights, blank digits as "!".
function groups(total) {
  const shown = String(total).padStart(DIGITS, "!")
  const parts = []
  for (let end = shown.length; end > 0; end -= 3) parts.unshift(shown.slice(Math.max(0, end - 3), end))
  return parts.map((part) => {
    const group = document.createElement("span")
    group.className = "group"
    const off = document.createElement("span")
    off.className = "off"
    off.textContent = "8".repeat(part.length)
    const on = document.createElement("span")
    on.className = "on"
    on.textContent = part
    group.append(off, on)
    return group
  })
}
