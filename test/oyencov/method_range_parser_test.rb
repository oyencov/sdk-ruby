require "minitest/autorun"
require_relative "../../lib/oyencov/method_range_parser"

class MethodRangeParserTest < Minitest::Test
  SAMPLE_PATH = "test/sample_ruby_codes/for_method_range_parser.rb"

  def setup
    @parser = OyenCov::MethodRangeParser[SAMPLE_PATH]
  end

  def test_return_expected_hash
    assert_equal(@parser.to_h, {
      "EverythingAllAtOnce.class_method" => 13,
      "EverythingAllAtOnce#whatever" => 22,
      "EverythingAllAtOnce#rails_controller_lineless" => nil
    })
  end
end
