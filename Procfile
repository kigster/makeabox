app:  bundle exec puma -e ${RAILS_ENV:-'development'} -w 4 -t 1:4 -v -C config/puma.rb
jobs: bundle exec sidekiq -e ${RAILS_ENV:-'development'} -C config/sidekiq.yml
css: yarn run watch:css
js: yarn run watch:js
