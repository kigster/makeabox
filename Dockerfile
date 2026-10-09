# syntax=docker/dockerfile:1
#
# makeabox for Google Cloud Run (or any container host). See docs/cloud-run.md.
#
#   docker build --platform linux/amd64 -t makeabox .
#   docker run --rm -p 8080:8080 -e SECRET_KEY_BASE=$(bin/rails secret) makeabox
#
# Cloud Run puts TLS, HTTP/2 and the public address in front of the container
# and talks plain HTTP to Puma on $PORT, so there is no nginx in here. Secrets
# are never baked in: pass them at run time (see "Secrets" at the bottom).

ARG RUBY_VERSION=4.0.6

# ── What both stages share ────────────────────────────────────────────────────
FROM ruby:${RUBY_VERSION}-slim AS base

WORKDIR /app

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl libjemalloc2 libyaml-0-2 && \
    rm -rf /var/lib/apt/lists/*

ENV BUNDLE_DEPLOYMENT=1 \
    BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_WITHOUT="development:test:doc" \
    LD_PRELOAD=libjemalloc.so.2

# ── Gems and assets ──────────────────────────────────────────────────────────
FROM base AS build

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git libyaml-dev pkg-config && \
    rm -rf /var/lib/apt/lists/*

COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git

COPY . .

# The real SECRET_KEY_BASE is not needed, or present, to build the assets, and
# New Relic must not start here. The logs this writes stay out of the image.
RUN RAILS_ENV=production SECRET_KEY_BASE_DUMMY=1 NEW_RELIC_AGENT_ENABLED=false bin/rails assets:precompile && \
    rm -rf log/* tmp/*

# ── The image that runs ──────────────────────────────────────────────────────
FROM base

RUN useradd --create-home --shell /bin/bash rails

COPY --from=build /usr/local/bundle /usr/local/bundle
# Owned by rails, whatever the file modes were in the checkout it was built from.
COPY --from=build --chown=rails:rails /app /app

USER rails
RUN mkdir -p log tmp/pids tmp/cache

# Settings that are safe to bake in. Each can be changed at build time with
# --build-arg NAME=value, or at run time with -e / gcloud --set-env-vars.

# Cloud Run sets PORT itself; 8080 is its default and ours.
ARG PORT=8080
# Puma: processes and threads per process. Size WEB_CONCURRENCY to the vCPUs.
ARG WEB_CONCURRENCY=2
ARG RAILS_MIN_THREADS=2
ARG RAILS_MAX_THREADS=4
# Logs go to stdout, where Cloud Logging collects them.
ARG RAILS_LOG_TO_STDOUT=1
ARG DISABLE_LOG_COLORS=1
# debug, info, warn or error.
ARG MAKEABOX_LOG_LEVEL=info
# Empty: assets come from this container. Set it to a CDN or another host.
ARG ASSET_HOST=""
# Empty: no memcached, so Rails caches in memory, per instance.
ARG MEMCACHED_HOST=""
ARG MEMCACHED_PORT=11211
# Empty: no nginx in front to hand files to.
ARG X_SENDFILE_HEADER=""
# New Relic stays off unless enabled and given NEW_RELIC_LICENSE_KEY.
ARG NEW_RELIC_AGENT_ENABLED=false
ARG NEW_RELIC_APP_NAME=makeabox
ARG NEW_RELIC_LOG=stdout

ENV RAILS_ENV=production \
    PORT=${PORT} \
    WEB_CONCURRENCY=${WEB_CONCURRENCY} \
    RAILS_MIN_THREADS=${RAILS_MIN_THREADS} \
    RAILS_MAX_THREADS=${RAILS_MAX_THREADS} \
    RAILS_LOG_TO_STDOUT=${RAILS_LOG_TO_STDOUT} \
    DISABLE_LOG_COLORS=${DISABLE_LOG_COLORS} \
    MAKEABOX_LOG_LEVEL=${MAKEABOX_LOG_LEVEL} \
    ASSET_HOST=${ASSET_HOST} \
    MEMCACHED_HOST=${MEMCACHED_HOST} \
    MEMCACHED_PORT=${MEMCACHED_PORT} \
    X_SENDFILE_HEADER=${X_SENDFILE_HEADER} \
    NEW_RELIC_AGENT_ENABLED=${NEW_RELIC_AGENT_ENABLED} \
    NEW_RELIC_APP_NAME=${NEW_RELIC_APP_NAME} \
    NEW_RELIC_LOG=${NEW_RELIC_LOG}

# Secrets: set these at run time only, never as build arguments, which stay
# readable in the image's history. On Cloud Run use --set-secrets.
#
#   SECRET_KEY_BASE        required; the app will not start without it
#   REDIS_URL              the download counter; without it the counter shows dashes
#   NEW_RELIC_LICENSE_KEY  only with NEW_RELIC_AGENT_ENABLED=true

EXPOSE ${PORT}

CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
