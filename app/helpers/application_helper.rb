# frozen_string_literal: true

module ApplicationHelper
  GISCUS_REPO_ID = "MDEwOlJlcG9zaXRvcnkyNDUyMTQzNg=="
  GISCUS_CATEGORY_ID = "52110578"

  # Analytics and the New Relic browser agent only make sense on the live site.
  def tracking?
    Rails.env.production?
  end

  # The discussion widget needs ids that giscus.app hands out once Discussions
  # are enabled on the repository. Without them the page links to GitHub instead.
  def giscus?
    GISCUS_REPO_ID.present? && GISCUS_CATEGORY_ID.present?
  end
end
