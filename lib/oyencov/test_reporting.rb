require "securerandom"

# For use in CI only, one-off export
#
module OyenCov
  class TestReporting
    def self.persist_controller_actions!
      controller_action_hits = OyenCov::ControllerTracking.snapshot_and_reset!

      # Persist report file
      test_report_dir = File.expand_path(OyenCov.config.test_reporting_dir)
      FileUtils.mkdir_p(test_report_dir)
      test_report_path = OyenCov.config.test_resultset_path

      report_content = {
        controller_action_hits: controller_action_hits
      }

      report_content_json = JSON.generate(report_content)

      File.open(test_report_path, "w+") do |f|
        f.puts(report_content_json)
      end

      puts "[OyenCov] Saved to #{test_report_path}"
    end
  end
end
