app:  bundle exec puma -e ${RAILS_ENV:-'development'} -w 4 -t 1:4 -v -d -C config/puma.rb
jobs: bundle exec sidekiq -e ${RAILS_ENV:-'development'} -C config/sidekiq.yml
# app:  bundle exec puma -C config/puma.rb -e ${RAILS_ENV:-'development'} -v -d "$@"
