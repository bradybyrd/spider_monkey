module AuditHandler
  class AuditRunner < AuditHandler::Runner
    QUEUE_NAME = '/queues/audit'
    MessagesSaver = AuditHandler::AuditMessagesSaver
  end
end
