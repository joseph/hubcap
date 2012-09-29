class Hubcap::Application < Hubcap::Group

  attr_reader(:recipe_paths)

  def initialize(parent, name, options = {}, &blk)
    @recipe_paths = [options[:recipes]].flatten.compact
    super(parent, name, &blk)
  end


  def application(*args)
    raise(Hubcap::NestedApplicationDisallowed)
  end


  class Hubcap::NestedApplicationDisallowed < StandardError; end

end

