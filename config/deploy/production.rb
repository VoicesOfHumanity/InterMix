# Simple Role Syntax
# ==================
# Supports bulk-adding hosts to roles, the primary
# server in each group is considered to be the first
# unless any hosts have the primary property set.
# Don't declare `role :all`, it's a meta role
role :web, "ploy@198.71.53.140"                          # Your HTTP server, Apache/etc
role :app, "ploy@198.71.53.140"                          # This may be the same as your `Web` server
role :db,  "ploy@198.71.53.140", :primary => true # This is where Rails migrations will run

# Extended Server Syntax
# ======================
# This can be used to drop a more detailed server
# definition into the server list. The second argument
# something that quacks like a hash can be used to set
# extended properties on the server.
#server 'intermix.org', user: 'ploy', roles: %w{web app db}, my_property: :my_value

# you can set custom ssh options
# it's possible to pass any option but you need to keep in mind that net/ssh understand limited list of options
# you can see them in [net/ssh documentation](http://net-ssh.github.io/net-ssh/classes/Net/SSH.html#method-c-start)
# set it globally
#  set :ssh_options, {
#    keys: %w(/home/rlisowski/.ssh/id_rsa),
#    forward_agent: false,
#    auth_methods: %w(password)
#  }
# and/or per server
# server 'example.com',
#   user: 'user_name',
#   roles: %w{web app},
#   ssh_options: {
#     user: 'user_name', # overrides user setting above
#     keys: %w(/home/user_name/.ssh/id_rsa),
#     forward_agent: false,
#     auth_methods: %w(publickey password)
#     # password: 'please use keys'
#   }
# setting per server overrides global ssh_options

#server 'eurodentaire.com',
#   user: 'ploy',
#   roles: %w{web app db},
#   ssh_options: {
#     user: 'ploy', # overrides user setting above
#     keys: %w(/Users/ffunch/.ssh/id_dsa),
#     forward_agent: true,
#     auth_methods: %w(publickey),
#     port: 22222
#   }


set :branch, "production"
set :rails_env, :production