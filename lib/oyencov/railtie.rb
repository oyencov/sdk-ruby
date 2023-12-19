require_relative "background"
require_relative "controller_tracking"
require_relative "test_reporting"
require_relative "logger"

module OyenCov
  class Railtie < Rails::Railtie
    initializer "oyencov.configure" do
      # puts "lib/oyencov/railtie.rb initializer oyencov.configure"
      OyenCov::Background.start
    end

    config.after_initialize do
      OyenCov::Logger.log("lib/oyencov/railtie.rb config.after_initialize")
      # OyenCov::Logger.log("This is development copy")
      ActiveSupport::Notifications.subscribe("start_processing.action_controller") do |name, start, finish, id, payload|
        # puts(payload)
        ControllerTracking.bump("#{payload[:controller]}##{payload[:action]}")
        puts "ControllerTracking.bump(#{payload[:controller]}##{payload[:action]})"
      end

      if OyenCov.config.mode == "test"
        at_exit do
          OyenCov::Logger.log("Testing mode, persisting rails controller action data.")
          OyenCov::TestReporting.persist_controller_actions!
        end
      end
    end
  end
end
