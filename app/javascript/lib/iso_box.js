// Draws the isometric preview of the box: three visible faces with finger
// joints, the dimensions, and for a lid that lifts off, the open box with the
// lid floating above it. Pure geometry, no state.

const COS30 = Math.cos(Math.PI / 6)
const SCALE = 100

const project = (x, y, z) => [(x - y) * COS30 * SCALE, ((x + y) * 0.5 - z) * SCALE]
const pair = (point) => point.map((n) => n.toFixed(1)).join(",")

// How many notches laser-cutter cuts along an edge: the notch length is a
// guide, rounded so that the count is odd and at least three. The gem measures
// the inside of the edge and allows for kerf, so its count can differ by two.
export function tabCount(length, notch) {
  const count = Math.ceil(Number((length / notch).toFixed(6))) + 1
  return Math.max(3, Math.floor(count / 2) * 2 + 1)
}

// box: { width, height, depth, thickness, notch, units, lid, hot }
// Returns { viewBox, markup } for an <svg>. Every interpolated value is a number
// or one of a fixed set of words, so the markup is safe to assign as innerHTML.
export function isoBox(box) {
  const { width: W, height: H, depth: D, thickness: t } = box
  const notch = box.notch || 3 * t
  const open = box.lid === "back" || box.lid === "plain"
  const unit = Math.max(W, H, D)
  const lift = open ? Math.max(0.35 * H, 0.18 * unit) : 0
  const points = []
  let markup = ""

  const face = (o, u, a, v, b) => ({ o, u, a, v, b })
  const faces = {
    top: face([0, 0, H + lift], [1, 0, 0], W, [0, 1, 0], D),
    left: face([0, D, 0], [1, 0, 0], W, [0, 0, 1], H),
    right: face([W, 0, 0], [0, 1, 0], D, [0, 0, 1], H)
  }
  const at = (f, p, q) => {
    const point = project(f.o[0] + f.u[0] * p + f.v[0] * q, f.o[1] + f.u[1] * p + f.v[1] * q, f.o[2] + f.u[2] * p + f.v[2] * q)
    points.push(point)
    return point
  }
  const quad = (f, p0, q0, p1, q1) => [at(f, p0, q0), at(f, p1, q0), at(f, p1, q1), at(f, p0, q1)].map(pair).join(" ")
  const polygon = (cls, f, ...rect) => { markup += `<polygon class="${cls}" points="${quad(f, ...rect)}"/>` }

  // A finger is the end grain of the neighbouring panel showing through an edge.
  const fingers = (f, edge, phase) => {
    const length = edge[0] === "u" ? f.a : f.b
    const count = tabCount(length, notch)
    for (let i = phase; i < count; i += 2) {
      const a = (i * length) / count, b = ((i + 1) * length) / count
      const rect = { u0: [a, 0, b, t], u1: [a, f.b - t, b, f.b], v0: [0, a, t, b], v1: [f.a - t, a, f.a, b] }[edge]
      polygon("finger", f, ...rect)
    }
  }

  const shadow = [project(-0.04 * unit, D, 0), project(W, D + 0.1 * unit, 0), project(W + 0.22 * unit, D * 0.4, 0), project(W + 0.16 * unit, -0.1 * unit, 0)]
  markup += `<polygon class="shadow" points="${shadow.map(pair).join(" ")}"/>`

  if (open) {
    // Looking into the open box: the rim, then the floor and far walls seen through the opening.
    const rim = face([0, 0, H], [1, 0, 0], W, [0, 1, 0], D)
    polygon("face top", rim, 0, 0, W, D)
    polygon("inside floor", face([0, 0, t], [1, 0, 0], W, [0, 1, 0], D), t, t, W - t, D - t)
    markup += `<clipPath id="opening"><polygon points="${quad(rim, t, t, W - t, D - t)}"/></clipPath><g clip-path="url(#opening)">`
    polygon("inside far", face([t, 0, 0], [0, 1, 0], D, [0, 0, 1], H), t, t, D - t, H)
    polygon("inside back", face([0, t, 0], [1, 0, 0], W, [0, 0, 1], H), t, t, W - t, H)
    markup += "</g>"
  }

  polygon("face left", faces.left, 0, 0, W, H)
  polygon("face right", faces.right, 0, 0, D, H)
  fingers(faces.left, "v1", 0); fingers(faces.right, "v1", 1)
  for (const [f, edge] of [[faces.left, "v0"], [faces.left, "u0"], [faces.right, "v0"], [faces.right, "u0"]]) fingers(f, edge, 1)

  if (open) {
    // The lid floats above the box, a slab one thickness deep.
    polygon("face left", face([0, D, H + lift - t], [1, 0, 0], W, [0, 0, 1], t), 0, 0, W, t)
    polygon("face right", face([W, 0, H + lift - t], [0, 1, 0], D, [0, 0, 1], t), 0, 0, D, t)
  }
  polygon("face top", faces.top, 0, 0, W, D)
  if (!open) {
    fingers(faces.top, "u1", 0); fingers(faces.left, "u1", 1)
    fingers(faces.top, "v1", 0); fingers(faces.right, "u1", 1)
    fingers(faces.top, "u0", 1); fingers(faces.top, "v0", 1)
  } else if (box.lid === "back") {
    fingers(faces.top, "u0", 1) // the far edge, where the lid meets the back wall
  }

  const offset = 0.1 * unit, size = unit * SCALE * 0.052
  const dimension = (key, a, b, away, value) => {
    const a1 = project(a[0] + away[0] * offset, a[1] + away[1] * offset, a[2])
    const b1 = project(b[0] + away[0] * offset, b[1] + away[1] * offset, b[2])
    const mid = [(a1[0] + b1[0]) / 2, (a1[1] + b1[1]) / 2]
    points.push(a1, b1, [mid[0] - size * 2.4, mid[1] - size], [mid[0] + size * 2.4, mid[1] + size])
    markup += `<g class="dim${box.hot === key ? " hot" : ""}"><line x1="${a1[0].toFixed(1)}" y1="${a1[1].toFixed(1)}" x2="${b1[0].toFixed(1)}" y2="${b1[1].toFixed(1)}"/>` +
      `<text x="${mid[0].toFixed(1)}" y="${mid[1].toFixed(1)}" font-size="${size.toFixed(1)}">${Number(value)} ${box.units === "mm" ? "mm" : "in"}</text></g>`
  }
  dimension("width", [0, D, 0], [W, D, 0], [0, 1.6], W)
  dimension("depth", [W, 0, 0], [W, D, 0], [1.6, 0], D)
  dimension("height", [0, D, 0], [0, D, H], [-1.2, 0], H)

  const xs = points.map((p) => p[0]), ys = points.map((p) => p[1]), pad = unit * 6
  const x0 = Math.min(...xs) - pad, y0 = Math.min(...ys) - pad
  const viewBox = [x0, y0, Math.max(...xs) + pad - x0, Math.max(...ys) + pad - y0].map((n) => n.toFixed(1)).join(" ")
  return { viewBox, markup }
}
