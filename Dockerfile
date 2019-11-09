# Use the barebones version of Ruby 2.2.3.
FROM ruby:2.6

RUN apt-get update && \
  apt-get install -qq -y \
  --fix-missing --no-install-recommends \
  build-essential htop nodejs 


WORKDIR /usr/src/app

COPY Gemfile Gemfile.lock ./

ENV RAILS_ENV=production \
    HOME=/usr/src/app

RUN bundle install --jobs 20 --retry 5 --without development test
RUN mkdir -p tmp/pids log

EXPOSE 5001

COPY . .

# Provide dummy data to Rails so it can pre-compile assets.
RUN RAILS_ENV=${RAILS_ENV} bundle exec rake assets:precompile

RUN RAILS_ENV=${RAILS_ENV} bundle exec rails secret > ${HOME}/.secret_key_base


CMD bundle exec puma -C $(pwd)/config/puma-docker.rb

