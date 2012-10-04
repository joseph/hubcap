# An application called 'readme' that uses Cap's default deployment recipe.
application('readme', :recipes => 'deploy') {
  # Set a capistrano variable.
  cap_set('repository', 'git@github.com:joseph/readme.git')

  # Declare that all servers will have the 'baseline' puppet class.
  puppet_role('baseline')

  group('staging') {
    # Puppet will have a $::exception_subject_prefix variable on these servers.
    param('exception_subject_prefix' => '[STAGING] ')
    # For simple staging, just one server that does everything.
    server('readme.stage', :address => '0.0.0.0') {
      cap_role(:web, :app, :db)
      puppet_role('proxy', 'app', 'db')
    }
  }

  group('production') {
    # Puppet will have these top-scope variables on all these servers.
    param(
      'exception_subject_prefix' => '[PRODUCTION] ',
      'env' => {
        'FORCE_SSL' => true,
        'S3_KEY' => 'AKIAKJRK23943202JK',
        'S3_SECRET' => 'KDJkaddsalkjfkawjri32jkjaklvjgakljkj'
      }
    )

    group('proxy') {
      # Servers will have the :web role and the 'proxy' puppet class.
      cap_role(:web)
      puppet_role('proxy')
      server('proxy-1', :address => '10.10.10.5')
    }

    group('app') {
      # Servers will have the :app role and the 'app' puppet class.
      role(:app)
      server('app-1', :address => '10.10.10.10')
      server('app-2', :address => '10.10.10.11')
    }

    group('db') {
      role(:db)
      server('db-1', :address => '10.10.10.50')
    }
  }
}
