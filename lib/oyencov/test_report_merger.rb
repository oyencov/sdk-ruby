require "json"

# Currently Oyencov only tracks
#
# Simplecov report collation is not handled here.
module OyenCov
  module TestReportMerger
    def self.create_or_append!(hash_to_merge)
      resultset_path = OyenCov.config.test_resultset_path

      # Load
      hash_content = if File.exist?(resultset_path)
        JSON.parse(File.read(resultset_path))
      else
        {}
      end

      hash_content.merge!(hash_to_merge)

      # Persist
      File.write(resultset_path, JSON.generate(hash_content))
    end

    # @param [String]
    # @param [String]
    # @return [Hash]
    def self.collate_job_reports(filepath_glob, save_to = nil)
      # Read and parse their JSONs
      job_reports_files = Dir.glob(filepath_glob)
      # binding.irb
      return if job_reports_files.count == 0

      job_reports = job_reports_files.map do |f|
        JSON.parse(File.read(f))
      end

      # Add them up
      collated_report = job_reports.reduce({
        "controller_action_hits" => {},
        "method_hits" => {}
      }) do |i, j|
        ij = {}
        i.keys.each do |metric|
          unless j[metric]
            ij[metric] = i[metric]
            next
          end

          case metric
          when "controller_action_hits", "method_hits"
            ij[metric] = add_hashes(i[metric], j[metric])
          end
        end

        ij
      end

      # Persist to filesystem as JSON
      if !!save_to
      end

      collated_report
    end

    private_class_method def self.add_hashes(i, j)
      (i.keys | j.keys).map do |key|
        [key, (i[key] || 0) + (j[key] || 0)]
      end.to_h
    end
  end
end
