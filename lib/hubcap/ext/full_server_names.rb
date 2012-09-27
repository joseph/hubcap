require 'capistrano'

class Capistrano::ServerDefinition

  alias base_to_s to_s

  def to_s
    @to_s ||= options[:full_name] || base_to_s
  end

end
