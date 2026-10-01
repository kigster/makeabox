# frozen_string_literal: true

class HomeController < ApplicationController
  def index
    @settings = {
      defaults:      BoxRequest.defaults,
      pageSizes:     BoxRequest.page_sizes,
      lidsSupported: BoxRequest.lids_supported?
    }
  end
end
