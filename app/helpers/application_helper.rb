module ApplicationHelper
  def google?
    Rails.env.production?
  end

  def disqus?
    Rails.env.production?
  end
end
