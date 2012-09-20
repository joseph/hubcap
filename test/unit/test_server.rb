require 'test_helper'

class Hubcap::TestServer < Test::Unit::TestCase

  def test_address
    hub = Hubcap.hub { server('test') }
    assert_equal('test', hub.servers.first.address)
    hub = Hubcap.hub { server('test', :address => 'test.example.com') }
    assert_equal('test.example.com', hub.servers.first.address)
  end


  def test_subgroups_disallowed
    assert_raises(Hubcap::ServerSubgroupDisallowed) {
      Hubcap.hub { server('test') { application('child') } }
    }
    assert_raises(Hubcap::ServerSubgroupDisallowed) {
      Hubcap.hub { server('test') { server('child') } }
    }
    assert_raises(Hubcap::ServerSubgroupDisallowed) {
      Hubcap.hub { server('test') { group('child') } }
    }
  end


  def test_application_parent
    # No application
    hub = Hubcap.hub { server('test') }
    assert_equal(nil, hub.servers.first.application_parent)

    # Direct inheritance
    hub = Hubcap.hub {
      application('foo') { server('test') }
      application('bar')
    }
    assert_equal('foo', hub.servers.first.application_parent.name)

    # Grandparent in a complex structure
    hub = Hubcap.hub {
      group('everything') {
        application('baz') {
          group('g1') {
            server('test')
          }
        }
      }
    }
    assert_equal('baz', hub.servers.first.application_parent.name)
  end


  def test_yaml
    hub = Hubcap.hub {
      group('everything') {
        role('baseline')
        server('test') {
          role('test::server')
          param('foo' => 1, 'bar' => 2)
        }
      }
    }
    hash = YAML.load(hub.servers.first.yaml)
    assert_equal(['baseline', 'test::server'], hash['classes'])
    assert_equal(['classes', 'parameters'], hash.keys.sort)
    assert_equal(['bar', 'foo'], hash['parameters'].keys.sort)
    assert_equal([1, 2], hash['parameters'].values.sort)
  end

end
