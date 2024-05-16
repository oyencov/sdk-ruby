require_relative "oyencov/configuration"
require_relative "oyencov/simplecov_resultset_translator"
require_relative "oyencov/version"
require_relative "oyencov/logger"

# For now, support only Rails. We bootstrap background thread and controller tracking from Railtie.
module OyenCov
  def self.config
    @config ||= OyenCov::Configuration.new
  end

  # Sometimes oyencov cant start on their own, maybe when oyencov is loaded
  #   before Rails did.
  #
  # For Rails, put `OyenCov.start!` in `config/initializers/oyencov.rb`.
  def self.start!
    require_relative "oyencov/railtie"
  end

  OyenCov::Logger.log("Hello! Booting from #{__FILE__}")
  OyenCov::Logger.log("Checking/Forcing Rails existence")

  begin
    require "rails"
  rescue LoadError
    # do nothing
  end

  if defined?(Rails::Railtie) # && ENV["OYENCOV_API_KEY"]
    OyenCov::Logger.log("Rails::Railtie already present, starting oyencov/railtie")
    require_relative "oyencov/railtie"
  else
    OyenCov::Logger.log("Rails::Railtie absent, cannot start tracking & reporting yet.")
  end
end
