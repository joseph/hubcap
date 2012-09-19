require 'test_helper'

class Cappet::TestApplication < Test::Unit::TestCase

  def test_recipe_paths
    top = Cappet.groups { application('test', :recipes => 'foo') }
    assert_equal(['foo'], top.applications.first.recipe_paths)

    top = Cappet.groups { application('test', :recipes => ['foo', 'bar']) }
    assert_equal(['foo', 'bar'], top.applications.first.recipe_paths)
  end


  def test_nested_application_disallowed
    assert_raises(Cappet::NestedApplicationDisallowed) {
      Cappet.groups { application('test') { application('child') } }
    }
  end

end
