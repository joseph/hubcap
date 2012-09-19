Capistrano::Configuration.instance(:must_exist).load do

  namespace(:puppet) do

    unless exists?(:cappet_repository)
      set(:cappet_repository) { raise "Required variable: cappet_repository" }
    end
    set(:cappet_branch, 'master')
    set(:cappet_path, '/var/www/provision/cappet')
    set(:cappet_git_password) { Capistrano::CLI.password_prompt }
    set(:cappet_manifest_path) { "#{cappet_path}/puppet/host.pp" }
    set(:cappet_modules_path) { "#{cappet_path}/puppet/modules" }
    set(:cappet_yaml_path) { "#{cappet_path}/puppet/host.yaml" }
    set(:cappet_enc_path) { "#{cappet_path}/puppet/enc" }
    set(:cappet_enc) { "#!/bin/sh\ncat '#{cappet_yaml_path}'" }
    set(:cappet_puppet_parameters, '--no-report')


    desc <<-DESC
      Calls 'check' and 'update' and 'properties', which means it performs a
      check for the necessary puppet dependencies, deploys the puppet scripts
      via git, then pushes up a special yaml file describing the properties of
      this particular server.
    DESC
    task(:freshen) do
      check
      update
      properties
    end


    desc <<-DESC
      Looks for Ruby 1.9 on the server. Installs it (and git-core) if not found.
      Also looks for Puppet 3.0 gem on the server, and installs it if not found.
    DESC
    task(:check) do
      unless exists?(:cappet_agnostic)
        raise "Cappet has not configured this Capistrano instance."
      end
      unless cappet_agnostic
        raise "Puppet tasks are not available in Cappet application mode"
      end

      apt_cmd = [
        "env",
        "DEBCONF_TERSE='yes'",
        "DEBIAN_PRIORITY='critical'",
        "DEBIAN_FRONTEND=noninteractive",
        "apt-get --force-yes -qyu"
      ].join(" ")

      # Because Ubuntu is weird, the 1.9.1 package installs Ruby 1.9.3-p0.
      sudo_bash([
        'if [[ `which ruby` && (`ruby -v` =~ "ruby 1.9") ]]; then',
          'echo "Ruby 1.9 verified";',
        'else',
          "#{apt_cmd} update;",
          "#{apt_cmd} install ruby1.9.1 git-core;",
        'fi'
      ].join(' '))

      # 3.0.0-rc5 is the last version that a) runs on Ruby 1.9 and b) works.
      ppt_ver = '3.0.0.rc5'
      sudo_bash([
        "if [[ `gem q -i -n \"^puppet$\" -v #{ppt_ver}` =~ \"true\" ]]; then",
          'echo "Puppet verified";',
        'else',
          "gem install puppet -v #{ppt_ver} --pre --no-rdoc --no-ri;",
        'fi'
      ].join(' '))

      # Workaround for: http://projects.puppetlabs.com/issues/9862
      sudo_bash([
        'if [[ `egrep -i "^puppet" /etc/group` =~ "puppet" ]]; then',
          'echo "Puppet group exists";',
        'else',
          'groupadd puppet;',
        'fi'
      ].join(' '))
    end


    desc <<-DESC
      Basically, this pulls down your puppet scripts so you can run them.
      It does this by cloning the cappet repository to each server (if necessary),
      then fetching the latest code and resetting to the HEAD of the
      specified branch.
    DESC
    task(:update) do
      handle_data = lambda { |channel, stream, text|
        host = channel[:host]
        logger.info "[#{host} :: #{stream}] #{text}"
        out = case text
        when /\bpassword.*:/i, /passphrase/i  # Git password or SSH passphrase.
          "#{cappet_git_password}\n"
        when %r{\(yes/no\)}                   # Should git connect?
          "yes\n"
        when /accept \(t\)emporarily/         # Should git accept certificate?
          "t\n"
        end
        channel.send_data(out)  if out
      }
      sudo("mkdir -p #{File.dirname(cappet_path)}")
      sudo("chown #{user} #{File.dirname(cappet_path)}")
      run(
        "[ -d #{cappet_path} ] || git clone #{cappet_repository} #{cappet_path}",
        :shell => nil,
        &handle_data
      )
      run(
        [
          "cd #{cappet_path}",
          "git fetch origin",
          "git reset --hard origin/#{cappet_branch}"
        ].join(' && '),
        :shell => nil,
        &handle_data
      )
    end


    desc <<-DESC
      Pushes a YAML file containing all the classes and parameters that Puppet
      needs to know about in order to provision this server. Each file is
      server-specific.
    DESC
    task(:properties) do
      cappet.servers.each { |s|
        put(s.yaml, cappet_yaml_path, :hosts => s.address)
      }
      put(cappet_enc, cappet_enc_path)
      run("chmod +x #{cappet_enc_path}")
    end


    desc <<-DESC
      Tells you what would happen if you ran puppet:apply. This is a safe way
      to test your changes.
    DESC
    task(:noop) do
      run_puppet('--noop')
    end


    desc <<-DESC
      Runs the puppet scripts on each server. Be careful!
    DESC
    task(:apply) do
      run_puppet
    end


    def sudo_bash(cmd, options = {}, &blk)
      sudo("/bin/bash -c \'#{cmd}\'", options, &blk)
    end


    def run_puppet(params = nil)
      sudo([
        "puppet apply",
        "--node_terminus exec",
        "--external_nodes '#{cappet_enc_path}'",
        "--modulepath '#{cappet_modules_path}'",
        cappet_puppet_parameters,
        params,
        "'#{cappet_manifest_path}'"
      ].compact.join(' '))
    end


    before('puppet:noop', 'puppet:freshen')
    before('puppet:apply', 'puppet:freshen')

  end

end
