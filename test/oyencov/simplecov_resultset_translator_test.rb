require "json"
require "minitest/autorun"
require_relative "../../lib/oyencov/simplecov_resultset_translator"

# This is meant to be run at the end of the fan-out jobs, and the output
#   artefacts are meant to be persisted for the next job in the workflow.
#
# It's possible the full codebase isn't pulled in the final summarising
#   job. User can opt to just `gem install oyencov` and do the collation
#   and submission with just the gem.
#
# The code should be similar to `CoveragePeekDelta`.
#
# A simplecov .resultset.json file looks like this:
#
# ```
# $test_tool (e.g. Minitest, RSpec) # can disregard
#   "coverage" # constant string
#     $rb_filepath # root relative paths
#       [null, 1, 2, null, ...] # raw `Coverage.result` output
# ```
#
class SimplecovResultTranslatorTest < Minitest::Test
  SAMPLE_RESULTSET_JSON = "../sample_test_reports/simplecov/1/.resultset.json"

  def setup
    # binding.irb
    # Duplicate the resultset json and set the absolute file path
    #   for the current test env.
    orig_resultset_json_path = File
      .expand_path(SAMPLE_RESULTSET_JSON, File.dirname(__FILE__))
    @orig_resultset_json = File.read(orig_resultset_json_path)
    tmp_resultset_json = @orig_resultset_json.gsub(/\$PROJECT_PATH/o, Dir.pwd)
    @tmp_resultset_json_file = File.expand_path("tmp/test/simplecov-resultset.json")

    FileUtils.mkdir_p(File.dirname(@tmp_resultset_json_file))
    File.write(@tmp_resultset_json_file, tmp_resultset_json)
    # @orig_resultset = JSON.parse(orig_resultset_json)
  end

  def test_return_correct_method_hits
    @translated = OyenCov::SimplecovResultsetTranslator.translate(@tmp_resultset_json_file)
    assert_equal(1, @translated["OyenCov::Configuration#initialize"])
    assert_nil(@translated["OyenCov::APIConnection#get_data_submissijon_clearance"])
  end

  def test_handles_missing_rb_files
    orig_resultset_json_path = File
      .expand_path(
        "../sample_test_reports/simplecov/with_missing_file/.resultset.json",
        File.dirname(__FILE__))
    orig_resultset_json = File.read(orig_resultset_json_path)
    tmp_resultset_json = orig_resultset_json.gsub(/\$PROJECT_PATH/o, Dir.pwd)
    tmp_resultset_json_file = File.expand_path("tmp/test/simplecov-resultset.json")
    FileUtils.mkdir_p(File.dirname(@tmp_resultset_json_file))
    File.write(@tmp_resultset_json_file, tmp_resultset_json)

    # assert nothing raised
    translated = OyenCov::SimplecovResultsetTranslator.translate(tmp_resultset_json_file)
    assert_empty(translated)
  end
end
