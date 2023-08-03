# This module is merely the container data structure.
#
# The ACTUAL code that tracks controller is in `railtie.rb`
module OyenCov
  module ControllerTracking
    @hits = {}

    def self.bump(controller_action_name)
      if @hits[controller_action_name]
        @hits[controller_action_name] += 1
      else
        @hits[controller_action_name] = 1
      end
    end

    def self.snapshot_and_reset!
      current_hits = @hits
      @hits = {}
      current_hits
    end
  end
end
