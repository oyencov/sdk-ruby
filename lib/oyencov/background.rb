require "securerandom"
require "singleton"
require_relative "api_connection"
require_relative "coverage_peek_delta"
require_relative "logger"

# Bootstrap the thread that starts Coverage module data collection.
#
# Every 60 secs or so:
# 1. Get the coverage peek_result delta
# 2. Parse source code and determine which method being run
# 3. Get controller actions' hits
# 4. Call the reporter
#
# Most of the codes here are inspired by danmayer's coverband gem.
#
module OyenCov
  class Background
    @loop_interval = 60 # seconds, can be set from server
    @semaphore = Mutex.new
    @thread = nil
    @reporter = nil
    @api_conn = OyenCov::APIConnection.instance
    @config = OyenCov.config

    def self.start
      OyenCov::Logger.log(<<~TXT)
        Env: #{@config.mode}
        $PROGRAM_NAME: #{$PROGRAM_NAME || "nil"}
        @process_type: #{@config.process_type}
        Env vars set: #{ENV.keys.grep(/^OYENCOV_/)}
      TXT

      # Start `Coverage` as soon as possible before other codes are loaded
      CoveragePeekDelta.start

      # This thread is for production reporting only.
      @thread = Thread.new {
        # Check with backend to get parameters
        sleep(3)

        if @config.mode == "production"
          clearance = @api_conn.get_data_submission_clearance

          if clearance.nil?
            OyenCov::Logger.log "Unable to obtain oyencov submission clearance. Stopping OyenCov background thread."
            Thread.stop
          end

          # OyenCov::Logger.log("clearance.body:-\n" + clearance.body)
        end

        @config.mode == "production" && loop do
          sleep(@loop_interval + 3 - rand(6))
          new_method_hits = CoveragePeekDelta.snapshot_delta
          OyenCov::Logger.log "ControllerTracking.hits = #{ControllerTracking.hits}"
          new_controller_hits = ControllerTracking.snapshot_and_reset!

          runtime_report = {
            controller_action_hits: new_controller_hits,
            method_hits: new_method_hits
          }

          unless runtime_report.values.any?(&:any?)
            OyenCov::Logger.log("All #{runtime_report.keys.join(", ")} are empty. Skipping submission.")
            next
          end

          runtime_report[:git_commit_sha] = @config.release

          response = @api_conn.post_runtime_report(runtime_report)

          if response && response.body["status"] == "ok"
            OyenCov::Logger.log "POST runtime_report ok."
          else
            OyenCov::Logger.log "POST runtime_report failed. Stopping background thread."
            Thread.stop
          end

          # TODO: Set new interval & wiggle.
        end # loop
      }

      @thread.run

      nil
    end

    # If production/staging etc, we can exit without further processing.
    # For `test`, persist controller report.
    def self.stop
      @thread.stop
    end

    private_class_method
  end
end
