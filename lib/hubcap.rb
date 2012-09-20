require 'yaml'

module Hubcap

  def self.hub(filter_string = '', &blk)
    Hubcap::Hub.new(filter_string).tap { |scope| scope.instance_eval(&blk) }
  end


  def self.load(filter_string, *paths)
    Hubcap::Hub.new(filter_string).tap { |scope|
      while paths.any?
        path = paths.shift
        if File.directory?(path)
          paths += Dir.glob(File.join(path, '*.rb'))
        else
          scope.absorb(path)
        end
      end
    }
  end

end


require 'hubcap/group'
require 'hubcap/application'
require 'hubcap/server'
require 'hubcap/hub'
