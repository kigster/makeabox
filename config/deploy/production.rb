server 'app101.dev.nvnt.re', roles: %w{app db web worker}, user: 'kig'

set :ssh_options, {
   keys: %w(/Users/kig/.ssh/id_rsa),
   forward_agent: false,
   auth_methods: %w(publickey)
}
