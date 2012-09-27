Capistrano::Configuration.instance(:must_exist).load do

  namespace(:puppet) do

    unless exists?(:puppet_repository)
      set(:puppet_repository) { raise "Required variable: puppet_repository" }
    end
    set(:puppet_branch, 'master')
    set(:puppet_path, '/var/www/provision/puppet')
    set(:puppet_git_password) { Capistrano::CLI.password_prompt }
    set(:puppet_manifest_path) { "#{puppet_path}/puppet/host.pp" }
    set(:puppet_modules_path) { "#{puppet_path}/puppet/modules" }
    set(:puppet_yaml_path) { "#{puppet_path}/puppet/host.yaml" }
    set(:puppet_enc_path) { "#{puppet_path}/puppet/enc" }
    set(:puppet_enc) { "#!/bin/sh\ncat '#{puppet_yaml_path}'" }
    set(:puppet_parameters, '--no-report')


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
      unless exists?(:hubcap_agnostic)
        raise "Hubcap has not configured this Capistrano instance."
      end
      unless hubcap_agnostic
        raise "Puppet tasks are not available in Hubcap application mode"
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
          "#{apt_cmd} install ruby1.9.1 ruby1.9.1-dev git-core;",
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
      It does this by cloning the Hubcap repository to each server (if necessary),
      then fetching the latest code and resetting to the HEAD of the
      specified branch.
    DESC
    task(:update) do
      handle_data = lambda { |channel, stream, text|
        host = channel[:server]
        logger.info "[#{stream} :: #{host}] #{text}"
        out = case text
        when /\bpassword.*:/i, /passphrase/i  # Git password or SSH passphrase.
          "#{puppet_git_password}\n"
        when %r{\(yes\/no\)}                  # Should git connect?
          "yes\n"
        when /accept \(t\)emporarily/         # Should git accept certificate?
          "t\n"
        end
        channel.send_data(out)  if out
      }
      sudo("mkdir -p #{File.dirname(puppet_path)}")
      sudo("chown -R #{user} #{File.dirname(puppet_path)}")
      run(
        "[ -d #{puppet_path} ] || git clone #{puppet_repository} #{puppet_path}",
        :shell => nil,
        &handle_data
      )
      run(
        [
          "cd #{puppet_path}",
          "git fetch origin",
          "git reset --hard origin/#{puppet_branch}"
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
      hubcap.servers.each { |s|
        put(s.yaml, puppet_yaml_path, :hosts => s.address)
      }
      put(puppet_enc, puppet_enc_path)
      run("chmod +x #{puppet_enc_path}")
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
        "--external_nodes '#{puppet_enc_path}'",
        "--modulepath '#{puppet_modules_path}'",
        puppet_parameters,
        params,
        "'#{puppet_manifest_path}'"
      ].compact.join(' '))
    end


    before('puppet:noop', 'puppet:freshen')
    before('puppet:apply', 'puppet:freshen')

  end

end
