module AuditHandler
  class AuditMessagesSaver < AuditHandler::MessagesSaver
  private

    def self.save(messages = [])
      Audit.import(messages.map { |message| Audit.new(message) })
    end
  end
end
