module RequestActivity
  class ActivityMessage
    extend TorqueBox::Injectors if defined? TorqueBox::Injectors

    QUEUE_PATH = '/queues/activity_log'
    attr_reader :activity

    def initialize(model, user)
      @activity = self.class.activity_info(model)
      @user = user
    end

    def log_state(to_state, comments = nil)
      log_activity(message_with_comments(activity.state(to_state), comments)) if valid?
    end

    def log_modification(comments = nil)
      log_activity(modification_message(comments)) if valid?
    end

    def modification_message(comments = nil)
      message_with_comments(activity.modification_prefix, comments)
    end

    def attrs(message)
      created_at_time = Time.now
      activity.attrs.merge({
        user_id: user_id,
        activity: message,
        created_at: created_at_time,
        usec_created_at: created_at_time.usec
      })
    end

    def log_activity(message)
      ActivityMessage.publish(attrs(message)) if valid?
    end

    def valid?
      !activity.nil? && !activity.request.nil?
    end

    class << self
      def activity_info(model)
        case model
          when Request
            RequestActivityInfo.new(model)
          when Step
            StepActivityInfo.new(model)
          else
            nil
        end
      end

      def destination
        @destination ||= fetch(QUEUE_PATH) if defined? TorqueBox::Injectors
      end

      def publish(activity_attrs)
        begin
          ActivityMessage.destination.publish(activity_attrs) if ActivityMessage.destination
        rescue # => err
          # logger.error "Messaging System Error: #{err.message}"
        end
      end
    end

    private

    def user_id
      @user.kind_of?(User) ? @user.id : @user
    end

    def message_with_comments(message, comments)
      comments ? "#{message} -- #{comments}" : message
    end
  end

  class RequestActivityInfo
    attr_reader :request

    def initialize(instance)
      @request = instance
    end

    def attrs
      {request_id: @request.id}
    end

    def state(to_state)
      "#{to_state.to_s.humanize}"
    end

    def modification_prefix
      'Request modification'
    end
  end

  class StepActivityInfo
    MODIFICATION_PREFIX = 'Step modification'

    def initialize(instance)
      @step = instance
    end

    def request
      @step.parent ? @step.parent.request : @step.request
    end

    # step might not have a request if it's in the procedure template
    def request_id
      request.try(:id)
    end

    def attrs
      { request_id: request_id, step_id: @step.id }
    end

    def state(to_state)
      @step.to_label(to_state)
    end

    def modification_prefix
      "#{MODIFICATION_PREFIX} #{@step.number} : #{@step.name}"
    end
  end

  class AuditActivityMessage
    attr_reader :audit
    attr_reader :model

    def initialize(audit)
      @audit = audit
      @model = audit_model
    end

    def audit_model
      begin
        is_destroy_audit_action = audit.action == 'destroy'
        if audit.auditable_type == 'Request'
          is_destroy_audit_action ? nil : Request.find_by_id(audit.auditable_id)
        elsif audit.auditable_type == 'Step'
          if is_destroy_audit_action
            Request.find audit[:changes]['request_id']
          else
            Step.find(audit.auditable_id)
          end
        else
          if is_destroy_audit_action
            if audit[:changes]['request_id']
              Request.find audit[:changes]['request_id']
            elsif audit[:changes]['step_id']
              Step.find audit[:changes]['step_id']
            else
              if audit.auditable_type == 'Upload'
                (Kernel.const_get audit[:changes].delete('owner_type')).find audit[:changes].delete('owner_id')
              elsif audit.auditable_type == 'LinkedItem'
                (Kernel.const_get audit[:changes].delete('target_holder_type')).find audit[:changes].delete('target_holder_id')
              else
                nil
              end
            end
          else
            record_obj = (Kernel.const_get audit.auditable_type).find audit.auditable_id
            if record_obj.respond_to?(:request)
              record_obj.request
            elsif record_obj.respond_to?(:step)
              record_obj.step
            else
              if audit.auditable_type == 'Upload'
                (Kernel.const_get audit[:changes].delete('owner_type')).find audit[:changes].delete('owner_id')
              elsif audit.auditable_type == 'LinkedItem'
                (Kernel.const_get audit[:changes].delete('target_holder_type')).find audit[:changes].delete('target_holder_id')
              else
                nil
              end
            end
          end
        end
      rescue
      end
    end

    def activity_log_attrs
      if request_or_step?
        activity_message = ActivityMessage.new(model, audit.user_id)
        activity_message.attrs(activity_message.modification_message(comments))
      end
    end

    def comments
      "#{audit.auditable_type} #{audit.action} : #{audit.changes.to_s}"
    end

    def request_or_step?
      model.kind_of?(Step) || model.kind_of?(Request)
    end
  end
end