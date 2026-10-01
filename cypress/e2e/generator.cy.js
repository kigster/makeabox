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
    cy.scrollTo("top")
    cy.screenshot("home", { capture: "viewport" })
  })

  it("animates the background and the heading", () => {
    const snapshot = ($canvas) => $canvas[0].toDataURL()
    cy.get("canvas.sparks").should(($canvas) => {
      const pixels = $canvas[0].getContext("2d").getImageData(0, 0, $canvas[0].width, $canvas[0].height).data
      expect(pixels.some((value) => value > 0)).to.eq(true)
    }).then(($canvas) => {
      const before = snapshot($canvas)
      // The particles move, so a later frame is a different picture.
      cy.get("canvas.sparks").should(($later) => expect(snapshot($later)).not.to.eq(before))
    })
    cy.get(".hero h1").should("have.css", "animation-name", "drift")
  })

  it("slides the sections up over the controls, and back down", () => {
    cy.contains("nav a", "How the tabs work").click()
    cy.get("dialog#how").should("have.attr", "open")
    cy.get("dialog#how").should("have.class", "up")
    cy.get("dialog#how h2").should("have.text", "How the tabs work")
    cy.location("hash").should("eq", "#how")
    cy.get(".go").should("exist") // the controls stay where they are, underneath

    cy.contains("nav a", "Discussion").click()
    cy.get("dialog#discussion").should("have.attr", "open")
    cy.get("dialog#how").should("not.have.attr", "open")

    cy.get("dialog#discussion .x").click()
    cy.get("dialog#discussion").should("not.have.attr", "open")
    cy.location("hash").should("eq", "")
  })

  it("opens the panel named in the URL", () => {
    cy.visit("/#support")
    cy.get("dialog#support").should("have.attr", "open")
    cy.contains("dialog#support button", "Donate with PayPal").should("be.visible")
    cy.get("body").type("{esc}")
    cy.get("dialog#support").should("not.have.attr", "open")
  })

  it("converts every number when the units change", () => {
    cy.contains(".seg span", "mm").click()
    field("width").should("have.value", "127")
    field("thickness").should("have.value", "6.22")
    cy.get(".num span").first().should("have.text", "mm")
    cy.get(".chips button").first().should("have.text", "3 mm")
  })

  it("reads a decimal comma, and converts it", () => {
    field("thickness").clear().type("0,25")
    cy.get(".hint").should("be.empty")
    field("width").clear().type("5,5")
    cy.contains(".seg span", "mm").click()
    field("width").should("have.value", "139.7")
    field("thickness").should("have.value", "6.35")
  })

  it("does not take a number with letters after it", () => {
    field("width").clear().type("5 in")
    cy.get(".hint").should("contain", "Width needs a number above zero")
    cy.get(".go").should("be.disabled")
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

  it("refuses a box with more notches than a laser can cut", () => {
    field("width").clear().type("100")
    field("thickness").clear().type("0.05")
    cy.get(".hint").should("contain", "669 notches along the longest side")
    cy.get(".go").should("be.disabled")
    // The preview keeps the last box it could draw, even when a field takes focus.
    field("width").focus()
    cy.get(".stage svg polygon.finger").its("length").should("be.lessThan", 1500)
  })

  it("starts from the defaults when what was saved is unusable", () => {
    for (const saved of ["null", "{oops", JSON.stringify({ width: "9", lid: "dome", page_size: "NOPE" })]) {
      cy.window().then((win) => win.localStorage.setItem("makeabox:settings:v1", saved))
      cy.reload()
      cy.get(".stage svg polygon.face").should("have.length", 3)
      field("lid").should("have.value", "full")
      field("page_size").should("have.value", "")
    }
    field("width").should("have.value", "9")
  })

  it("remembers the settings in this browser", () => {
    field("depth").clear().type("7.5")
    cy.contains(".seg span", "mm").click()
    cy.reload()
    field("depth").should("have.value", "190.5")
    cy.get('[name="box[units]"][value="mm"]').should("be.checked")

    cy.contains("button", "Kerf, page, margins").click()
    cy.contains("button", "Reset everything to defaults").click()
    field("depth").should("have.value", "4")
    cy.get('[name="box[units]"][value="in"]').should("be.checked")
  })

  it("offers the optional settings with the gem's defaults as placeholders", () => {
    cy.contains("button", "Kerf, page, margins").click()
    field("kerf").should("have.attr", "placeholder", "0.0024")
    field("page_size").find("option").should("have.length.greaterThan", 10)
    cy.screenshot("settings", { capture: "viewport" })
    cy.contains("button", "Done").click()
    cy.get("dialog.sheet").first().should("not.have.attr", "open")
  })

  it("says what went wrong, and recovers on the next try", () => {
    // Once only: the second Generate goes to the real server, untouched.
    cy.intercept({ method: "GET", url: "/box/stream*", times: 1 }, { headers: { "content-type": "text/event-stream" }, body: 'event: failed\ndata: {"message":"laser-cutter could not draw this box: no luck"}\n\n' }).as("stream")
    cy.get(".go").click()
    cy.wait("@stream")
    cy.get("dialog.cut").should("have.class", "failed")
    cy.get("dialog.cut .progress").should("contain", "no luck")
    cy.contains("button", "Download SVG").should("be.disabled")
    cy.get("dialog.cut .x").click()

    cy.get(".go").click()
    cy.contains("dialog.cut .progress", "Ready", { timeout: 10000 })
    cy.get("dialog.cut").should("not.have.class", "failed")
  })

  it("reports a lost connection", () => {
    cy.intercept("GET", "/box/stream*", { forceNetworkError: true })
    cy.get(".go").click()
    cy.get("dialog.cut .progress").should("contain", "makeabox stopped answering")
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

  it("keeps the notch length between 0.4 in and a third of the shortest side", () => {
    cy.get(".field.notch .range").should("have.text", "0.4 to 1 in")
    field("notch").type("2")
    cy.get(".hint").should("contain", "Notch length has to be between 0.4 and 1 in")
    cy.get(".go").should("be.disabled")

    field("notch").clear().type("0.5")
    cy.get(".hint").should("be.empty")
    field("notch").type("{uparrow}{uparrow}{uparrow}{uparrow}{uparrow}{uparrow}{uparrow}{uparrow}{uparrow}{uparrow}{uparrow}{uparrow}")
    field("notch").should("have.value", "1")

    field("notch").clear().type("{uparrow}")
    field("notch").should("have.value", "0.785")
    cy.get(".go").click()
    cy.contains("dialog.cut dd", "0.785 in")
    cy.contains("dialog.cut .progress", "Ready", { timeout: 10000 })
  })

  it("offers a small box a range the server accepts at both ends", () => {
    for (const side of ["width", "height", "depth"]) field(side).clear().type("1")
    field("thickness").clear().type("0.1")
    cy.get(".field.notch .range").should("have.text", "0.16 to 0.33 in")

    for (const notch of ["0.33", "0.16"]) {
      field("notch").clear().type(notch)
      cy.get(".hint").should("be.empty")
      cy.request(`/box/download.svg?box[width]=1&box[height]=1&box[depth]=1&box[thickness]=0.1&box[units]=in&box[notch]=${notch}`).its("status").should("eq", 200)
    }
    field("notch").clear().type("0.34")
    cy.get(".go").should("be.disabled")
  })

  it("shows the range in millimetres", () => {
    cy.contains(".seg span", "mm").click()
    cy.get(".field.notch .range").should("have.text", "10 to 25.4 mm")
  })

  it("cuts a lid that lifts off", () => {
    field("lid").find("option:disabled").should("not.exist")
    field("lid").select("plain")
    cy.get(".go").click()
    cy.contains("dialog.cut .progress", "Ready", { timeout: 10000 })
    cy.get("dialog.cut .progress").should("contain", "248 of 248 lines")
    cy.contains("dialog.cut dd", "Lid, no tabs")
    cy.screenshot("lid", { capture: "viewport" })
  })

  it("downloads the PDF from the dialog, for the settings on the form", () => {
    field("width").clear().type("6")
    field("lid").select("plain")
    cy.intercept("GET", "/box/download.pdf*").as("pdf")
    cy.get(".go").click()
    cy.contains("dialog.cut .progress", "Ready", { timeout: 10000 })
    cy.contains("button", "Download PDF").click()
    cy.wait("@pdf").its("request.url").should("contain", "box%5Bwidth%5D=6").and("contain", "box%5Blid%5D=plain")
    cy.get("dialog.cut").should("not.have.attr", "open")
    cy.readFile("tmp/cypress/downloads/makeabox-6x3x4in-0.245t.pdf", "latin1").should("match", /^%PDF-/)
  })

  it("counts each click on a download button in Google Analytics", () => {
    cy.window().then((win) => { win.gtag = cy.stub().as("gtag") })
    cy.intercept("GET", "/box/download.pdf*", { statusCode: 422, body: "Stroke has to be above zero, or leave it blank." })
    cy.get(".go").click()
    cy.contains("dialog.cut .progress", "Ready", { timeout: 10000 })

    cy.contains("button", "Download PDF").click()
    cy.get("@gtag").should("have.been.calledWith", "event", "pdf_download", { file_name: "makeabox-5x3x4in-0.245t.pdf" })
    cy.contains("button", "Download SVG").click()
    cy.get("@gtag").should("have.been.calledWith", "event", "svg_download", { file_name: "makeabox-5x3x4in-0.245t.svg" })
  })

  it("keeps the dialog open and says why when the PDF is refused", () => {
    cy.get(".go").click()
    cy.contains("dialog.cut .progress", "Ready", { timeout: 10000 })
    cy.intercept("GET", "/box/download.pdf*", { statusCode: 422, body: "Stroke has to be above zero, or leave it blank." })
    cy.contains("button", "Download PDF").click()
    cy.get("dialog.cut").should("have.attr", "open")
    cy.get("dialog.cut .progress").should("contain", "Stroke has to be above zero")
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
    // Three sides share a row; thickness and the notch drop to the next one.
    const top = (name) => field(name).then(($input) => Math.round($input[0].getBoundingClientRect().top))
    top("width").then((first) => {
      top("depth").should("eq", first)
      top("thickness").should("be.greaterThan", first)
      top("notch").should("be.greaterThan", first)
    })
    cy.get("body").should(($body) => expect($body[0].scrollWidth).to.be.at.most(390))
    cy.screenshot("phone", { capture: "viewport" })
  })

  it("folds the nav into a hamburger menu on a phone, with every link in it", () => {
    cy.viewport(390, 844)
    cy.get(".site-header nav").should("not.be.visible")
    cy.get(".burger").should("have.attr", "aria-expanded", "false").click()
    cy.get(".burger").should("have.attr", "aria-expanded", "true")
    for (const name of ["How the tabs work", "Discussion", "GitHub", "Donate"]) cy.contains(".site-header nav a", name).should("be.visible")
    cy.screenshot("phone-menu", { capture: "viewport" })

    cy.contains(".site-header nav a", "Donate").click()
    cy.get(".site-header nav").should("not.be.visible")
    cy.get("dialog#support").should("have.class", "up")

    cy.get(".burger").click()
    cy.get("body").type("{esc}")
    cy.get(".site-header nav").should("not.be.visible")
    cy.get(".burger").click()
    cy.get(".bench").click("topLeft", { force: true })
    cy.get(".site-header nav").should("not.be.visible")
  })

  it("keeps the nav in the header on a wide screen", () => {
    cy.get(".burger").should("not.be.visible")
    cy.contains(".site-header nav a", "Donate").should("be.visible")
  })
})
