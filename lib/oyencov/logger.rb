module OyenCov
  module Logger
    # ANSI escape code for orange text
    ORANGE_TEXT = "\e[38;5;214m"
    RESET_COLOR = "\e[0m"

    def self.log(msg, level = 1)
      return unless ENV["OYENCOV_DEBUG"]
      formatted_msg = msg.split("\n").map { |m| "#{ORANGE_TEXT}[OyenCov] #{m}#{RESET_COLOR}" }.join("\n")

      if level == 2
        warn formatted_msg
      else
        puts formatted_msg
      end
    end
  end
end
