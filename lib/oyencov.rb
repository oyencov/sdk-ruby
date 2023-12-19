require_relative "oyencov/configuration"
require_relative "oyencov/simplecov_resultset_translator"
require_relative "oyencov/version"
require_relative "oyencov/logger"

# For now, support only Rails. We bootstrap from Railtie.
module OyenCov
  def self.config
    @config ||= OyenCov::Configuration.new
  end

  OyenCov::Logger.log("Checking Rails existence")
  if defined?(Rails::Railtie) # && ENV["OYENCOV_API_KEY"]
    OyenCov::Logger.log("Starting Railtie")
    require_relative "oyencov/railtie"
  end
end
