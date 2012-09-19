class Cappet::Server < Cappet::Group

  attr_reader(:address)


  def initialize(parent, name, options = {}, &blk)
    @address = options[:address] || name
    super(parent, name, &blk)
  end


  def application(*args)
    raise('Not permitted inside a server block: application.')
  end


  def server(*args)
    raise('Not permitted inside a server block: server.')
  end


  def group(*args)
    raise('Not permitted inside a server block: group.')
  end


  def application_parent
    p = self
    while p && p != top
      return p  if p.kind_of?(Cappet::Application)
      p = p.instance_variable_get(:@parent)
    end
  end


  def yaml
    { 'classes' => @roles.collect(&:to_s), 'parameters' => @params }.to_yaml
  end

end
