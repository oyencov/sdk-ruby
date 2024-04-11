require "faraday"
require "singleton"
require_relative "version"
require_relative "logger"

module OyenCov
  class APIConnection < Faraday::Connection
    include Singleton

    def initialize
      super({
        url: ENV["OYENCOV_API_URL"] || "https://telemetry-api.oyencov.com",
        headers: {
          "Authorization" => "Bearer #{ENV["OYENCOV_API_KEY"]}",
          "Content-Type" => "application/json",
          "User-Agent" => "oyencov-ruby #{OyenCov::VERSION}"
        }
      }) do |f|
        f.request :json
        f.response :json
      end
    end

    # Used in `background.rb` to determine whether to start background
    def get_data_submission_clearance
      attempts = 3
      begin
        response = get("/v1/data_submission_clearance")

        if Hash === response.body && response.body["status"] == "ok"
          response.body
        else
          false
        end
      rescue Faraday::Error => e
        OyenCov::Logger.log(e, 2)

        if attempts > 0
          attempts -= 1
          sleep(5)
          retry
        end
        nil
      end
    end

    def post_runtime_report(body)
      post("/v1/runtime_reports", body)
    rescue Faraday::Error
      false
    end

    def post_test_report(body)
      post("/v1/test_reports", body)
    end
  end
end
