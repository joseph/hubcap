Capistrano::Configuration.instance(:must_exist).load do

  namespace(:servers) do

    desc <<-DESC
      Lists all the servers that match the filter used when Hubcap was loaded.
    DESC
    task(:list) do
      puts(hubcap.servers.collect(&:tree))
    end

    desc <<-DESC
      Show the entire Hubcap configuration tree for the given filter.
    DESC
    task(:tree) do
      puts(hubcap.tree)
    end

  end


  task(:ssh) do
    host = hubcap.servers.first.address
    puts("SSH connect to: #{user}@#{host}")
    system("ssh -A #{user}@#{host}")
  end

end
