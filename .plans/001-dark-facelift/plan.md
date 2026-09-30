# 001: Plan

- [x] Ruby 4.0.6, Rails 8.1.4, laser-cutter 2 (now 2.0.1 from GitHub, see the spec); drop Sprockets, sassc, Babel, jQuery, Bootstrap, Tether, Font Awesome
- [x] Propshaft, importmap, Stimulus; self-hosted Archivo
- [x] `BoxRequest`: parameters, validation, file name, rendering through a `Tempfile`
- [x] `BoxesController#stream` (server-sent events) and `#download` (PDF or SVG)
- [x] Page: header, pitch, isometric preview, control strip, settings sheet, Generate dialog
- [x] Below the fold: how the tabs work, donation, discussion, footer
- [x] Settings remembered in `localStorage`
- [x] Lid choices in the form and the preview (disabled only on a gem older than 2.0.1)
- [x] RSpec for the model, both endpoints, the page and the helpers
- [x] Cypress suite, wired into GitHub Actions
- [x] rubocop configuration brought up to the current rubocop
- [x] Production build checked: `assets:precompile` and `secret_key_base` from `config/secrets.yml`
- [ ] Deploy (Konstantin): Ruby 4.0.6 on the server, `cap production deploy`, check that nginx does not buffer `/box/stream`
- [ ] Fix the SVG renderer in laser-cutter, then delete `Makeabox::SvgRenderer`
- [x] Use the gem's lid names (`full`, `back`, `plain`); on, through the pinned 2.0.1 commit
- [ ] Move `BoxRequest#render` to the gem's public Ruby API once it is released
- [x] Review fixes: notch range agrees on both sides, at most 150 notches per edge, download errors answer 422, render deadline
