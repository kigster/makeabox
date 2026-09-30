import { Controller } from "@hotwired/stimulus"

const COLORS = ["255, 138, 61", "135, 206, 250"] // orange and light sky blue, as "r, g, b"
const LINK = 140       // px within which two particles are joined by a line
const DENSITY = 15000  // px² of window per particle
const MOST = 120
const SPEED = 0.35     // px per frame along each axis, at most

// Slow particles drifting over the bed, joined when they come close. Drawn on
// a fixed canvas behind the page. Stands still for anyone who asked for less
// motion, and stops while the tab is hidden.
export default class extends Controller {
  connect() {
    this.pen = this.element.getContext("2d")
    if (!this.pen) return // no canvas, no particles; the page is fine without them
    this.still = window.matchMedia("(prefers-reduced-motion: reduce)").matches
    this.resize = this.resize.bind(this)
    this.tick = this.tick.bind(this)
    this.visibility = () => (document.hidden ? this.stop() : this.start())
    window.addEventListener("resize", this.resize)
    document.addEventListener("visibilitychange", this.visibility)
    this.resize()
    this.start()
  }

  disconnect() {
    if (!this.pen) return
    this.stop()
    window.removeEventListener("resize", this.resize)
    document.removeEventListener("visibilitychange", this.visibility)
  }

  resize() {
    const ratio = Math.min(window.devicePixelRatio || 1, 2)
    this.width = window.innerWidth
    this.height = window.innerHeight
    this.element.width = this.width * ratio
    this.element.height = this.height * ratio
    this.pen.setTransform(ratio, 0, 0, ratio, 0, 0)
    const count = Math.min(MOST, Math.round((this.width * this.height) / DENSITY))
    this.particles = Array.from({ length: count }, () => ({
      x: Math.random() * this.width,
      y: Math.random() * this.height,
      dx: (Math.random() - 0.5) * 2 * SPEED,
      dy: (Math.random() - 0.5) * 2 * SPEED,
      radius: 1 + Math.random() * 1.6,
      color: COLORS[Math.random() < 0.5 ? 0 : 1]
    }))
    this.paint()
  }

  start() {
    if (this.still || this.frame) return
    this.frame = requestAnimationFrame(this.tick)
  }

  stop() {
    cancelAnimationFrame(this.frame)
    this.frame = null
  }

  tick() {
    for (const particle of this.particles) {
      particle.x = (particle.x + particle.dx + this.width) % this.width
      particle.y = (particle.y + particle.dy + this.height) % this.height
    }
    this.paint()
    this.frame = requestAnimationFrame(this.tick)
  }

  paint() {
    const pen = this.pen, particles = this.particles
    pen.clearRect(0, 0, this.width, this.height)
    pen.lineWidth = 1
    for (let i = 0; i < particles.length; i++) {
      const a = particles[i]
      for (let j = i + 1; j < particles.length; j++) {
        const b = particles[j], distance = Math.hypot(a.x - b.x, a.y - b.y)
        if (distance > LINK) continue
        pen.strokeStyle = `rgba(${a.color}, ${((1 - distance / LINK) * 0.22).toFixed(3)})`
        pen.beginPath()
        pen.moveTo(a.x, a.y)
        pen.lineTo(b.x, b.y)
        pen.stroke()
      }
      pen.fillStyle = `rgba(${a.color}, 0.7)`
      pen.beginPath()
      pen.arc(a.x, a.y, a.radius, 0, Math.PI * 2)
      pen.fill()
    }
  }
}
