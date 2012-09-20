class Hubcap::Group

  attr_reader(:name, :cap_attributes, :roles, :params, :parent, :children)

  def initialize(parent, name, &blk)
    @name = name
    if @parent = parent
      @cap_attributes = parent.cap_attributes.clone
      @roles = parent.roles.clone
      @params = parent.params.clone
    elsif !kind_of?(Hubcap::Hub)
      raise(Hubcap::GroupWithoutParent, self.inspect)
    end
    @children = []
    instance_eval(&blk)  if blk && processable?
  end


  def absorb(path)
    p = path
    p += '.rb'  unless File.exists?(p)
    raise("File not found: #{path}")  unless File.exists?(p)
    code = IO.read(p)
    eval(code)
  end


  def hub
    @parent ? @parent.hub : self
  end


  def history
    @parent ? @parent.history + [@name] : []
  end


  def processable?
    # My history and the filter are identical to the shortest end.
    s = [history.length, hub.filter.length].min
    history.slice(0,s) == hub.filter.slice(0,s)
  end


  def collectable?
    # My history is same length or longer than filter, but identical to
    # that point.
    processable? && history.length >= hub.filter.length
  end


  # Either:
  #   cap_set(:foo, 'bar')
  # or:
  #   cap_set(:foo => 'bar')
  # and this works too:
  #   cap_set(:foo => 'bar', :garply => 'grault')
  # FIXME this should also work:
  #   cap_set(:foo) { bar }
  #
  def cap_set(*args)
    if args.length == 2
      hub.cap_set(args.first => args.last)
    elsif args.length == 1 && args.first.kind_of?(Hash)
      hub.cap_set(args.first)
    else
      raise ArgumentError('Must be (key, value) or (hash).')
    end
  end


  # Either:
  #   cap_attribute(:foo, 'bar')
  # or:
  #   cap_attribute(:foo => 'bar')
  # and this works too:
  #   cap_attribute(:foo => 'bar', :garply => 'grault')
  #
  def cap_attribute(*args)
    if args.length == 2
      cap_attribute(args.first => args.last)
    elsif args.length == 1 && args.first.kind_of?(Hash)
      @cap_attributes.update(args.first)
    else
      raise ArgumentError('Must be (key, value) or (hash).')
    end
  end


  # When declared multiple times (even in parents), it's additive.
  #
  # Either:
  #   role(:app)
  # or:
  #   role(:app, :db)
  # FIXME or:
  #   role(:cap => :app, :puppet => 'relishapp')
  # FIXME or:
  #   role(:cap => [:app, :db], :puppet => 'relishapp')
  #
  def role(*role_names)
    @roles += role_names
  end


  def param(hash)
    @params.update(hash)
  end


  def add_child(category, child)
    @children << child  if child.processable?
    hub.send(category) << child  if child.collectable?
  end


  def application(name, options = {}, &blk)
    add_child(:applications, Hubcap::Application.new(self, name, options, &blk))
  end


  def server(name, options = {}, &blk)
    add_child(:servers, Hubcap::Server.new(self, name, options, &blk))
  end


  def group(name, &blk)
    add_child(:groups, Hubcap::Group.new(self, name, &blk))
  end


  def tree(indent = "  ")
    outs = [self.class.name.split('::').last.upcase, "Name: #{@name}"]
    outs << "Atts: #{@cap_attributes.inspect}"  if @cap_attributes.any?
    outs << "Pram: #{@params.inspect}"  if @params.any?
    extend_tree(outs)  if respond_to?(:extend_tree)
    outs << ""
    if @children.any?
      @children.each { |child| outs << child.tree(indent+"  ") }
    end
    outs.join("\n#{indent}")
  end


  class Hubcap::GroupWithoutParent < StandardError; end

end
