// The side view of a box whose front slopes back, the same numbers
// laser-cutter's Sloped::Profile computes. Pure geometry, no state.
//
// Seen from the left, front to the left: a front strip Hf high, a tilted
// panel rising at the slope, a top strip Dt deep, the back H high, and the
// bottom D deep. Every length is of the inside outline.
//
// Where the tilted panel meets a strip the corner is obtuse: the strip runs
// past the corner over the end of the tilted panel, which stops short, so the
// outside faces meet. A strip of zero size is dropped.

const PRECISION = 1e-6

// { depth, height, frontHeight, slope (degrees), thickness }
// Returns null when the numbers do not make this shape, otherwise
// { angle, topDepth, slopeLength, outline, span, lengths }.
export function slopedProfile({ depth: D, height: H, frontHeight: Hf, slope, thickness: t }) {
  if (!(D > 0 && H > 0 && t > 0 && slope > 0 && slope < 90 && Hf >= 0 && Hf < H)) return null
  const angle = (slope * Math.PI) / 180
  const run = (H - Hf) / Math.tan(angle)
  if (run > D + PRECISION) return null

  const topDepth = D - run < PRECISION ? 0 : D - run
  const top = topDepth > 0, front = Hf > 0
  const topCut = top ? t / Math.tan(angle) : 0
  const frontCut = front ? t * Math.tan(angle) : 0
  const slopeLength = Math.hypot(run, H - Hf)
  const [cos, sin] = [Math.cos(angle), Math.sin(angle)]

  // [depth from the front, height], counter-clockwise from the front of the bottom.
  const outline = [[0, 0], [D, 0], [D, H]]
  if (top) outline.push([D - topDepth, H])
  if (front) outline.push([0, Hf])

  return {
    angle,
    topDepth,
    slopeLength,
    outline,
    // The stretch of the slope the tilted panel covers, low end first.
    span: [[frontCut * cos, Hf + frontCut * sin], [run - topCut * cos, H - topCut * sin]],
    lengths: {
      tilted: slopeLength - frontCut - topCut,
      top: top ? topDepth + t / sin : 0,
      front: front ? Hf + t / cos : 0
    }
  }
}
