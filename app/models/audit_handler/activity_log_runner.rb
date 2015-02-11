module AuditHandler
  class ActivityLogRunner < AuditHandler::Runner
    QUEUE_NAME = '/queues/activity_log'
    MessagesSaver = AuditHandler::ActivityLogMessagesSaver
  end
end
