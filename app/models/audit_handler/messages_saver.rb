module AuditHandler
  class MessagesSaver
    def self.save(messages = [])
      raise NotImplementedError, "#{self} must implement the method `save`."
    end
  end
end
