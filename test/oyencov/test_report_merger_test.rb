require "minitest/autorun"
require_relative "../../lib/oyencov/test_report_merger"

class TestReportMergerTest < Minitest::Test
  def setup
  end

  def test_merges_oyencovs_controller_action_hits_reports
    collated_job_report = OyenCov::TestReportMerger.collate_job_reports(
      File.expand_path("../sample_test_reports/oyencov_job_reports/*/oyencov_resultset.json", File.dirname(__FILE__))
    )

    # Just check a few results
    assert_equal(
      collated_job_report["controller_action_hits"]["API::ProductsController#index"],
      210 + 1518 + 0
    )
    assert_equal(
      collated_job_report["controller_action_hits"]["Mobile::HomeController#index"],
      60 + 0 + 489
    )
  end
end
