class Hubcap::Server < Hubcap::Group

  attr_reader(:address)


  def initialize(parent, name, options = {}, &blk)
    super(parent, name, &blk)
    # If name is an IP, or is not in hosts hash, use name as address
    # Otherwise, dereference it from the hash and assign it
    unless @address = options[:address]
      hist = history.join('.')
      @address = lookup(hist)
      @address = lookup(name)  if @address == hist
    end
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
    nil
  end


  def yaml
    { 'classes' => puppet_roles, 'parameters' => params }.to_yaml
  end


  class Hubcap::ServerSubgroupDisallowed < StandardError; end

end
