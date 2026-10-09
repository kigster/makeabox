# frozen_string_literal: true

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.enable_reloading = false

  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both threaded web servers
  # and those relying on copy on write to perform better.
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = true

  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true
  # Assets carry a digest in their names, so browsers may keep them for a year.
  config.public_file_server.headers = { 'cache-control' => "public, max-age=#{1.year.to_i}, immutable" }

  # Enable Rack::Cache to put a simple HTTP cache in front of your application
  # Add `rack-cache` to your Gemfile before enabling this.
  # For large-scale production use, consider using a caching reverse proxy like nginx, varnish or squid.
  # config.action_dispatch.rack_cache = true

  # Disable Rails's static asset server (Apache or nginx will already do this).
  # config.serve_static_files = true

  # Compress JavaScripts and CSS.

  # Do not fallback to assets pipeline if a precompiled asset is missed.

  # Generate digests for assets URLs.

  # Specifies the header that your server uses for sending files.
  # config.action_dispatch.x_sendfile_header = "X-Sendfile" # for apache
  # nginx on the old server sends files for Rails; in a container nothing does (X_SENDFILE_HEADER="").
  config.action_dispatch.x_sendfile_header = ENV.fetch('X_SENDFILE_HEADER', 'X-Accel-Redirect').presence

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  config.force_ssl = false

  # Set to :debug to see everything in the log.
  config.log_level = :info

  # Prepend all log lines with the following tags.
  # config.log_tags = [ :subdomain, :uuid ]

  # In a container the logs go to stdout, where Cloud Logging collects them.
  config.logger = ActiveSupport::TaggedLogging.logger($stdout) if ENV['RAILS_LOG_TO_STDOUT'].present?

  # Use a different cache store in production.
  # config.cache_store = :mem_cache_store

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # ASSET_HOST overrides it; ASSET_HOST="" serves assets from the app itself, as in a container.
  config.action_controller.asset_host = ENV.fetch('ASSET_HOST') { 'https://makeabox.io' if Makeabox.live? }.presence

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  # config.action_mailer.raise_delivery_errors = false

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners.
  config.active_support.deprecation = :notify

  config.lograge.enabled = true

  # Disable automatic flushing of the log to improve performance.
  config.autoflush_log = false

  # Use default logging formatter so that PID and timestamp are not suppressed.
  config.log_formatter = Logger::Formatter.new

  # memcached on the old server; without one (MEMCACHED_HOST="", as in a container) each process caches in memory.
  config.cache_store = if Makeabox::MEMCACHED_HOST.present?
                         [:mem_cache_store, Makeabox::MEMCACHED_URL, Makeabox.memcached_options(:cache)]
                       else
                         :memory_store
                       end
end
