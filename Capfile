# This just lets us test Hubcap without installing it as a gem...
#
$LOAD_PATH.unshift('lib')

# Force Hubcap into agnostic mode with AGNOSTIC=1, or application mode with 0.
# Use this environment variable with care!
#
# if ag = ENV['AGNOSTIC']
#   set(:hubcap_agnostic, ag == '1')  if ['0', '1'].include?(ag)
# end


# SSH user (and login password if required).
#
set(:user, ENV['AS'] || 'deploy')
set(:password) {
  puts
  warn("A server is prompting for the \"#{user}\" user's login password.")
  warn("NB: You can run as another user with the AS environment variable.")
  Capistrano::CLI.password_prompt
}
set(:puppet_repository, 'git@122.100.2.206:cappet.git')


# OKAY! Load servers and sets from node config. Any recipes loaded after this
# point will be available only in application mode.
#
if (target = ENV['TO']) && !ENV['TO'].empty?
  target = ''  if target == 'ALL'
  require('hubcap')
  Hubcap.load(target, 'test/data').configure_capistrano(self)
else
  warn("NB: No servers specified. Target a Hubcap group or server with TO.")
end
