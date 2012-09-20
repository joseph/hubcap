require 'test_helper'

class Hubcap::TestApplication < Test::Unit::TestCase

  def test_recipe_paths
    hub = Hubcap.hub { application('test', :recipes => 'foo') }
    assert_equal(['foo'], hub.applications.first.recipe_paths)

    hub = Hubcap.hub { application('test', :recipes => ['foo', 'bar']) }
    assert_equal(['foo', 'bar'], hub.applications.first.recipe_paths)
  end


  def test_nested_application_disallowed
    assert_raises(Hubcap::NestedApplicationDisallowed) {
      Hubcap.hub { application('test') { application('child') } }
    }
  end

end
