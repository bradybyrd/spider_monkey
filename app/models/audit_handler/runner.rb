module AuditHandler
  class Runner
    MAX_MESSAGES_AMOUNT_TO_SAVE = 1000

    def self.run
      messages = messages_amount.times.map { queue.receive }
      self::MessagesSaver.save messages
    end

  private

    def self.queue
      @queue ||= TorqueBox::Messaging::Queue.new self::QUEUE_NAME
    end

    def self.messages_amount
      [MAX_MESSAGES_AMOUNT_TO_SAVE, queue.count_messages].compact.min
    end
  end
end
