Capistrano::Configuration.instance(:must_exist).load do

  namespace(:servers) do

    desc <<-DESC
      Lists all the servers that match the filter used when Hubcap was loaded.
    DESC
    task(:default) do
      outs = hubcap.servers.collect { |s|
        out = ["#{s.name}#{"(#{s.address})"  if s.name != s.address}"]
        if app = s.application_parent
          out << "  Appli: #{app.name}"
        end
        out << ["  Attrs: "+s.cap_attributes.inspect]  if s.cap_attributes.any?
        if s.cap_roles == s.puppet_roles
          out << "  Roles: #{s.cap_roles}"
        else
          cr = s.cap_roles.any? ? 'Cap - '+s.cap_roles.inspect : nil
          pr = s.puppet_roles.any? ? 'Puppet - '+s.puppet_roles.inspect : nil
          out << "  Roles: #{[cr,pr].compact.join(" | ")}"  if cr || pr
        end
        out << "  Parms: #{s.params.inspect}"  if s.params.any?
        out.join("\n")
      }
      puts(outs.join("\n\n"))
    end


    task(:list) do
      outs = hubcap.servers.collect { |s|
        out = []
        out << s.history.join('.')
        out << s.address
        out << "App[#{s.application_parent.name}]"  if s.application_parent
        if s.cap_roles == s.puppet_roles
          out << "Role#{s.cap_roles}"
        else
          out << "Cap#{s.cap_roles}"  if s.cap_roles.any?
          out << "Pup#{s.puppet_roles}"  if s.puppet_roles.any?
        end
        out.join(', ')
      }
      puts(outs.join("\n"))
    end


    desc <<-DESC
      Show the entire Hubcap configuration tree for the given filter.
    DESC
    task(:tree) do
      tree = lambda { |obj, indent|
        outs = [obj.class.name.split('::').last.upcase+': '+obj.name]
        atts = obj.instance_variable_get(:@cap_attributes)
        croles = obj.instance_variable_get(:@cap_roles)
        proles = obj.instance_variable_get(:@puppet_roles)
        prams = obj.instance_variable_get(:@params)
        outs << "Atts: #{atts.inspect}"  if atts.any?
        if croles == proles
          outs << "Role: #{croles.inspect}"  if croles.any?
        else
          cr = croles.any? ? 'Cap - '+croles.inspect : nil
          pr = proles.any? ? 'Puppet - '+proles.inspect : nil
          outs << "Role: #{[cr,pr].compact.join(' ')}"  if cr || pr
        end
        outs << "Parm: #{prams.inspect}"  if prams.any?
        if obj.is_a?(Hubcap::Hub)
          outs << "Sets: #{obj.instance_variable_get(:@cap_sets).inspect}"
        elsif obj.is_a?(Hubcap::Application)
          recipes = obj.instance_variable_get(:@recipe_paths)
          outs << "Load: #{recipes.inspect}"  if recipes.any?
        end
        if obj.children.any?
          obj.children.each { |child| outs << tree.call(child, indent+"  ") }
        end
        outs.join("\n#{indent}")
      }
      puts(tree.call(hubcap, '  '))
    end

  end

end
