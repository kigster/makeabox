#@IgnoreInspection BashAddShebang
pkg_name=makeabox
pkg_origin=kigster
pkg_version="0.1.0"
pkg_scaffolding="core/scaffolding-ruby"

declare -A scaffolding_env
scaffolding_env[SECRET_KEY_BASE]="7b1f0e9ecd9f54bc3dee46a85069b38fcd61aaee333e0bc29fa1a5c59f302bd8167ab655fb3a8c48f85ceab12d8196db16ee8210280e1d1b7d1b6ea635426c3d"

declare -A scaffolding_process_bins
scaffolding_process_bins[web]='bundle exec puma -C config/puma.rb -p ${PORT}'
scaffolding_process_bins[release]='bundle exec rake db:migrate'
