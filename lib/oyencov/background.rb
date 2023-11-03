require "securerandom"
require "singleton"
require_relative "api_connection"
require_relative "coverage_peek_delta"

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
      if ENV["OYENCOV_DEBUG"]
        puts "Hello #{Rails.env}"
        puts "$PROGRAM_NAME: #{$PROGRAM_NAME || "nil"}"
        puts "@process_type: #{@config.process_type}"
      end

      # Start `Coverage` as soon as possible before other codes are loaded
      CoveragePeekDelta.start

      @thread = Thread.new {
        # Check with backend to get parameters
        sleep(3)
        clearance = @api_conn.get_data_submission_clearance

        if clearance.nil?
          puts "Unable to obtain oyencov submission clearance. Stopping OyenCov background thread."
          Thread.stop
        end

        if ENV["OYENCOV_DEBUG"]
          puts(clearance.body)
        end

        @config.mode == "production" && loop do
          sleep(@loop_interval + 3 - rand(6))
          new_method_hits = CoveragePeekDelta.snapshot_delta
          new_controller_hits = ControllerTracking.snapshot_and_reset!

          puts new_method_hits

          runtime_report = {
            git_commit_sha: @config.release,
            controller_action_hits: new_controller_hits,
            method_hits: new_method_hits
          }
          response = @api_conn.post_runtime_report(runtime_report)

          if response && response.body["status"] == "ok"
            puts "[OyenCov] POST runtime_report ok."
          else
            warn "[OyenCov] POST runtime_report failed. Stopping background thread."
            Thread.stop
          end
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
