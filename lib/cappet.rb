require 'yaml'

module Cappet

  def self.groups(filter_string = '', &blk)
    Cappet::Top.new(filter_string).tap { |scope|
      scope.instance_eval(&blk)
    }
  end


  def self.load(filter_string, *paths)
    Cappet::Top.new(filter_string).tap { |scope|
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


require 'cappet/group'
require 'cappet/application'
require 'cappet/server'
require 'cappet/top'
