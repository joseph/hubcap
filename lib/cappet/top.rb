class Cappet::Top < Cappet::Group

  attr_reader(:filter, :applications, :servers, :groups)


  def initialize(filter_string)
    @filter = filter_string.split('.')
    @cap_sets = {}
    @cap_set_clashes = []
    @cap_attributes = {}
    @roles = []
    @params = {}
    @applications = []
    @servers = []
    @groups = []
    super(nil, '')
    @name = '∞'
  end


  def top
    self
  end


  def history
    []
  end


  def cap_set(hash)
    hash.each_pair { |k, v|
      if @cap_sets[k] && @cap_sets[k] != v
        @cap_set_clashes << { k => v }
      else
        @cap_sets[k] = v
      end
    }
  end


  def extend_tree(outs)
    outs << "Sets: #{@cap_sets.inspect}"
  end


  def configure_capistrano(cap)
    raise("Capistrano already configured by cappet!")  if cap.exists?(:cappet)
    cap.set(:cappet, self)

    # FIXME: cap.load(path) would be nicer.
    cap.instance_eval {
      require('cappet/recipes/servers')
      require('cappet/recipes/puppet')
    }

    # Declare the servers.
    servers.each { |s|
      #puts("-> #{s.address}: #{s.roles.inspect}, #{s.cap_attributes.inspect}")
      cap.server(s.address, *(s.roles + [s.cap_attributes]))
    }

    configure_application_mode(cap)  unless capistrano_is_agnostic?(cap)
  end


  # In agnostic mode, Capistrano recipes for specific applications are not
  # loaded, and cap_set collisions are ignored.
  #
  def capistrano_is_agnostic?(cap)
    return cap.fetch(:cappet_agnostic)  if cap.exists?(:cappet_agnostic)
    ag = true
    options = cap.logger.instance_variable_get(:@options)
    if options && options[:actions] && options[:actions].any?
      tasks = options[:actions].clone
      while tasks.any?
        ag = false  unless cap.find_task(tasks.shift)
      end
    end
    cap.set(:cappet_agnostic, ag)
    ag
  end


  private

    def configure_application_mode(cap)
      apps = servers.collect(&:application_parent).compact.uniq

      # A - there should be only one application for all the servers
      if apps.size > 1
        raise "Too many applications: #{apps.collect(&:name).join(', ')}"
      end

      # B - there should be no clash of cap sets
      if @cap_set_clashes.any?
        raise "Cap set clash: #{@cap_set_clashes.inspect}"
      end

      # C - app-specific, but no applications
      if !apps.any?
        raise "In application mode, but no applications."
      else
        # Otherwise, load all recipes...
        cap.set(:application, apps.first.name)
        apps.first.recipe_paths.each { |rp|
          #puts("Load recipe: #{rp}")
          cap.load(rp)
        }
      end

      # ..and declare all cap sets.
      @cap_sets.each_pair { |key, val|
        #puts("Set: #{key} => #{val}")
        val.kind_of?(Proc) ? cap.set(key, &val) : cap.set(key, val)
      }
    end

end
