module OyenCov
  module Logger
    # ANSI escape code for orange text
    ORANGE_TEXT = "\e[38;5;214m"
    RESET_COLOR = "\e[0m"

    # Level 0 = stdout for common users
    # Level 1 = debug stdout
    # Level 2 = debug stderr
    def self.log(msg, level = 1)
      return unless ENV["OYENCOV_DEBUG"] || level == 0
      if Exception === msg
        msg = msg.inspect
      end
      formatted_msg = msg.split("\n").map { |m| "#{ORANGE_TEXT}[OyenCov] PID##{$$} #{m}#{RESET_COLOR}" }.join("\n")

      if level == 2
        warn formatted_msg
      else
        puts formatted_msg
      end
    end
  end
end
