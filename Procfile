#
# vim: filetype=yaml
#

app:  bundle exec puma -C config/puma.rb -e ${RAILS_ENV} -v "$@" 2>&1
jobs: bundle exec sidekiq-pool -e ${RAILS_ENV} -p config/sidekiq-pool.yml -C config/sidekiq.yml 2>&1
