require 'test_helper'

class Cappet::TestServer < Test::Unit::TestCase

  def test_address
    top = Cappet.groups { server('test') }
    assert_equal('test', top.servers.first.address)
    top = Cappet.groups { server('test', :address => 'test.example.com') }
    assert_equal('test.example.com', top.servers.first.address)
  end


  def test_subgroups_disallowed
    assert_raises(Cappet::ServerSubgroupDisallowed) {
      Cappet.groups { server('test') { application('child') } }
    }
    assert_raises(Cappet::ServerSubgroupDisallowed) {
      Cappet.groups { server('test') { server('child') } }
    }
    assert_raises(Cappet::ServerSubgroupDisallowed) {
      Cappet.groups { server('test') { group('child') } }
    }
  end


  def test_application_parent
    # No application
    top = Cappet.groups { server('test') }
    assert_equal(nil, top.servers.first.application_parent)

    # Direct inheritance
    top = Cappet.groups {
      application('foo') { server('test') }
      application('bar')
    }
    assert_equal('foo', top.servers.first.application_parent.name)

    # Grandparent in a complex structure
    top = Cappet.groups {
      group('everything') {
        application('baz') {
          group('g1') {
            server('test')
          }
        }
      }
    }
    assert_equal('baz', top.servers.first.application_parent.name)
  end


  def test_yaml
    top = Cappet.groups {
      group('everything') {
        role('baseline')
        server('test') {
          role('test::server')
          param('foo' => 1, 'bar' => 2)
        }
      }
    }
    hash = YAML.load(top.servers.first.yaml)
    assert_equal(['baseline', 'test::server'], hash['classes'])
    assert_equal(['classes', 'parameters'], hash.keys.sort)
    assert_equal(['bar', 'foo'], hash['parameters'].keys.sort)
    assert_equal([1, 2], hash['parameters'].values.sort)
  end

end
