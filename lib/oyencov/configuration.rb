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
          version_clue_path = if defined?(Rails.root) && Rails.root
            Rails.root.join(version_clue)
          elsif defined?(Bundler.root) && Bundler.root
            Bundler.root.join(version_clue)
          elsif defined?(Pathname.pwd) && Pathname.pwd
            Pathname.pwd.join(version_clue)
          else
            next
          end

          if File.exist?(version_clue_path)
            return File.read(version_clue_path).strip
          end
        end
      end

      # Last resort, prevent null value.
      if release == "" || release.nil?
        release = "-"
      end

      release
    end

    # We need to know if this is rails, sidekiq, rake task etc
    #
    # Method 1: $PROGRAM_NAME.split("/")[-1]
    def suggest_process_type
      sliced_program_name = File.basename($PROGRAM_NAME)

      if %w[sidekiq resque].include?(sliced_program_name)
        return sliced_program_name
      end

      if /(rake|rails)$/.match?(sliced_program_name)
        if defined?(Rake::Task) && Rake::Task.tasks.any?
          return "rake"
        end
      end

      # If its cluster mode & we are in worker process, puma is at the beginning.
      # If it's `bundle exec puma` then it comes in the end
      #
      # If it's booted up by puma not rails server, `Rails` module wont be defined.
      # We will just assume puma = rails-server
      if /^puma/.match?($0) || sliced_program_name == "puma"
        return "rails-server"
      end

      # Rails can be server or rake task
      if /rails$/.match?(sliced_program_name)
        if defined?(Rails)
          if Rails.const_defined?(:Server)
            return "rails-server"
          elsif Rails.const_defined?(:Console)
            return "rails-console"
          end
        else
          "-"
        end
      end

      "-"
    end
  end
end
