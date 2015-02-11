module AuditHandler
  class MessagesProcessor
    def run
      TorqueBox.transaction do
        AuditHandler::AuditRunner.run
        AuditHandler::ActivityLogRunner.run
      end
    end
  end
end
