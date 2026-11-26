// Draws the isometric preview of a box whose front slopes back: the right
// side wall, the front strip, the tilted panel and the top strip, with finger
// joints and the dimensions. For a lid that lifts off, the tilted panel floats
// up off the box. Pure geometry, no state.
//
// Library modules here import nothing (importmap pins them by bare name, which
// the test bundler cannot resolve), so the caller passes in the profile from
// slopedProfile() and tabCount from iso_box.js. The projection matches
// iso_box.js, so both boxes draw at the same scale.

const COS30 = Math.cos(Math.PI / 6)
const SCALE = 100

const project = (x, y, z) => [(x - y) * COS30 * SCALE, ((x + y) * 0.5 - z) * SCALE]
const pair = (point) => point.map((n) => n.toFixed(1)).join(",")

// box: { width, height, depth, frontHeight, slope, thickness, notch, units, lid, hot }
// profile: slopedProfile() of the same box, in the same units
// Returns { viewBox, markup } for an <svg>. Every interpolated value is a number
// or one of a fixed set of words, so the markup is safe to assign as innerHTML.
export function isoSlopedBox(box, profile, tabCount) {
  // Drawn in inches whatever the units, as iso_box.js does.
  const inch = box.units === "mm" ? 25.4 : 1
  const [W, H, D, Hf, t] = [box.width, box.height, box.depth, box.frontHeight, box.thickness].map((value) => value / inch)
  const notch = (box.notch || 3 * box.thickness) / inch
  const [Dt, S] = [profile.topDepth / inch, profile.slopeLength / inch]
  const tilted = profile.lengths.tilted / inch
  const start = Math.hypot(...profile.span[0].map((c, i) => c - [0, box.frontHeight][i])) / inch // where the tilted panel begins on the slope
  const [cos, sin] = [Math.cos(profile.angle), Math.sin(profile.angle)]
  const open = box.lid === "plain"
  const unit = Math.max(W, H, D)
  const points = []
  let markup = ""

  // A face maps its own (p, q) onto the box: o + u·p + v·q.
  const face = (o, u, v) => ({ o, u, v })
  const at = (f, p, q) => {
    const point = project(...[0, 1, 2].map((i) => f.o[i] + f.u[i] * p + f.v[i] * q))
    points.push(point)
    return point
  }
  const shape = (cls, f, corners) => { markup += `<polygon class="${cls}" points="${corners.map(([p, q]) => pair(at(f, p, q))).join(" ")}"/>` }
  const rect = (cls, f, a, b) => shape(cls, f, [[0, 0], [a, 0], [a, b], [0, b]])

  // A finger is the end grain of the neighbouring panel showing through an
  // edge: every other notch along it, one thickness deep.
  const fingers = (f, from, dir, inward, length, phase) => {
    if (length <= 0) return
    const count = tabCount(length, notch)
    const point = (s, d) => [from[0] + dir[0] * s + inward[0] * d, from[1] + dir[1] * s + inward[1] * d]
    for (let i = phase; i < count; i += 2) {
      const a = (i * length) / count, b = ((i + 1) * length) / count
      shape("finger", f, [point(a, 0), point(b, 0), point(b, t), point(a, t)])
    }
  }

  // Seen from the right, the side's own p runs from the front to the back.
  const side = face([W, D, 0], [0, -1, 0], [0, 0, 1])
  const front = face([0, D, 0], [1, 0, 0], [0, 0, 1])
  const slope = face([0, D, Hf], [1, 0, 0], [0, -cos, sin])
  const top = face([0, Dt, H], [1, 0, 0], [0, -1, 0])
  const outline = profile.outline.map(([p, q]) => [p / inch, q / inch])

  const shadow = [project(-0.04 * unit, D, 0), project(W, D + 0.1 * unit, 0), project(W + 0.22 * unit, D * 0.4, 0), project(W + 0.16 * unit, -0.1 * unit, 0)]
  markup += `<polygon class="shadow" points="${shadow.map(pair).join(" ")}"/>`

  shape("face right", side, outline)
  fingers(side, [0, 0], [1, 0], [0, 1], D, 1)
  fingers(side, [D, 0], [0, 1], [-1, 0], H, 1)
  fingers(side, [0, 0], [0, 1], [1, 0], Hf, 1)
  fingers(side, [D - Dt, H], [1, 0], [0, -1], Dt, 1)

  if (Hf > 0) {
    rect("face left", front, W, Hf)
    fingers(front, [0, 0], [1, 0], [0, 1], W, 1)
    fingers(front, [W, 0], [0, 1], [-1, 0], Hf, 0)
  }
  if (Dt > 0) {
    rect("face top", top, W, Dt)
    fingers(top, [0, Dt], [1, 0], [0, -1], W, 0)
    fingers(top, [W, 0], [0, 1], [-1, 0], Dt, 0)
  }

  if (open) {
    // The opening the tilted panel leaves, then the panel, lifted along its
    // own normal, a slab one thickness deep.
    shape("inside floor", slope, [[0, 0], [W, 0], [W, S], [0, S]])
    const lift = Math.max(0.35 * H, 0.18 * unit)
    const up = [0, sin * lift, cos * lift]
    const lifted = face(slope.o.map((c, i) => c + up[i]), slope.u, slope.v)
    const edge = lifted.o.map((c, i) => c + slope.v[i] * start) // the low edge of the lifted panel
    rect("face left", face(edge, [1, 0, 0], [0, -sin, -cos]), W, t)
    shape("face tilted", lifted, [[0, start], [W, start], [W, start + tilted], [0, start + tilted]])
    fingers(lifted, [W, start], [0, 1], [-1, 0], tilted, 0)
  } else {
    rect("face tilted", slope, W, S)
    fingers(slope, [W, start], [0, 1], [-1, 0], tilted, 0)
    // The side's sloped edge, under the tilted panel's fingers.
    const [low] = profile.span
    fingers(side, [low[0] / inch, low[1] / inch], [cos, sin], [sin, -cos], tilted, 1)
  }

  const offset = 0.1 * unit, size = unit * SCALE * 0.052
  const label = (key, at, text) => {
    points.push([at[0] - size * 2.4, at[1] - size], [at[0] + size * 2.4, at[1] + size])
    markup += `<g class="dim${box.hot === key ? " hot" : ""}"><text x="${at[0].toFixed(1)}" y="${at[1].toFixed(1)}" font-size="${size.toFixed(1)}">${text}</text></g>`
  }
  const dimension = (key, a, b, away, value) => {
    const a1 = project(a[0] + away[0] * offset, a[1] + away[1] * offset, a[2])
    const b1 = project(b[0] + away[0] * offset, b[1] + away[1] * offset, b[2])
    points.push(a1, b1)
    markup += `<g class="dim${box.hot === key ? " hot" : ""}"><line x1="${a1[0].toFixed(1)}" y1="${a1[1].toFixed(1)}" x2="${b1[0].toFixed(1)}" y2="${b1[1].toFixed(1)}"/></g>`
    label(key, [(a1[0] + b1[0]) / 2, (a1[1] + b1[1]) / 2], `${Number(value)} ${box.units === "mm" ? "mm" : "in"}`)
  }
  dimension("width", [0, D, 0], [W, D, 0], [0, 1.6], box.width)
  dimension("depth", [W, 0, 0], [W, D, 0], [1.6, 0], box.depth)
  dimension("height", [W, 0, 0], [W, 0, H], [1.6, -1.2], box.height)
  if (Hf > 0) dimension("frontHeight", [0, D, 0], [0, D, Hf], [-1.2, 0], box.frontHeight)
  label("slope", project(W + offset, D - (S / 2) * cos, Hf + (S / 2) * sin + offset), `${Number(Number(box.slope).toFixed(1))}°`)

  const xs = points.map((p) => p[0]), ys = points.map((p) => p[1]), pad = unit * 6
  const x0 = Math.min(...xs) - pad, y0 = Math.min(...ys) - pad
  const viewBox = [x0, y0, Math.max(...xs) + pad - x0, Math.max(...ys) + pad - y0].map((n) => n.toFixed(1)).join(" ")
  return { viewBox, markup }
}
