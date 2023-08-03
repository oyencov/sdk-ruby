require_relative "oyencov/configuration"
require_relative "oyencov/simplecov_resultset_translator"

# For now, support only Rails. We bootstrap from Railtie.
module OyenCov
  VERSION = "0.0.1.pre"

  def self.config
    @config ||= OyenCov::Configuration.new
  end

  if defined?(Rails::Railtie) && ENV["OYENONSEN_API_KEY"]
    require_relative "oyencov/railtie"
  end
end
