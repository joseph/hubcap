# Cappet

Unite Capistrano and Puppet with a single Ruby config file.

Invented by Joseph Pearson at [OverDrive](http://overdrive.com).

## Meet Cappet

You want to provision your servers with Puppet. You want to deploy to your
servers with Capistrano. Where do you define your server infrastructure?

Cappet lets you define the characteristics of your servers once. Then, when you
need to use Puppet, Capistrano drives. It deploys your Puppet modules and
manifests, plus a special host-specific file, and applies it to the server.
(This is sometimes called "masterless Puppet". It has a lot of benefits that
derive from decentralization and pushing changes on-demand.)

Here's what your config file might look like:

    application('example', :recipes => 'deploy') {

      # These cap settings will apply to all the servers within this application
      # group or any subgroups. (The same applies for roles, attributes, etc.)
      cap_set(:repository, 'git@github.com:example/example.git')
      cap_set(:branch, 'master')

      # Load some ssh keys into param() from a separate (more secure?) file.
      # These will be handed to your puppet scripts.
      #absorb('nodes/private/admin_ssh_keys')

      # Just a normal Ruby hash var we can reuse throughout the config.
      common_env = {
        'PGUSER' => 'example',
        'RABBIT_URI' => 'amqp://example:password@localhost:54322'
      }

      # A local dev simulation.
      group('vagrant') {
        param('env' => common_env.merge('PGPASSWORD' => 'password'))
        server('127.0.0.1:2222') {
          role(:app, :db, :queue)
        }
      }

      # Your staging environment.
      group('staging') {
        param('env' => common_env.merge(
          'PGPASSWORD' => 'pa55w3rd',
          'PGHOST' => '10.10.10.20',
          'RABBIT_URI' => 'amqp://example:pa55w3rd@10.10.10.20'
        ))
        server('app', :address => '10.10.10.10') {
          role(:app)
        }
        server('db', :address => '10.10.10.15') {
          role(:db)
        }
        server('queue', :address => '10.10.10.20') {
          role(:queue)
        }
      }

      # Your production environment.
      group('production') {
        prod_env = common_env.merge(
          'PGPASSWORD' => '1391f3a24daef0c78f75cbef9d62eb848c2d454c71a5fd2a',
          'PGHOST' => '20.20.20.20',
          'RABBIT_URI' => 'amqp://example:e18edfa58fa6c5d3a9a@20.20.20.30'
        )
        param('env' => prod_env)
        group('app') {
          role(:app)
          param('env' => prod_env.merge('FORCE_SSL' => '1'))
          server('app-1.example.com')
          server('app-2.example.com')
          server('app-3.example.com')
        }
        group('db') {
          role(:db)
          server('db-1.example.com')
          server('db-2.example.com')
        }
        server('queue-1.example.com') {
          role(:queue)
        }
      }
    }


Save this as `nodes.rb`.

Something like this goes at the end of your Capfile:

     # Load servers and sets from node config. Any recipes loaded after this
     # point will be available only in application mode.
     if (target = ENV['TO']) && !ENV['TO'].empty?
       target = ''  if target == 'ALL'
       require('cappet')
       Cappet.load(target, 'nodes').configure_capistrano(self)
     else
       warn("NB: No servers specified. Target a Cappet group with TO.")
     end

Now, let's see what gets defined:

    $ cap servers:tree TO=ALL

That's a lot of servers. You can filter your server list to target specific
groups of servers: `TO=example.vagrant` or `TO=example.production.db`, for
example.

You can run `list` in place of `tree` to see just the servers that match
your filter.

