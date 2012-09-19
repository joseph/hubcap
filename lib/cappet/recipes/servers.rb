Capistrano::Configuration.instance(:must_exist).load do

  namespace(:servers) do

    desc <<-DESC
      Lists all the servers that match the filter used when Cappet was loaded.
    DESC
    task(:list) do
      puts(cappet.servers.collect(&:tree))
    end

    desc <<-DESC
      Show the entire Cappet configuration tree for the given filter.
    DESC
    task(:tree) do
      puts(cappet.tree)
    end

  end

end
