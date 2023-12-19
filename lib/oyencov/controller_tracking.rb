require_relative "logger"

# This module is merely the container data structure.
#
# The ACTUAL code that tracks controller is in `railtie.rb`
module OyenCov
  module ControllerTracking
    @@hits = {}

    def self.hits
      @@hits
    end

    def self.bump(controller_action_name)
      if @@hits[controller_action_name]
        @@hits[controller_action_name] += 1
      else
        @@hits[controller_action_name] = 1
      end

      OyenCov::Logger.log "ControllerTracking.bump self.object_id = #{object_id}"
      OyenCov::Logger.log "ControllerTracking.bump @@hits[#{controller_action_name}] = #{@@hits[controller_action_name]}"
    end

    def self.snapshot_and_reset!
      OyenCov::Logger.log "ControllerTracking.snapshot_and_reset! self.object_id = #{object_id}"
      OyenCov::Logger.log "ControllerTracking.snapshot_and_reset! @@hits = #{@@hits}"

      current_hits = @@hits.dup
      @@hits = {}
      current_hits
    end
  end
end
