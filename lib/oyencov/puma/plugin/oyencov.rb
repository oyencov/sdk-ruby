require "puma/plugin"
require_relative "../../background"
require_relative "../../logger"

Puma::Plugin.create do
  OyenCov::Logger.log("Puma::Plugin.create running...")

  def config(c)
    OyenCov::Logger.log("Puma::Plugin.create config(c) running...")

    c.on_worker_boot do
      OyenCov::Logger.log("Puma::Plugin.create config on_worker_boot called")
      OyenCov::Background.start
    end
  end
end
