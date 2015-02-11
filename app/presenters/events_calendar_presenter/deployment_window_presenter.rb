module EventsCalendarPresenter
  class DeploymentWindowPresenter < SimpleDelegator
    GREEN = '00ff00'
    RED = 'ff0000'
    GREY = 'aaaaaa'
    YELLOW = 'ffff00'
    SERIES_BORDER_COLOR = ''
    SERIES_BORDER_THICKNESS = '2'
    RANGE_DATE_FORMAT = '%d/%m/%Y %l:%M %p'

    attr_reader :plan_diagram_id

    def initialize(event, environment_id, diagram_start_at, diagram_finish_at, all_series = nil)
      @plan_diagram_id = environment_id
      @diagram_start_at = diagram_start_at.to_date
      @diagram_finish_at = diagram_finish_at.to_date
      super EventsCalendarPresenter::DeploymentWindowDecorator.new event, all_series, environment_id, @diagram_start_at, @diagram_finish_at
    end

    def start_at
      __getobj__.start_at < @diagram_start_at ? @diagram_start_at : __getobj__.start_at
    end

    def finish_at
      __getobj__.finish_at > @diagram_finish_at ? @diagram_finish_at : __getobj__.finish_at
    end

    def color
      old? ? GREY : upcoming_event_color
    end

    def tool_text
      <<-EOS
#{name}
Type: #{behavior}
Environments: #{environment_names}
#{duration_or_range_placeholder}#{state_placeholder}#{reason_placeholder}
      EOS
    end

    def series?
      __getobj__.series? ? 1 : 0
    end

    def border_thickness
      __getobj__.series? ? SERIES_BORDER_THICKNESS : ''
    end

    def border_color
      __getobj__.series? ? SERIES_BORDER_COLOR : ''
    end

    def permitted_actions(user)
      __getobj__.permitted_actions(user).to_json
    end

  private

    def duration_or_range_placeholder
      __getobj__.series? ? range_placeholder : duration_placeholder
    end

    def duration_placeholder
      "Duration: #{duration}"
    end

    def range_placeholder
      "Range: #{range}"
    end

    def range
      "#{original_series.start_at.strftime(RANGE_DATE_FORMAT)} - #{original_series.finish_at.strftime(RANGE_DATE_FORMAT)}"
    end

    def state_placeholder
      "\nState: #{state}" unless __getobj__.series?
    end

    def reason_placeholder
      "\nReason of move/suspend/resume: #{reason}" if reason.present?
    end

    def duration
      partial_durations.join ' '
    end

    def upcoming_event_color
      suspended? ? YELLOW : persisted_event_color
    end

    def persisted_event_color
      allow? ? GREEN : RED
    end
  end
end
