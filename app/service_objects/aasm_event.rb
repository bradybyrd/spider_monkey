module AasmEvent
  class ExecuteEvent
    attr_reader :object, :obj_class

    def initialize(object)
      @object  = object
      @obj_class = @object.class
    end

    def validate_aasm_event
      # turn it into a symbol
      event_symbol = object.aasm_event.to_sym
      # get the official event
      event = obj_class.aasm.events.detect{|event| event.name == event_symbol}
      # check if it is one of our supported events and the event object is exists
      supported_events = get_supported_events
      if supported_events.include?(event_symbol) && event
        check_transition(event)
      else
        object.errors.add(:aasm_event, "was not included in supported events: #{supported_events.to_sentence}.")
      end
    end

    def run_aasm_event
      begin
        # cache the command before getting rid of it
        command = get_obj_command
        # Add any event category note to request if present
        add_notes if obj_class == Request
        # clear the event attribute so you don't validate and run the command again after the state has been changed
        object.aasm_event = nil
        # now send the command after validation and clearing; this will be a second save of the model which is why we don't want
        # the event value to be in the instance any more -- otherwise another update loop will run.
        object.send(command)
      rescue => e
        object.errors.add(:aasm_event, "generated an unexpected error: #{e.message}.")
      end
    end

    def get_supported_events
      obj_class.aasm.events.map(&:name).reject { |event_name| rejected_events.include?(event_name) }
    end

    def rejected_events
      [:created]
    end

    def check_transition(event)
      # add an error if the event can't be retrieved from the class or the transition is invalid for the current state
      return if event.transitions_from_state?(object.aasm_state.to_sym)
      object.errors.add(:aasm_event, "was not a valid transition for current state: #{object.aasm_state}.")
    end

    def get_obj_command
      "#{object.aasm_event}!"
    end

    def add_notes
      return if object.aasm_event_note.blank?
      object.add_log_comments object.aasm_event.to_sym, object.aasm_event_note
    end
  end

  class PlanExecuteEvent < ExecuteEvent
    def rejected_events
      [:created, :delete]
    end
  end

  class StepExecuteEvent < ExecuteEvent
    def get_obj_command
      commands = { start: 'lets_start!',
                   done: 'all_done!' }
      commands[object.aasm_event.to_sym] ? commands[object.aasm_event.to_sym] : "#{object.aasm_event}!"
    end
  end
end