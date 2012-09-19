require 'test_helper'

class Cappet::TestTop < Test::Unit::TestCase

  def test_top
    top = Cappet.groups { application('example') }
    assert_equal(top, top.top)
  end


  def test_history
    top = Cappet.groups { application('example') }
    assert_equal([], top.history)
  end


  def test_configure_capistrano
    flunk
  end

end
