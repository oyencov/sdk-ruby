require_relative "./method_range_parser"
require_relative "./test_report_merger"

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
module OyenCov
  module SimplecovResultsetTranslator
    PWD = Dir.pwd

    # @param [String] Root-relative path to the .resultset.json
    # @return [String] JSON file
    def self.translate(resultset_json_path, persist: false)
      # Open up the JSON
      resultset = JSON.parse(File.read(resultset_json_path))

      # binding.irb

      # Loop through all the files
      # Set {"method" => runs, ...}
      all_methods_hits = resultset[resultset.keys[0]]["coverage"].each_pair.map do |file_path, file_attr|
        # file_path = file_path.gsub(/#{PWD}\//o, "")
        line_hits = file_attr["lines"]
        methods_hits = MethodRangeParser[file_path]&.each_pair&.map do |method_name, line_num|
          next if line_num.nil? || line_hits[line_num].nil?
          [method_name, line_hits[line_num]]
        end&.compact.to_h
        # methods_hits
      end.reduce(:merge)

      # Persist to existing oyencov report?
      if persist
        OyenCov::TestReportMerger.create_or_append!(method_hits: all_methods_hits)
      end

      all_methods_hits
    end
  end
end
