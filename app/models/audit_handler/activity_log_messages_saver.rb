module AuditHandler
  class ActivityLogMessagesSaver < AuditHandler::MessagesSaver
  private

    def self.save(messages = [])
      logs = []
      messages.each do |message|
        if self.audit? message
          audit = Audit.new(message)
          attrs = RequestActivity::AuditActivityMessage.new(audit).activity_log_attrs
          logs << ActivityLog.new(attrs) unless attrs.nil?
        else
          logs << ActivityLog.new(message)
        end
      end
      ActivityLog.import(logs) if logs.any?
    end

    def self.audit?(message)
      message.has_key? 'auditable_id'
    end
  end
end
