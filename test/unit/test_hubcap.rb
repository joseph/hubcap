require 'test_helper'

class Hubcap::TestHubcap < Test::Unit::TestCase

  def test_hub
    hub = Hubcap.hub('group2') {
      role(:baseline)
      group('group1') { server('serverA') }
      group('group2') { server('serverB') }
      group('group3') { server('serverC') }
    }
    assert_equal(1, hub.servers.length)
    assert_equal('serverB', hub.servers.last.name)
    assert_equal([:baseline], hub.servers.first.cap_roles)
  end


  def test_load
    # Fully specified path to a single file.
    hub = Hubcap.load('', 'test/data/simple.rb')
    assert_equal('simple', hub.groups.first.name)
    assert_equal('localhost', hub.servers.last.name)

    # You can omit the .rb
    hub = Hubcap.load('', 'test/data/simple')
    assert_equal(1, hub.groups.length)

    # You can load multiple files.
    hub = Hubcap.load('', 'test/data/simple', 'test/data/example')
    assert_equal(6, hub.groups.length)

    # You can load a directory (or directories).
    hub = Hubcap.load('', 'test/data')
    assert_equal(6, hub.groups.length)
    # ..but note that Hubcap doesn't recurse into subdirectories:
    assert_equal(nil, hub.params[:foo])
  end

end
