require 'test_helper'

class Cappet::TestGroup < Test::Unit::TestCase

  def test_name
    top = Cappet.groups { group('test') }
    assert_equal('test', top.groups.first.name)
  end


  def test_top
    top = Cappet.groups { group('test') }
    assert_equal(top, top.groups.first.top)
  end


  def test_must_have_parent_unless_top
    assert_raises(Cappet::GroupWithoutParent) { Cappet::Group.new(nil, 'foo') }
  end


  def test_history
    top = Cappet.groups { group('test') { group('child') } }
    assert_equal(['test'], top.children.first.history)
    assert_equal(['test', 'child'], top.children.first.children.first.history)
  end


  def test_absorb
    top = Cappet.groups {
      group('test') { absorb('test/data/parts/foo_param') }
    }
    assert_equal('foo', top.groups.first.params[:foo])
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
    top = Cappet.groups {
      role(:baseline)
      server('test')
    }
    assert_equal([:baseline], top.servers.first.roles)

    # Multiple roles in a single declaration
    top = Cappet.groups {
      role(:baseline, :app)
      server('test')
    }
    assert_equal([:baseline, :app], top.servers.first.roles)

    # Multiple declarations are additive
    top = Cappet.groups {
      role(:baseline)
      server('test') { role(:db) }
    }
    assert_equal([:baseline, :db], top.servers.first.roles)

    # Separate cap and puppet roles
    top = Cappet.groups {
      role(:cap => :app, :puppet => 'testapp')
      server('test')
    }
    assert_equal(:app, top.servers.first.cap_roles)
    assert_equal('testapp', top.servers.first.puppet_roles)

    # Separate cap/puppet roles can be defined with an array
    top = Cappet.groups {
      role(:cap => [:app, :db])
      server('test') { role(:baseline) }
    }
    assert_equal([:app, :db, :baseline], top.servers.first.cap_roles)
  end


  def test_param
    # Single key/val.
    top = Cappet.groups {
      server('test') { param('foo' => 1) }
    }
    assert_equal(1, top.servers.first.params['foo'])

    # Multiple key/vals.
    top = Cappet.groups {
      server('test') { param('foo' => 1, 'baz' => 2) }
    }
    assert_equal(1, top.servers.first.params['foo'])
    assert_equal(2, top.servers.first.params['baz'])
  end

end
