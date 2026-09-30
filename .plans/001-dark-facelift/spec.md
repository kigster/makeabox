# 001: Dark facelift, laser-cutter 2, Rails 8.1

Status: built, in review. Written 2026-09-30.

This is the first of three specs agreed during brainstorming:

1. **This one.** New look, new front-end stack, laser-cutter 2.
2. PostgreSQL, Devise with Google sign-in, a history of boxes. Not started.
3. Emails through Resend. Not started.

## Goal

Someone lands on makeabox.io, types the inside dimensions of a box, watches it take shape, and leaves with an SVG or a PDF a laser cutter can cut. The page should look like it belongs to 2026, and the drawing should come from laser-cutter 2.

## What Konstantin decided

| Question                | Decision                                                                                          |
| ----------------------- | ------------------------------------------------------------------------------------------------- |
| Scope                   | New look, new stack and the new gem together                                                      |
| Decomposition           | Three specs, facelift first                                                                       |
| Gem                     | laser-cutter 2.0.1 from GitHub, pinned to commit `bf2b831`, until 2.0.1 is on RubyGems; then back to `'~> 2.0'` |
| Stack                   | Rails 8.1, Propshaft, importmap, Stimulus, hand-written CSS, HAML. No Node in the app             |
| Visual direction        | "Lid down": dark honeycomb bed, a plywood box lit by the beam, controls in a strip at the bottom  |
| Form                    | Easy to fill in, and the preview redraws instantly                                                |
| Flow                    | Generate opens a dialog with the SVG; Download SVG or Download PDF; the dialog then closes        |
| Progress                | Real line counts from the gem, plus a laser tracing the drawing                                   |
| Kept                    | PayPal donation                                                                                   |
| Dropped                 | Refine Packaging ads, Commento, the Actions menu                                                  |
| Comments                | giscus on `kigster/makeabox`                                                                      |
| Settings                | Remembered in `localStorage` and restored on load, with a "Reset everything to defaults" link     |
| Lids                    | Offer a lid with tabs on one side and a lid with none, as laser-cutter gains them                 |
| Done means              | A pull request with the checks green and the deploy config updated. Konstantin deploys            |

## What Claude decided while Konstantin slept

Each of these is a judgement call that can be reversed.

| Question                        | Decision                                                                                                   | Why                                                                                                   |
| ------------------------------- | ---------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------- |
| Progress transport              | Server-sent events from `GET /box/stream`, through `ActionController::Live`                                | No Redis, no Action Cable, no job queue. One request, one response                                    |
| Two phases on one bar           | "Working out the tabs" shows the gem's real count, then "Cutting" shows the trace                          | A typical box is drawn in 40 ms, so the real count alone would never be seen                          |
| Downloads                       | `GET /box/download.pdf` and `.svg`; the SVG button saves the copy already in the browser                   | GET needs no CSRF token and no session, and the form works without JavaScript                         |
| Temporary files                 | `Tempfile`, deleted as soon as the bytes are read                                                          | Replaces the `FileCleaner` thread and the shutdown hook                                               |
| Page cache and sessions         | Gone. Development and test no longer need memcached                                                        | The page is static; the form state lives in the browser                                               |
| Lids on an older gem            | The two lid options are shown disabled with a note unless the installed gem defines `Laser::Cutter::Box::LIDS` | The names `full`, `back` and `plain` and the `lid:` key come from laser-cutter PR 21. The bundled gem has them, so the options are on |
| Help                            | One "How the tabs work" section replaces three modals                                                      | Same content, no dialog to dismiss                                                                    |
| Typeface                        | Archivo, variable, self-hosted (SIL OFL)                                                                   | One file covers every weight and width; no request to Google Fonts                                    |
| giscus without its ids          | The page links to GitHub Discussions until `GISCUS_REPO_ID` and `GISCUS_CATEGORY_ID` are set               | The ids only exist once Discussions and the giscus app are enabled on the repository                  |
| Thickness rule                  | Thickness must be smaller than the shortest side                                                           | The old app had no check; this is the loosest rule that still stops nonsense                          |
| `config/secrets.yml`            | Still read, for `secret_key_base`, by `config/application.rb`                                              | Rails 8 ignores the file, and the deploy still ships it                                               |
| Cypress                         | Added, with Node as a development-only dependency                                                          | The global rule asks for an end-to-end suite on every web app                                         |

## How it fits together

```text
browser                                   server
-------                                   ------
generator_controller.js
  form fields ──────────────┐
  lib/iso_box.js  (preview) │
                            ├─ GET /box/stream ──▶ BoxesController#stream
  lib/laser_trace.js        │                        BoxRequest#render('svg')
    progress ◀── event: progress {done, total}         Makeabox::SvgRenderer
    drawing  ◀── event: drawn {svg, filename}
    error    ◀── event: failed {message}
                            │
  Download SVG  (from memory)
  Download PDF ─────────────┴─ GET /box/download.pdf ▶ BoxesController#download
                                                        BoxRequest#render('pdf')
```

- **`BoxRequest`** (`app/models/box_request.rb`) owns everything about one box: reading the parameters, the validation messages, the file name, and the call into laser-cutter. Both controller actions go through it.
- **`Makeabox::SvgRenderer`** (`lib/makeabox/svg_renderer.rb`) is a workaround. See below.
- **`generator_controller.js`** is the only Stimulus controller. The preview and the trace are plain modules under `app/javascript/lib` with no state of their own.

## A bug found in laser-cutter 2.0.0

`Laser::Cutter::Renderer::SvgRenderer` works out the page size again for every line it writes. Measured on this machine:

| Box (in)             | Lines | Gem as released | With the size remembered |
| -------------------- | ----- | --------------- | ------------------------ |
| 5 x 3 x 4 / 0.245    | 376   | 0.65 s          | 0.007 s                  |
| 10 x 10 x 10 / 0.125 | 1,368 | 7.9 s           | 0.045 s                  |

The output is byte for byte the same. `Makeabox::SvgRenderer` subclasses the gem's renderer and memoizes `width` and `height`; a spec pins the output to the gem's. The fix belongs in the gem, after which this class should be deleted. The PDF renderer is not affected.

## Open questions

- [x] **Lids.** Settled by laser-cutter PR 21 (version 2.0.1, merged, not yet on RubyGems): `lid:` is `full`, `back` or `plain`. The form uses the same words, and `BoxRequest.lids_supported?` looks for `Laser::Cutter::Box::LIDS`. The Gemfile takes the gem from GitHub at the merge commit, so all three lids work now; specs and Cypress cover them.
- [ ] **Back to RubyGems.** When laser-cutter 2.0.1 is released, replace the `github:` line in the Gemfile with `gem 'laser-cutter', '~> 2.0'`.
- [ ] **The Ruby API.** The gem is gaining a public entry point that takes every option as a typed object and returns the document without a file. Once released, `BoxRequest#render` should call it, and the `Tempfile` and probably `Makeabox::SvgRenderer` can go.
- [ ] **Close the dialog after a download?** Built as asked. Anyone wanting both files has to generate twice.
- [ ] **giscus.** Enable Discussions on `kigster/makeabox`, install the giscus app, and set the two ids on the server.
- [ ] **Dead code.** `lib/makeabox/logging/` (about 250 lines) is not referenced anywhere. It is why total line coverage reads 42%; everything this change added is covered.

## Third parties (R5)

- **giscus**: its privacy policy says it collects and stores no data. A signed-in visitor gets an encrypted GitHub token in `localStorage`. Visitors need a GitHub account to post. Nothing unusual.
- **Archivo**: SIL Open Font License 1.1; the licence text ships beside the font.
