# We encourage configuring OyenCov through environment variables.
#
# But some can be set through config/ if they are meant to be uniform across environments.
module OyenCov
  class Configuration
    ENV_PARAMETERS = %w[
      API_KEY
      API_URL
      MODE
      RELEASE
      TEST_REPORTING_DIR
      TEST_RESULTSET_PATH
      PROGRAM_NAME
    ]

    attr_reader :api_key, :api_url, :mode, :including_file_paths, :excluding_file_paths, :release, :test_reporting_dir, :test_resultset_path, :program_name, :process_type

    def initialize
      reset_to_defaults
      ENV_PARAMETERS.each do |key|
        if (envvar_value = ENV["OYENCOV_#{key}"])
          instance_variable_set(
            :"@#{key.downcase}", envvar_value
          )
        end
      end
    end

    def reset_to_defaults
      @api_key = nil
      @api_url = "https://telemetry-api.oyencov.com"
      @mode = ENV["OYENCOV_ENV"] || ENV["RAILS_ENV"]
      @including_file_paths = %w[app lib]
      @excluding_file_paths = []
      @release = suggest_release
      @process_type = suggest_process_type
      @test_reporting_dir = "coverage/"
      @test_resultset_path = "coverage/oyencov-resultset.json"
    end

    private

    # Lots of ideas came from sentry-ruby, thanks to nate berkopec.
    def suggest_release
      release = `git rev-parse HEAD ||:`.strip

      if release == "" || release.nil?
        [".source_version", "REVISION"].each do |version_clue|
          if File.exist?(Rails.root.join(version_clue))
            release = File.read(Rails.root.join(version_clue)).strip
            return release
          end
        end
      end

      release
    end

    # We need to know if this is rails, sidekiq, rake task etc
    #
    # Method 1: $PROGRAM_NAME.split("/")[-1]
    def suggest_process_type
      answer = nil
      sliced_program_name = File.basename($PROGRAM_NAME)

      if %w[sidekiq resque].include?(sliced_program_name)
        return sliced_program_name
      end

      # Rails can be server or rake task
      if sliced_program_name == "rails"
        if defined?(Rails) && Rails.respond_to?(:server) && !!Rails.server
          return "rails server"
        else
          return "rake"
        end
      end

      "-"
    end
  end
end
