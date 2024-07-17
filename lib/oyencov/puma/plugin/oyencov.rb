require "puma/plugin"
require_relative "../../background"
require_relative "../../logger"

defined?(Puma::Plugin.create) && Puma::Plugin.create do
  OyenCov::Logger.log("Puma::Plugin.create running...")

  def config(c)
    OyenCov::Logger.log("Puma::Plugin.create config(c) running...")

    defined?(c.on_booted) && c.on_booted do
      OyenCov::Logger.log("Puma::Plugin.create config on_booted called")
      OyenCov::Background.start
      if defined?(Rails::Railtie)
        load(File.expand_path("../../railtie.rb", File.dirname(__FILE__)))
      else
        OyenCov::Logger.log("on_booted: Railtie undefined 😭")
      end
    end

    defined?(c.on_worker_boot) && c.on_worker_boot do
      OyenCov::Logger.log("Puma::Plugin.create config on_worker_boot called")
      OyenCov::Background.start
      if defined?(Rails::Railtie)
        load(File.expand_path("../../railtie.rb", File.dirname(__FILE__)))
      else
        OyenCov::Logger.log("on_worker_boot: Railtie undefined 😭")
      end
    end
  end
end
