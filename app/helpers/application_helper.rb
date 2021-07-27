# frozen_string_literal: true

require 'etc'

module ApplicationHelper
  def google?
    Rails.env.production?
  end

  def asset_image(path, **opts)
    uri = image_path(path, **opts)
    if uri.start_with?('http') && Rails.env.production? && Etc.uname =~ /linux/i
      uri.gsub(/^http:/, 'https:')
    else
      uri
    end
  end
end
