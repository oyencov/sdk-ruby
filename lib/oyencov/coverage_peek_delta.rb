require "coverage"
require_relative "method_range_parser"
require_relative "logger"

# `CoveragePeekDelta` utility is meant to take...
#
# This class won't be governing the state, that will be handled by `OyenCov::Background`. However this will help strip the project path from the hash keys for cleaner reporting.
module OyenCov
  module CoveragePeekDelta
    PWD = Dir.pwd

    @@previous_method_hits = {}

    # We go a bit softer here. If there are other libraries starting
    #   coverage then don't throw exception.
    def self.start
      reset!

      unless Coverage.running?
        Coverage.start
      end
    end

    # 1. Filter only the keys with PWD.
    # 2. `transform_keys` and remove the PWD
    # 3. Use MRP to get the impt lines.
    #
    # @return [Hash] Method name => line num executions diff from last time
    def self.snapshot_delta
      current_peek = Coverage.peek_result

      # OyenCov::Logger.log "1st current_peek size = #{current_peek.size}, keys like: #{current_peek.keys[0, 3]}"

      # Filter into project
      filtered = current_peek.select do |k, _|
        /^#{PWD}/o.match?(k)
      end.transform_keys do |k|
        k.gsub(/#{PWD}\//o, "")
      end

      # OyenCov::Logger.log "2nd filtered size = #{filtered.size}, keys like: #{filtered.keys[0, 3]}"

      # Filter inside project to just the paths
      filtered = filtered.select do |k, _|
        /^(app|lib)/.match?(k)
      end

      # OyenCov::Logger.log "3rd filtered size = #{filtered.size}, keys like: #{filtered.keys[0, 3]}"

      # Find the method ranges, set
      current_method_hits = {}
      filtered.each_pair do |fpath, line_hits|
        MethodRangeParser[fpath]&.each_pair do |method_name, line_num|
          # puts [method_name, line_num, line_hits[line_num]]
          next if line_num.nil? || line_hits[line_num].nil?
          current_method_hits[method_name] = line_hits[line_num]
        end
      end

      # Compare and delta
      new_method_hits = {}
      current_method_hits.each_pair do |method_name, counter|
        new_hits = counter - (@@previous_method_hits[method_name] || 0)
        if new_hits > 0
          new_method_hits[method_name] = new_hits
        end
      end

      @@previous_method_hits = current_method_hits
      new_method_hits
    end

    def self.reset!
      @@previous_method_hits = {}
    end
  end
end
