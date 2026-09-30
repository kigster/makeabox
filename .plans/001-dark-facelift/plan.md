# 001: Plan

- [x] Ruby 4.0.6, Rails 8.1.4, `laser-cutter ~> 2.0`; drop Sprockets, sassc, Babel, jQuery, Bootstrap, Tether, Font Awesome
- [x] Propshaft, importmap, Stimulus; self-hosted Archivo
- [x] `BoxRequest`: parameters, validation, file name, rendering through a `Tempfile`
- [x] `BoxesController#stream` (server-sent events) and `#download` (PDF or SVG)
- [x] Page: header, pitch, isometric preview, control strip, settings sheet, Generate dialog
- [x] Below the fold: how the tabs work, donation, discussion, footer
- [x] Settings remembered in `localStorage`
- [x] Lid choices in the form and the preview, switched off until the gem supports them
- [x] RSpec for the model, both endpoints, the page and the helper
- [x] Cypress suite, wired into GitHub Actions
- [x] rubocop configuration brought up to the current rubocop
- [x] Production build checked: `assets:precompile` and `secret_key_base` from `config/secrets.yml`
- [ ] Deploy (Konstantin): Ruby 4.0.6 on the server, `cap production deploy`, check that nginx does not buffer `/box/stream`
- [ ] Fix the SVG renderer in laser-cutter, then delete `Makeabox::SvgRenderer`
- [ ] Wire the real lid option once laser-cutter ships it
