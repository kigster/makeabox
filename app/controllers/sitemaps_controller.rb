# frozen_string_literal: true

# robots.txt points crawlers here. Served from the app because production
# nginx does not treat .xml as a static file, unlike robots.txt.
class SitemapsController < ApplicationController
  def show
    send_data Rails.root.join('public/sitemap.xml').read,
              type: 'application/xml',
              disposition: 'inline'
  end
end
