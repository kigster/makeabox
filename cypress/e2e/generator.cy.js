const field = (name) => cy.get(`[name="box[${name}]"]`)

describe("making a box", () => {
  beforeEach(() => {
    cy.clearLocalStorage()
    cy.visit("/")
  })

  it("draws the preview and keeps it in step with the form", () => {
    cy.get(".stage svg polygon.face").should("have.length", 3)
    cy.get(".stage svg .dim text").first().should("have.text", "5 in")

    field("width").clear().type("8")
    cy.get(".stage svg .dim text").first().should("have.text", "8 in")
    cy.screenshot("home", { capture: "viewport" })
  })

  it("converts every number when the units change", () => {
    cy.contains(".seg span", "mm").click()
    field("width").should("have.value", "127")
    field("thickness").should("have.value", "6.22")
    cy.get(".num span").first().should("have.text", "mm")
    cy.get(".chips button").first().should("have.text", "3 mm")
  })

  it("sets the thickness from a stock size", () => {
    cy.contains(".chips button", "1/8″").click()
    field("thickness").should("have.value", "0.125")
    cy.contains(".chips button", "1/8″").should("have.attr", "aria-pressed", "true")
  })

  it("explains what is wrong and refuses to generate", () => {
    field("thickness").clear().type("9")
    cy.get(".hint").should("contain", "Thickness has to be smaller")
    cy.get(".go").should("be.disabled")

    field("height").clear()
    cy.get(".hint").should("contain", "Height needs a number above zero")
  })

  it("remembers the settings in this browser", () => {
    field("depth").clear().type("7.5")
    cy.contains(".seg span", "mm").click()
    cy.reload()
    field("depth").should("have.value", "190.5")
    cy.get('[name="box[units]"][value="mm"]').should("be.checked")

    cy.contains("button", "Tabs, kerf, page").click()
    cy.contains("button", "Reset everything to defaults").click()
    field("depth").should("have.value", "4")
    cy.get('[name="box[units]"][value="in"]').should("be.checked")
  })

  it("offers the optional settings with the gem's defaults as placeholders", () => {
    cy.contains("button", "Tabs, kerf, page").click()
    field("kerf").should("have.attr", "placeholder", "0.0024")
    field("page_size").find("option").should("have.length.greaterThan", 10)
    cy.screenshot("settings", { capture: "viewport" })
    cy.contains("button", "Done").click()
    cy.get("dialog.sheet").first().should("not.have.attr", "open")
  })

  it("generates the drawing, traces it, and offers both files", () => {
    cy.get(".go").click()
    cy.get("dialog.cut").should("have.attr", "open")
    cy.get("dialog.cut h2").should("have.text", "5 × 3 × 4 in box")
    cy.contains("dialog.cut .progress", "Ready", { timeout: 10000 })
    cy.get("dialog.cut .progress").should("contain", "376 of 376 lines")
    cy.get(".cut-bed svg line.cut").should("have.length", 376)
    cy.contains("button", "Download SVG").should("be.enabled")
    cy.contains("button", "Download PDF").should("be.enabled")
    cy.screenshot("generated", { capture: "viewport" })

    cy.contains("button", "Download SVG").click()
    cy.get("dialog.cut").should("not.have.attr", "open")
    cy.readFile("tmp/cypress/downloads/makeabox-5x3x4in-0.245t.svg").should("contain", "<svg")
  })

  it("serves the PDF for the same settings", () => {
    cy.request("/box/download.pdf?box[width]=5&box[height]=3&box[depth]=4&box[thickness]=0.245&box[units]=in").then((response) => {
      expect(response.status).to.eq(200)
      expect(response.headers["content-type"]).to.eq("application/pdf")
      expect(response.headers["content-disposition"]).to.contain("makeabox-5x3x4in-0.245t.pdf")
      expect(response.body.slice(0, 5)).to.eq("%PDF-")
    })
  })

  it("stacks the form on a phone", () => {
    cy.viewport(390, 844)
    cy.get(".go").should("be.visible")
    cy.screenshot("phone", { capture: "viewport" })
  })
})
