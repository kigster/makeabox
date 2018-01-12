# Use the barebones version of Ruby 2.2.3.
FROM ruby:2.4-onbuild

RUN apt-get update && \
  apt-get install -qq -y \
  --fix-missing --no-install-recommends \
  build-essential htop nodejs 

WORKDIR /usr/src/app

# Provide dummy data to Rails so it can pre-compile assets.
RUN bundle exec rake RAILS_ENV=production assets:precompile
EXPOSE 3000
# The default command that gets ran will be to start the Unicorn server.
CMD bundle exec puma -C config/puma.rb 
