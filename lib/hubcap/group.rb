class Hubcap::Group

  attr_reader(:name, :parent, :children)

  # Supply the parent group, the name of this new group and a block of code to
  # evaluate in the context of this new group.
  #
  # Every group must have a parent group, unless it is the top-most group: the
  # hub. The hub must be a Hubcap::Hub.
  #
  def initialize(parent, name, &blk)
    @name = name.to_s
    @parent = parent
    unless @parent || kind_of?(Hubcap::Hub)
      raise(Hubcap::GroupWithoutParent, self.inspect)
    end
    @cap_attributes = {}
    @cap_roles = []
    @puppet_roles = []
    @params = {}
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
  # match any of the filters or are below the furthest point in the filter.
  #
  # "Match the filter" means that this group's history and the filter are
  # identical to the end of the shortest of the two arrays.
  #
  def processable?
    hub.filters.any? { |fr| matching_filter?(fr) }
  end


  # Indicates whether we should store this group in the hub's array of
  # groups/applications/servers. We only store groups at the end of the filter
  # and below.
  #
  # That is, this group's history should be the same length or longer than the
  # filter, but identical at each point in the filter.
  #
  def collectable?
    hub.filters.any? { |fr| history.size >= fr.size && matching_filter?(fr) }
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



  def cap_attributes
    @parent ? @parent.cap_attributes.merge(@cap_attributes) : @cap_attributes
  end


  def cap_roles
    @parent ? @parent.cap_roles + @cap_roles : @cap_roles
  end


  def puppet_roles
    @parent ? @parent.puppet_roles + @puppet_roles : @puppet_roles
  end


  def params
    @parent ? @parent.params.merge(@params) : @params
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
    if @cap_roles == @puppet_roles
      outs << "Role: #{@cap_roles.inspect}"  if @cap_roles.any?
    else
      cr = @cap_roles.any? ? 'Cap - '+@cap_roles.inspect : nil
      pr = @puppet_roles.any? ? 'Puppet - '+@puppet_roles.inspect : nil
      outs << "Role: #{[cr,pr].compact.join(' ')}"  if cr || pr
    end
    outs << "Pram: #{@params.inspect}"  if @params.any?
    extend_tree(outs)  if respond_to?(:extend_tree)
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


    def matching_filter?(fr)
      s = [history.size, fr.size].min
      history.slice(0, s) == fr.slice(0, s)
    end



  class Hubcap::GroupWithoutParent < StandardError; end

end
