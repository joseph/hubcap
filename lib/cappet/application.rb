class Cappet::Application < Cappet::Group

  attr_reader(:recipe_paths)

  def initialize(parent, name, options = {}, &blk)
    @recipe_paths = [options[:recipes]].flatten.compact
    super(parent, name, &blk)
  end


  def application(*args)
    raise(Cappet::NestedApplicationDisallowed)
  end


  def extend_tree(outs)
    outs << "Load: #{@recipe_paths.inspect}"  if @recipe_paths.any?
  end


  class Cappet::NestedApplicationDisallowed < StandardError; end

end

