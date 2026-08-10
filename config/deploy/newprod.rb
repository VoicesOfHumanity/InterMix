# TEMPORARY stage for the 2026-08 migration off the IONOS bare-metal box
# (198.71.53.140, Ubuntu 18.04) onto a Hetzner CPX21 in Hillsboro.
#
# It exists so the new server can be deployed to and tested BEFORE any DNS is
# touched. At cutover this file's host replaces the one in production.rb and
# this stage goes away.
#
# NOTE: no SYS_MODE here. production.rb's environment detection keys off it —
# setting it would make the box think it is staging and resolve BASEDOMAIN to
# intermix.cr8.com. Staging sets it; real production must not.

role :web, "ploy@5.78.151.159"
role :app, "ploy@5.78.151.159"
role :db,  "ploy@5.78.151.159", :primary => true

set :branch, "production"
set :rails_env, :production
