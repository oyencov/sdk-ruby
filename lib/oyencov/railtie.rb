require_relative "background"
require_relative "controller_tracking"
require_relative "test_reporting"

module OyenCov
  class Railtie < Rails::Railtie
    initializer "oyencov.configure" do
      # puts "lib/oyencov/railtie.rb initializer oyencov.configure"
      OyenCov::Background.start
    end

    config.after_initialize do
      !!ENV["OYENCOV_DEBUG"] && puts("lib/oyencov/railtie.rb config.after_initialize")
      ActiveSupport::Notifications.subscribe("start_processing.action_controller") do |name, start, finish, id, payload|
        # puts(payload)
        ControllerTracking.bump("#{payload[:controller]}##{payload[:action]}")
      end

      if OyenCov.config.mode == "test"
        at_exit do
          !!ENV["OYENCOV_DEBUG"] && puts("[OyenCov] Testing mode, persisting rails controller action data.")
          OyenCov::TestReporting.persist_controller_actions!
        end
      end
    end
  end
end
