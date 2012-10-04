require 'test_helper'

class Hubcap::TestGroup < Test::Unit::TestCase

  def test_name
    hub = Hubcap.hub { group('test') }
    assert_equal('test', hub.groups.first.name)
  end


  def test_hub
    hub = Hubcap.hub { group('test') }
    assert_equal(hub, hub.groups.first.hub)
  end


  def test_must_have_parent_unless_hub
    assert_raises(Hubcap::GroupWithoutParent) { Hubcap::Group.new(nil, 'foo') }
  end


  def test_history
    hub = Hubcap.hub { group('test') { group('child') } }
    assert_equal(['test'], hub.children.first.history)
    assert_equal(['test', 'child'], hub.children.first.children.first.history)
  end


  def test_absorb
    hub = Hubcap.hub {
      group('test') { absorb('test/data/parts/foo_param') }
    }
    assert_equal('foo', hub.groups.first.params['foo'])
  end


  def test_processable_and_collectable
    x = {}
    hub = Hubcap.hub('g1.a1') {
      x[:g1] = group('g1') {
        x[:a1] = application('a1') {
          x[:s1] = server('s1')
        }
        x[:a2] = application('a2') {
          x[:s2] = server('s2')
        }
      }
      x[:g2] = group('g2') {
        x[:a3] = application('a3') {
          x[:s3] = server('s3')
        }
      }
    }
    assert_equal(true, x[:g1].processable?)
    assert_equal(false, x[:g1].collectable?)
    assert_equal(true, x[:a1].processable?)
    assert_equal(true, x[:a1].collectable?)
    assert_equal(true, x[:s1].processable?)
    assert_equal(true, x[:s1].collectable?)
    assert_equal(false, x[:g2].processable?)
    assert_equal(false, x[:g2].collectable?)
    assert_nil(x[:a3])
    assert_nil(x[:s3])
  end


  def test_cap_set
    # Single value, as key, val arguments
    hub = Hubcap.hub { group('test') { cap_set(:foo, 'bar') } }
    assert_equal('bar', hub.cap_sets[:foo])

    # Single value, as one hash argument
    hub = Hubcap.hub { group('test') { cap_set('baz' => 'yyy') } }
    assert_equal('yyy', hub.cap_sets['baz'])

    # Multiple values
    hub = Hubcap.hub { group('test') { cap_set(:a => 1, :z => 0) } }
    assert_equal(1, hub.cap_sets[:a])
    assert_equal(0, hub.cap_sets[:z])

    # Lazily-evaluated block
    hub = Hubcap.hub { group('test') { cap_set(:blk) { 'garply' } } }
    assert_equal('garply', hub.cap_sets[:blk].call)
  end


  def test_cap_attribute
    # Single value as key, val arguments
    hub = Hubcap.hub { server('test') { cap_attribute(:foo, 'bar') } }
    assert_equal({ :foo => 'bar' }, hub.servers.first.cap_attributes)

    # Single value as hash
    hub = Hubcap.hub { server('test') { cap_attribute(:foo => 'bar') } }
    assert_equal({ :foo => 'bar' }, hub.servers.first.cap_attributes)

    # Multiple values
    hub = Hubcap.hub { server('test') { cap_attribute(:a => 1, :z => 0) } }
    assert_equal({ :a => 1, :z => 0 }, hub.servers.first.cap_attributes)

    # Cap attributes are additive down the tree
    hub = Hubcap.hub {
      group('g') {
        cap_attribute(:excellent => true)
        server('s') { cap_attribute(:modest => false) }
      }
    }
    assert_equal({ :excellent => true }, hub.groups.first.cap_attributes)
    assert_equal(
      { :excellent => true, :modest => false },
      hub.servers.first.cap_attributes
    )
  end


  def test_role
    # Single role
    hub = Hubcap.hub {
      role(:baseline)
      server('test')
    }
    assert_equal([:baseline], hub.servers.first.cap_roles)
    assert_equal({ 'baseline' => nil }, hub.servers.first.puppet_roles)

    # Multiple roles in a single declaration
    hub = Hubcap.hub {
      role(:baseline, :app)
      server('test')
    }
    assert_equal([:baseline, :app], hub.servers.first.cap_roles)
    assert_equal(
      { 'baseline' => nil, 'app' => nil },
      hub.servers.first.puppet_roles
    )

    # Multiple declarations are additive
    hub = Hubcap.hub {
      role(:baseline)
      server('test') { role(:db) }
    }
    assert_equal([:baseline, :db], hub.servers.first.cap_roles)
    assert_equal(
      { 'baseline' => nil, 'db' => nil },
      hub.servers.first.puppet_roles
    )

    # Separate cap and puppet roles
    hub = Hubcap.hub {
      cap_role(:app)
      puppet_role('testapp')
      server('test')
    }
    assert_equal([:app], hub.servers.first.cap_roles)
    assert_equal({ 'testapp' => nil }, hub.servers.first.puppet_roles)

    # Separate cap/puppet roles can be defined with an array
    # Also shows that multiple role declarations are additive
    hub = Hubcap.hub {
      cap_role(:app, :db)
      server('test') { role(:baseline) }
    }
    assert_equal([:app, :db], hub.cap_roles)
    assert_equal({}, hub.puppet_roles)
    assert_equal([:app, :db, :baseline], hub.servers.first.cap_roles)
    assert_equal({ 'baseline' => nil }, hub.servers.first.puppet_roles)

    # Puppet roles can be passed parameters in a hash.
    hub = Hubcap.hub {
      puppet_role(:foo, :bar, { :garply => { :grault => 'x' } }, :garp)
      server('test') { role(:baseline) }
    }
    assert_equal(
      {
        'foo' => nil,
        'bar' => nil,
        'garply' => { 'grault' => 'x' },
        'garp' => nil,
        'baseline' => nil
      },
      hub.servers.first.puppet_roles
    )
  end


  def test_param
    # Single key/val.
    hub = Hubcap.hub {
      server('test') { param('foo' => 1) }
    }
    assert_equal(1, hub.servers.first.params['foo'])

    # Multiple key/vals.
    hub = Hubcap.hub {
      server('test') { param('foo' => 1, 'baz' => 2) }
    }
    assert_equal(1, hub.servers.first.params['foo'])
    assert_equal(2, hub.servers.first.params['baz'])

    # Recursive stringification of hash keys.
    hub = Hubcap.hub {
      server('test') {
        param(:foo => { :bar => { :garply => 'grault' } })
      }
    }
    assert_equal('foo', hub.servers.first.params.keys.first)
    assert_equal('bar', hub.servers.first.params['foo'].keys.first)
    assert_equal('garply', hub.servers.first.params['foo']['bar'].keys.first)

    # Top-level keys other than strings or symbols are rejected.
    assert_raises(Hubcap::InvalidParamKeyType) {
      hub = Hubcap.hub { server('test') { param(1 => 'x') } }
    }
  end

end
