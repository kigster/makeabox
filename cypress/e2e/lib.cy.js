// The pure modules behind the preview and the trace, tested without a page.
import { tabCount, isoBox } from "../../app/javascript/lib/iso_box"
import { chain } from "../../app/javascript/lib/laser_trace"

describe("tabCount", () => {
  it("is odd and at least three, counted the way laser-cutter counts", () => {
    expect(tabCount(5, 0.735)).to.eq(9)
    expect(tabCount(3, 0.735)).to.eq(7)
    expect(tabCount(1, 5)).to.eq(3)
    expect(tabCount(4, 1)).to.eq(5) // an exact fit still gets one more, then is made odd
    for (let length = 1; length < 40; length += 0.7) expect(tabCount(length, 0.6) % 2).to.eq(1)
  })
})

describe("isoBox", () => {
  const box = { width: 5, height: 3, depth: 4, thickness: 0.245, notch: 0, units: "in", hot: null }
  const count = (markup, cls) => markup.split(`class="${cls}"`).length - 1

  it("draws three faces, their fingers and three dimensions for a closed box", () => {
    const { viewBox, markup } = isoBox({ ...box, lid: "full" })
    expect(count(markup, "face top") + count(markup, "face left") + count(markup, "face right")).to.eq(3)
    expect(count(markup, "finger")).to.be.greaterThan(20)
    expect(markup).to.contain(">5 in<").and.contain(">3 in<").and.contain(">4 in<")
    expect(viewBox.split(" ").map(Number).every(Number.isFinite)).to.eq(true)
  })

  it("opens the box and floats the lid for a lid that lifts off", () => {
    const closed = isoBox({ ...box, lid: "full" }).markup
    const plain = isoBox({ ...box, lid: "plain" }).markup
    const back = isoBox({ ...box, lid: "back" }).markup
    expect(plain).to.contain('class="inside floor"')
    expect(closed).not.to.contain('class="inside floor"')
    expect(count(back, "finger")).to.be.greaterThan(count(plain, "finger"))
    expect(count(closed, "finger")).to.be.greaterThan(count(back, "finger"))
  })

  it("raises tabs on the back wall where a back lid has its slots", () => {
    const slots = (tabCount(5, 3 * 0.245) - 1) / 2 // every other notch along the far edge of the lid
    expect(count(isoBox({ ...box, lid: "back" }).markup, "tab")).to.eq(slots)
    expect(count(isoBox({ ...box, lid: "plain" }).markup, "tab")).to.eq(0)
    expect(count(isoBox({ ...box, lid: "full" }).markup, "tab")).to.eq(0)
  })

  it("draws a box in millimetres at the same size as in inches, so its lines keep their width", () => {
    const inches = isoBox({ ...box, lid: "full" })
    const mm = isoBox({ ...box, width: 127, height: 76.2, depth: 101.6, thickness: 6.223, units: "mm", lid: "full" })
    expect(mm.viewBox).to.eq(inches.viewBox)
    expect(mm.markup).to.contain(">127 mm<").and.contain(">76.2 mm<").and.contain(">101.6 mm<")
  })

  it("marks the dimension being edited and labels millimetres", () => {
    const { markup } = isoBox({ ...box, lid: "full", units: "mm", hot: "depth" })
    expect(count(markup, "dim hot")).to.eq(1)
    expect(markup).to.contain(">4 mm<")
  })
})

describe("chain", () => {
  it("orders lines end to start and flips the ones that point the wrong way", () => {
    const lines = [[0, 0, 1, 0], [5, 5, 6, 5], [2, 0, 1, 0]]
    expect(chain(lines)).to.deep.eq([[0, 0, 1, 0], [1, 0, 2, 0], [5, 5, 6, 5]])
  })

  it("leaves very large drawings in the order they came", () => {
    const lines = [[9, 9, 8, 8], [0, 0, 1, 1], [7, 7, 6, 6]]
    expect(chain(lines, 2)).to.eq(lines)
  })
})
