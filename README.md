# Hubcap

Create a hub for your server configuration. Use it with Capistrano,
Puppet and others.


## Meet Hubcap

You want to provision your servers with Puppet. You want to deploy to your
servers with Capistrano. Where do you define your server infrastructure?

Hubcap lets you define the characteristics of your servers once. Then, when you
need to use Puppet, Capistrano drives. It deploys your Puppet modules and
manifests, plus a special host-specific file, and applies it to the server.
(This is sometimes called "masterless Puppet". It has a lot of benefits that
derive from decentralization and pushing changes on-demand.)

Here's a really simple infrastructure configuration file:

```ruby
group('us') {
  server('app.example.com') {
    role(:app)
    cap_attribute(:primary => true)
  }
  server('db.example.com') {
    role(:db)
    cap_attribute(:no_release => true)
  }
}

group('au') {
  server('example.com.au') {
    role(:app, :db)
    cap_attribute(:primary => true)
  }
}
```

Using this config, you could tell Capistrano to deploy to all servers, servers
in one group, or just a single server.

Here's a more advanced example - an application that can be deployed to a set
of *staging* servers or a larger set of *production* servers. It has special
parameters that Puppet will use.

```ruby
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
```

Save this as `example.rb` in a `hub` subdirectory of the location of your
`Capfile`.

Run:

    $ hubcap ALL servers:tree

That's a lot of info. You can filter your server list to target specific
groups of servers:

    $ `hubcap example.vagrant servers:tree`

You can run `list` in place of `tree` to see just the servers that match
your filter:

    $ `hubcap example.production.db servers:tree`


### Working with Puppet

You should have your Puppet modules in a git repository. The location of this
repository should be specified in your Capfile with
`set(:puppet_repository, '...')`. Your site manifest should be within this repo
at `puppet/host.pp` (but this is also configurable).

When you're ready to provision some servers:

    $ `hubcap example.vagrant puppet:noop`
    $ `hubcap example.vagrant puppet:apply`

Once that's done, you can deploy your app in the usual way:

    $ `hubcap example.vagrant deploy:setup deploy:cold`



### The Hubcap DSL

The Hubcap DSL is very simple. This is the basic set of statements:

* `group` - A named set of servers, roles, variables, attributes. Groups
  can be nested.

* `application` - A special kind of group. You can pass `:recipes => ...`
  to this declaration. Each recipe path will be loaded into Capistrano only
  for this application. Applications can't be nested.

* `server` - An actual host that you are managing with Capistrano and
  Puppet. The first argument is the name, which can be an IP address or domain
  name if you like. Otherwise, pass `:address => '...'`.

* `cap_set` - Set a Capistrano variable.

* `cap_attribute` - Set a Cap attribute on all the servers within this
  group, such as `:primary => true` or `:no_release => true`.

* `role` - Add a role to the list of Capistrano roles for servers within
  this group. By default, these roles are supplied as classes to apply to the 
  host in Puppet. You can specify that a role is Capistrano-only with
  `cap_role()`, or Puppet-only with `puppet_role()`. This is additive:
  if you have multiple role declarations in your tree, all of them apply.

* `param` - Add to a hash of 'parameters' that will be supplied to Puppet
  as top-scope variables for servers in this group. Like `role`, this is 
  additive.

Hubcap uses Puppet's External Node Classifier (ENC) feature to provide the
list of classes and parameters for a specific host. More info here: 
http://docs.puppetlabs.com/guides/external_nodes.html


### Hubcap as a library

If you'd rather run `cap` than `hubcap`, you can load your hub configuration
directly in your `Capfile`. Add this to the end of the file:

```ruby
require('hubcap')
Hubcap.load('', 'hub').configure_capistrano(self)
```

The two arguments to `Hubcap.load` are the filter (where `''` means no filter),
and the path to the hub configuration. This will load `*.rb` in the `hub`
directory (but not subdirectories). You can specify multiple paths as additional
arguments -- whole directories or specific files.

If you want to simulate the behaviour of the `hubcap` script, you could do it
with something like this in your `Capfile`.

```ruby
# Load servers and sets from node config. Any recipes loaded after this
# point will be available only in application mode.
if (target = ENV['TO']) && !ENV['TO'].empty?
  target = ''  if target == 'ALL'
  require('hubcap')
  Hubcap.load(target, 'hub').configure_capistrano(self)
else
  warn('NB: No servers specified. Target a Hubcap group with TO.')
end
```

In this set-up, you'd run `cap` like this:

    $ cap TO=example.vagrant servers:tree

