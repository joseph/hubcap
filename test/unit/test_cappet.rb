require 'test_helper'

class Cappet::TestCappet < Test::Unit::TestCase

  def test_groups
    top = Cappet.groups('group2') {
      role(:baseline)
      group('group1') { server('serverA') }
      group('group2') { server('serverB') }
      group('group3') { server('serverC') }
    }
    assert_equal(1, top.servers.length)
    assert_equal('serverB', top.servers.last.name)
    assert_equal([:baseline], top.servers.first.roles)
  end


  def test_load
    # Fully specified path to a single file.
    top = Cappet.load('', 'test/data/simple.rb')
    assert_equal('simple', top.groups.first.name)
    assert_equal('localhost', top.servers.last.name)

    # You can omit the .rb
    top = Cappet.load('', 'test/data/simple')
    assert_equal(1, top.groups.length)

    # You can load multiple files.
    top = Cappet.load('', 'test/data/simple', 'test/data/example')
    assert_equal(6, top.groups.length)

    # You can load a directory (or directories).
    top = Cappet.load('', 'test/data')
    assert_equal(6, top.groups.length)
    # ..but note that Cappet doesn't recurse into subdirectories:
    assert_equal(nil, top.params[:foo])
  end

end
