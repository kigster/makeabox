const { defineConfig } = require("cypress")

module.exports = defineConfig({
  e2e: {
    baseUrl: process.env.CYPRESS_BASE_URL || "http://127.0.0.1:3055",
    supportFile: false,
    video: false,
    viewportWidth: 1440,
    viewportHeight: 900,
    screenshotOnRunFailure: true,
    screenshotsFolder: "tmp/cypress/screenshots",
    downloadsFolder: "tmp/cypress/downloads"
  }
})
