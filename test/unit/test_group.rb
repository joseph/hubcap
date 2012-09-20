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
    assert_equal('foo', hub.groups.first.params[:foo])
  end


  def test_processable
    flunk
  end


  def test_collectable
    flunk
  end


  def test_cap_set
    flunk
  end


  def test_cap_attribute
    flunk
  end


  def test_role
    # Single role
    hub = Hubcap.hub {
      role(:baseline)
      server('test')
    }
    assert_equal([:baseline], hub.servers.first.roles)

    # Multiple roles in a single declaration
    hub = Hubcap.hub {
      role(:baseline, :app)
      server('test')
    }
    assert_equal([:baseline, :app], hub.servers.first.roles)

    # Multiple declarations are additive
    hub = Hubcap.hub {
      role(:baseline)
      server('test') { role(:db) }
    }
    assert_equal([:baseline, :db], hub.servers.first.roles)

    # Separate cap and puppet roles
    hub = Hubcap.hub {
      role(:cap => :app, :puppet => 'testapp')
      server('test')
    }
    assert_equal(:app, hub.servers.first.cap_roles)
    assert_equal('testapp', hub.servers.first.puppet_roles)

    # Separate cap/puppet roles can be defined with an array
    hub = Hubcap.hub {
      role(:cap => [:app, :db])
      server('test') { role(:baseline) }
    }
    assert_equal([:app, :db, :baseline], hub.servers.first.cap_roles)
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
  end

end
