module EventsCalendarPresenter
  class ViewSwitcher
    MAX_ALLOWED_EVENTS = 1000
    MONTHS_SCALE = 'm'
    WEEKS_SCALE = 'w'

    def initialize(total_events, scale_unit)
      @total_events = total_events
      @scale_unit = scale_unit
    end

    def display_series?(diagram_start, diagram_finish, environment_id)
      @total_events > MAX_ALLOWED_EVENTS && (@scale_unit == MONTHS_SCALE || @scale_unit == WEEKS_SCALE)
    end
  end
end
