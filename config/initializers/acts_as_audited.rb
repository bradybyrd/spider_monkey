module ActsAsAudited
  module Auditor
    module InstanceMethods
      # Temporarily turns off auditing while saving.
      def save_without_auditing(*args, &block)
        without_auditing { save(*args, &block) }
      end

      private

      def write_audit(attrs)
        if auditing_enabled
          attrs[:associated] = self.send(audit_associated_with) unless audit_associated_with.nil?
          self.audit_comment = nil
          audit = Audit.new attrs
          audit.user = User.current_user
          audit.auditable = self

          message = audit.attributes.except(*ignored_audit_attributes)
          self.class.publish_message(message)
          LogActivity::ActivityMessage.publish(message)
        end
      end

      def ignored_audit_attributes
        ["id", :id]
      end
    end

    module SingletonMethods
      include TorqueBox::Injectors if defined? TorqueBox::Injectors

      def destination
        @destination ||= fetch('/queues/audit') if defined? TorqueBox::Injectors
      end

      def publish_message(msg)
        begin
          self.destination.publish(msg) if self.destination
        rescue => err
          logger.error "Messaging System Error: #{err.message}"
        end
      end
    end
  end
end
