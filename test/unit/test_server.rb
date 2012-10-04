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
    assert_equal({ 'baseline' => nil, 'test::server' => nil }, hash['classes'])
    assert_equal(['classes', 'parameters'], hash.keys.sort)
    assert_equal(['bar', 'foo'], hash['parameters'].keys.sort)
    assert_equal([1, 2], hash['parameters'].values.sort)
  end


  def test_host_lookup_single_level
    hub = Hubcap.hub {
      host('test' => '0.0.0.0')
      server('test')
    }
    assert_equal('0.0.0.0', hub.servers.first.address)
  end


  def test_host_lookup_multiple_levels
    hub = Hubcap.hub {
      host('g1.t1' => '1.1.1.1')
      host('g1.a1.t2' => '2.2.2.2')
      group('g1') {
        server('t1')
        application('a1') {
          server('t2')
        }
      }
    }
    assert_equal('1.1.1.1', hub.servers[0].address)
    assert_equal('2.2.2.2', hub.servers[1].address)
  end


  def test_host_lookup_where_name_is_ip
    hub = Hubcap.hub {
      host(
        'foo' => '255.255.255.255',
        '1.1.1.1' => '255.255.255.254'
      )
      server('1.1.1.1')
    }
    assert_equal('1.1.1.1', hub.servers.first.address)
  end


  def test_host_lookup_where_name_is_not_in_hosts
    hub = Hubcap.hub {
      host(
        'foo.bar.com' => '255.255.255.255',
        'baz.bar.com' => '255.255.255.254'
      )
      server('garply.bar.com')
    }
    assert_equal('garply.bar.com', hub.servers.first.address)
  end


  def test_host_lookup_dereferencing
    hub = Hubcap.hub {
      host('some.other.thing' => '1.1.1.1')
      group('g1') {
        host('g1.t1' => 'some.other.thing')
        server('t1')
      }
    }
    assert_equal('1.1.1.1', hub.servers.first.address)
  end


  def test_host_lookup_handle_circular_reference
    assert_raises(Hubcap::HostCircularReference) {
      hub = Hubcap.hub {
        host('some.other.thing' => 'g1.t1')
        group('g1') {
          host('g1.t1' => 'some.other.thing')
          server('t1')
        }
      }
    }
  end


  def test_host_lookup_where_hosts_is_overridden_in_subgroup
    hub = Hubcap.hub {
      host('g1.t1' => '2.2.2.2')
      group('g1') {
        host('g1.t1' => '1.1.1.1')
        server('t1')
      }
    }
    assert_equal('1.1.1.1', hub.servers[0].address)
  end


  def test_resolv
    hub = Hubcap.hub {
      host('g1.t1' => '2.2.2.2')
      group('g1') {
        host('g1.t1' => '1.1.1.1')
        server('t1')
      }
      server('t2', :address => resolv('g1.t1'))
    }
    assert_equal('1.1.1.1', hub.servers[0].address)
    assert_equal('2.2.2.2', hub.servers[1].address)
  end

end
