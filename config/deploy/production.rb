role :app, %w{kig@demo100.demo.wanelo.com}
role :web, %w{kig@demo100.demo.wanelo.com}

server 'demo100.demo.wanelo.com', user: 'kig', roles: %w{web app}

set :ssh_options, {
   keys: %w(/Users/kig/.ssh/id_rsa),
   forward_agent: false,
   auth_methods: %w(publickey)
}
