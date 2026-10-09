# frozen_string_literal: true

Rails.application.routes.draw do
  root 'home#index'

  get 'sitemap.xml', to: 'sitemaps#show', as: :sitemap

  # For Cloud Run and load balancers: 200 once the app has booted.
  get 'up', to: 'rails/health#show', as: :rails_health_check

  # Draws the box as an SVG and reports progress as server-sent events.
  get 'box/stream', to: 'boxes#stream', as: :box_stream
  # The same box as a file: /box/download.pdf or /box/download.svg
  get 'box/download', to: 'boxes#download', as: :box_download
  # How many boxes have been downloaded, and the page reporting an SVG it saved.
  resource :downloads, only: %i[show create]
end
