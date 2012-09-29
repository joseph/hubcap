Capistrano::Configuration.instance(:must_exist).load do

  namespace(:ssh) do

    desc("Shells out to SSH for the first server that matches the filter.")
    task(:default) do
      host = hubcap.servers.first.address
      puts("SSH connect to: #{user}@#{host}")
      system("ssh -A #{user}@#{host}")
    end

  end

end

