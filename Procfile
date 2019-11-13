web: bundle exec puma -C ${PWD}/config/puma.rb -e ${RAILS_ENV:-'development'} -v 
jobs: bundle exec sidekiq -c 5 -e ${RAILS_ENV:-'development'} -C config/sidekiq.yml
