// Shows the drawing laser-cutter made and traces it the way a laser would:
// one line after another, following a path rather than jumping around.

const SVG_NS = "http://www.w3.org/2000/svg"
const FRESH = 14   // lines behind the beam that still glow
const COOLING = 40 // how far back the glow is cleared each frame

// Chains lines end to start, nearest first, so neighbours are drawn in a row.
// Quadratic, so very large drawings keep the order laser-cutter gave them.
export function chain(lines, limit = 4000) {
  if (lines.length > limit || lines.length < 2) return lines
  const left = new Set(lines)
  let current = lines[0]
  left.delete(current)
  const ordered = [current]
  while (left.size) {
    let best = null, distance = Infinity, flip = false
    for (const line of left) {
      const head = Math.hypot(line[0] - current[2], line[1] - current[3])
      const tail = Math.hypot(line[2] - current[2], line[3] - current[3])
      if (head < distance) { distance = head; best = line; flip = false }
      if (tail < distance) { distance = tail; best = line; flip = true }
    }
    left.delete(best)
    current = flip ? [best[2], best[3], best[0], best[1]] : best
    ordered.push(current)
  }
  return ordered
}

// Reads the <line> elements out of laser-cutter's SVG and rebuilds them inside
// `target`, hidden. Only numbers and the viewBox are copied across, never markup.
export function load(target, source) {
  const parsed = new DOMParser().parseFromString(source, "image/svg+xml").documentElement
  const lines = chain([...parsed.querySelectorAll("line")].map((line) => ["x1", "y1", "x2", "y2"].map((name) => Number(line.getAttribute(name)))))
  target.setAttribute("viewBox", parsed.getAttribute("viewBox") || "0 0 1 1")
  const elements = lines.map((line) => {
    const element = document.createElementNS(SVG_NS, "line")
    ;["x1", "y1", "x2", "y2"].forEach((name, index) => element.setAttribute(name, line[index]))
    return element
  })
  const dot = document.createElementNS(SVG_NS, "circle")
  dot.setAttribute("class", "dot")
  dot.setAttribute("r", (parsed.viewBox.baseVal.width || 1) * 0.008)
  target.replaceChildren(...elements, dot)
  return { lines, elements, dot }
}

const ease = (p) => (p < 0.5 ? 2 * p * p : 1 - Math.pow(-2 * p + 2, 2) / 2)

// Reveals the lines over `duration` ms. Calls onStep(done, total) each frame and
// onDone() at the end. Returns a function that cancels the animation.
export function trace({ lines, elements, dot }, { duration, onStep, onDone }) {
  const total = elements.length, start = performance.now()
  let shown = 0, frame = 0
  const finish = () => {
    elements.forEach((element) => element.setAttribute("class", "cut"))
    dot.style.display = "none"
    onStep(total, total)
    onDone()
  }
  if (duration <= 0 || total === 0) { finish(); return () => {} }

  dot.style.display = ""
  const tick = (now) => {
    const progress = Math.min(1, (now - start) / duration)
    const upTo = Math.round(total * ease(progress))
    for (; shown < upTo; shown++) elements[shown].setAttribute("class", "cut fresh")
    for (let i = Math.max(0, upTo - COOLING); i < upTo - FRESH; i++) elements[i].setAttribute("class", "cut")
    if (upTo) { dot.setAttribute("cx", lines[upTo - 1][2]); dot.setAttribute("cy", lines[upTo - 1][3]) }
    onStep(upTo, total)
    if (progress < 1) frame = requestAnimationFrame(tick)
    else finish()
  }
  frame = requestAnimationFrame(tick)
  return () => cancelAnimationFrame(frame)
}
