require 'test_helper'

class Hubcap::TestHub < Test::Unit::TestCase

  def test_hub
    hub = Hubcap.hub { application('example') }
    assert_equal(hub, hub.hub)
  end


  def test_history
    hub = Hubcap.hub { application('example') }
    assert_equal([], hub.history)
  end


  def test_configure_capistrano
    flunk
  end

end
