# frozen_string_literal: true

module ApplicationHelper
  GISCUS_KEYS = %w[GISCUS_REPO_ID GISCUS_CATEGORY_ID].freeze

  # Analytics and the New Relic browser agent only make sense on the live site.
  def tracking?
    Rails.env.production?
  end

  # The discussion widget needs ids that giscus.app hands out once Discussions
  # are enabled on the repository. Without them the page links to GitHub instead.
  def giscus?
    GISCUS_KEYS.all? { |key| ENV[key].present? }
  end
end
