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
