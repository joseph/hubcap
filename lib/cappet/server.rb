class Cappet::Server < Cappet::Group

  attr_reader(:address)


  def initialize(parent, name, options = {}, &blk)
    @address = options[:address] || name
    super(parent, name, &blk)
  end


  def application(*args)
    raise(Cappet::ServerSubgroupDisallowed, 'application')
  end


  def server(*args)
    raise(Cappet::ServerSubgroupDisallowed, 'server')
  end


  def group(*args)
    raise(Cappet::ServerSubgroupDisallowed, 'group')
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


  class Cappet::ServerSubgroupDisallowed < StandardError; end

end
