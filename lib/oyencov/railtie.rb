require_relative "background"
require_relative "controller_tracking"
require_relative "test_reporting"
require_relative "logger"

module OyenCov
  class Railtie < Rails::Railtie
    @@controller_tracker_notification = nil

    # This is only useful when `rails s` is run in lieu of webserver command first.
    def install_puma_hooks
      return unless defined?(Puma)
      OyenCov::Logger.log("Puma defined, installing puma hooks")

      begin
        require "puma/plugin"
      rescue LoadError => e
        OyenCov::Logger.log("Load errors: #{e}")
      end

      # Cluster mode
      if defined?(Puma::Plugin)
        OyenCov::Logger.log("Puma::Plugin defined, installing hooks for CLUSTER MODE")
        require_relative "puma/plugin/oyencov"
      end
    end

    initializer "oyencov.configure" do
      OyenCov::Background.start
      install_puma_hooks

      if @@controller_tracker_notification.nil?
        OyenCov::Logger.log "@@controller_tracker_notification is nil"
      else
        OyenCov::Logger.log "@@controller_tracker_notification is already set, Railtie init rerun."
      end

      @@controller_tracker_notification ||= ActiveSupport::Notifications.subscribe("start_processing.action_controller") do |name, start, finish, id, payload|
        ControllerTracking.bump("#{payload[:controller]}##{payload[:action]}")
        OyenCov::Logger.log "ControllerTracking.bump(#{payload[:controller]}##{payload[:action]})"
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
