################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class AutomationQueueData < ActiveRecord::Base
  attr_accessible :attempts, :run_at, :step_id, :failed_at, :last_error
  
  class << self
    include AutomationBackgroundable::ClassMethods

    def clear_queue!
      AutomationQueueData.delete_all
      AutomationQueueData.remove_messages
    end

    def track_queue_data(step_id)
      queue = AutomationQueueData.find_or_create_by_step_id step_id
      queue.update_attributes run_at: Time.zone.now
    end

    def clear_queue_data(step_id)
      AutomationQueueData.destroy_all step_id: step_id
    end

    def error_queue_data(step_id, error)
      logger.error "AutomationQueueData: Error in step_id: #{step_id}: #{error}"
      queue = AutomationQueueData.find_by_step_id(step_id)
      queue.update_attributes failed_at: Time.zone.now, last_error: error, attempts: (queue.attempts + 1) if queue
    end
  end
end
