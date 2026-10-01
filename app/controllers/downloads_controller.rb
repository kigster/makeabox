# frozen_string_literal: true

# The count of boxes downloaded since makeabox began, shown in the header.
class DownloadsController < ApplicationController
  # Nobody saves 30 boxes a minute; this keeps the count from being pumped.
  rate_limit to: 30, within: 1.minute, only: :create

  # GET /downloads
  def show
    render json: { total: Makeabox::BoxCounter.total }
  end

  # POST /downloads?kind=svg
  #
  # The SVG is saved in the browser from the drawing it already has, so the
  # page reports it here. A PDF is counted where it is served (BoxesController).
  def create
    return head(:unprocessable_content) unless params[:kind] == 'svg'

    render json: { total: Makeabox::BoxCounter.record_download('svg') }
  end
end
