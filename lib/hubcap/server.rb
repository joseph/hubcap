class Hubcap::Server < Hubcap::Group

  attr_reader(:address)


  def initialize(parent, name, options = {}, &blk)
    @address = options[:address] || name
    super(parent, name, &blk)
  end


  def application(*args)
    raise(Hubcap::ServerSubgroupDisallowed, 'application')
  end


  def server(*args)
    raise(Hubcap::ServerSubgroupDisallowed, 'server')
  end


  def group(*args)
    raise(Hubcap::ServerSubgroupDisallowed, 'group')
  end


  def application_parent
    p = self
    while p && p != hub
      return p  if p.kind_of?(Hubcap::Application)
      p = p.instance_variable_get(:@parent)
    end
  end


  def yaml
    { 'classes' => @roles.collect(&:to_s), 'parameters' => @params }.to_yaml
  end


  class Hubcap::ServerSubgroupDisallowed < StandardError; end

end
