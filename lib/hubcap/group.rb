class Hubcap::Group

  attr_reader(
    :name,
    :cap_attributes,
    :cap_roles,
    :puppet_roles,
    :params,
    :parent,
    :children
  )

  # Supply the parent group, the name of this new group and a block of code to
  # evaluate in the context of this new group.
  #
  # Every group must have a parent group, unless it is the top-most group: the
  # hub. The hub must be a Hubcap::Hub.
  #
  def initialize(parent, name, &blk)
    @name = name
    if @parent = parent
      @cap_attributes = parent.cap_attributes.clone
      @cap_roles = parent.cap_roles.clone
      @puppet_roles = parent.puppet_roles.clone
      @params = parent.params.clone
    elsif !kind_of?(Hubcap::Hub)
      raise(Hubcap::GroupWithoutParent, self.inspect)
    end
    @children = []
    instance_eval(&blk)  if blk && processable?
  end


  # Load a Ruby file and evaluate it in the context of this group.
  # Like Ruby's require(), the '.rb' is optional in the path.
  #
  def absorb(path)
    p = path
    p += '.rb'  unless File.exists?(p)
    raise("File not found: #{path}")  unless File.exists?(p)
    code = IO.read(p)
    eval(code)
  end


  # Finds the top-level Hubcap::Hub to which this group belongs.
  #
  def hub
    @parent ? @parent.hub : self
  end


  # An array of names, from the oldest ancestor to the parent to self.
  #
  def history
    @parent ? @parent.history + [@name] : []
  end


  # Indicates whether we should process this group. We process all groups that
  # match the filter or are below the furthest point in the filter.
  #
  # "Match the filter" means that this group's history and the filter are
  # identical to the end of the shortest of the two arrays.
  #
  def processable?
    s = [history.length, hub.filter.length].min
    history.slice(0,s) == hub.filter.slice(0,s)
  end


  # Indicates whether we should store this group in the hub's array of
  # groups/applications/servers. We only store groups at the end of the filter
  # and below.
  #
  # That is, this group's history should be the same length or longer than the
  # filter, but identical at each point in the filter.
  #
  def collectable?
    (history.length >= hub.filter.length) && processable?
  end


  # Sets a variable in the Capistrano instance.
  #
  # Note: when Hubcap is in application mode (not executing a default task),
  # an exception will be raised if a variable is set twice to two different
  # values.
  #
  # Either:
  #   cap_set(:foo, 'bar')
  # or:
  #   cap_set(:foo => 'bar')
  # and this works too:
  #   cap_set(:foo => 'bar', :garply => 'grault')
  # in fact, even this works:
  #   cap_set(:foo) { bar }
  #
  def cap_set(*args, &blk)
    if args.length == 2
      hub.cap_set(args.first => args.last)
    elsif args.length == 1
      if block_given?
        hub.cap_set(args.first => blk)
      elsif args.first.kind_of?(Hash)
        hub.cap_set(args.first)
      end
    else
      raise ArgumentError('Must be (key, value) or (hash) or (key) { block }.')
    end
  end


  # Sets an attribute in the Capistrano server() definition for all Hubcap
  # servers to which it applies.
  #
  # For eg, :primary => true or :no_release => true.
  #
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


  # Sets the Capistrano role and/or Puppet class for all Hubcap servers to
  # which it applies.
  #
  # When declared multiple times (even in parents), it's additive.
  #
  # Either:
  #   role(:app)
  # or:
  #   role(:app, :db)
  # or:
  #   role(:cap => :app, :puppet => 'relishapp')
  # or:
  #   role(:cap => [:app, :db], :puppet => 'relishapp')
  #
  def role(*args)
    if args.length == 1 && args.first.kind_of?(Hash)
      h = args.first
      @cap_roles += [h[:cap]].flatten  if h.has_key?(:cap)
      @puppet_roles += [h[:puppet]].flatten  if h.has_key?(:puppet)
    else
      @cap_roles += args
      @puppet_roles += args
    end
  end


  # Adds values to a hash that is supplied to Puppet when it is provisioning
  # the server.
  #
  # If you do this...
  #   params(:foo => 'bar')
  # ...then Puppet will have a top-level variable called $foo, containing 'bar'.
  #
  def param(hash)
    @params.update(hash)
  end


  # Instantiate an application as a child of this group.
  #
  def application(name, options = {}, &blk)
    add_child(:applications, Hubcap::Application.new(self, name, options, &blk))
  end


  # Instantiate a server as a child of this group.
  #
  def server(name, options = {}, &blk)
    add_child(:servers, Hubcap::Server.new(self, name, options, &blk))
  end


  # Instantiate a group as a child of this group.
  #
  def group(name, &blk)
    add_child(:groups, Hubcap::Group.new(self, name, &blk))
  end


  # Returns a formatted string of all the key details for this group, and
  # recurses into each child.
  #
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


  private

    def add_child(category, child)
      @children << child  if child.processable?
      hub.send(category) << child  if child.collectable?
      child
    end


  class Hubcap::GroupWithoutParent < StandardError; end

end
