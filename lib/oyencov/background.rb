require "securerandom"
require "singleton"
require_relative "api_connection"
require_relative "controller_tracking"
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
    # Added to be more fork-aware. Ruby/Puma can fork a process copy-on-write,
    #   but it won't start the threads that are running in the parent process.
    #
    # If the PID > 0 but also not the current process_id, make the thread run.
    @@running_pid = 0

    @loop_interval = 60 # seconds, can be set from server
    @thread = nil
    @reporter = nil
    @api_conn = OyenCov::APIConnection.instance
    @config = OyenCov.config

    def self.start
      if @@running_pid == $$
        OyenCov::Logger.log("OyenCov Background thread is already running.")
        return false
      end

      OyenCov::Logger.log(<<~TXT)
        Env: #{@config.mode}
        program_name: #{$PROGRAM_NAME || "nil"}
        process_type: #{@config.process_type}
        release/git_commit_sha: #{@config.release}
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

          unless clearance && clearance["status"] == "ok"
            OyenCov::Logger.log "Unable to obtain oyencov submission clearance. Stopping OyenCov background thread. #{clearance.inspect}"
            Thread.stop
          end

          @loop_interval = clearance["runtime_report_submission"]["interval"]
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
          runtime_report[:process_type] = @config.process_type

          response = @api_conn.post_runtime_report(runtime_report)

          OyenCov::Logger.log("POST-ing runtime_report: #{runtime_report.to_json}")

          if response && response.body["status"] == "ok"
            OyenCov::Logger.log "POST runtime_report ok."
          else
            OyenCov::Logger.log "POST runtime_report failed. Stopping background thread."
            @@running_pid = 0
            Thread.stop
          end

          # TODO: Set new interval & wiggle.
        end # loop
      }

      @thread.run
      OyenCov::Logger.log("OyenCov Background thread starts.")
      @@running_pid = $$

      nil
    end

    # If production/staging etc, we can exit without further processing.
    # For `test`, persist controller report.
    def self.stop
      @thread.stop
      @@running_pid = 0
    end

    private_class_method
  end
end
