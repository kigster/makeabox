role :app, %w{kig@kig.re}
role :web, %w{kig@kig.re}

server 'kig.re', user: 'kig', roles: %w{web app}

set :ssh_options, {
   keys: %w(/Users/kig/.ssh/id_rsa),
   forward_agent: false,
   auth_methods: %w(publickey)
}
