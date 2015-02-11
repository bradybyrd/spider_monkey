module EventsCalendarPresenter
  class DeploymentWindowDecorator < SimpleDelegator
    include EventsCalendarPresenter::EventsLimiter

    SECONDS_IN_DAY = 86400
    SECONDS_IN_HOUR = 3600
    SECONDS_IN_MINUTE = 60

    alias_method :original_series, :__getobj__

    def initialize(deployment_window, all_series=nil, environment_id=nil, diagram_start=nil, diagram_finish=nil)
      @environment_id = environment_id
      @all_series = all_series
      @diagram_start = diagram_start
      @diagram_finish = diagram_finish
      super deployment_window
    end

    def allow?
      DeploymentWindow::Series::ALLOW == behavior
    end

    def old?
      finish_at < Time.now
    end

    def partial_durations
      detailed_duration.map { |span_name, time_span|
        "#{time_span} #{span_name.to_s.pluralize(time_span)}"
      }
    end

    def state
      try(:state).presence || DeploymentWindow::Event::CREATED
    end

    def suspended?
      try(:suspended?) || false
    end

    def reason
      try(:reason) || ''
    end

    def series?
      __getobj__.is_a? DeploymentWindow::Series
    end

    def requests_count
      series? && @all_series.present? ? all_series_requests_count : super
    end

    def permitted_actions(user)
      if in_past?
        []
      else
        [ edit_action(user), schedule_action(user) ].compact
      end
    end

  private

    def series
      __getobj__.respond_to?(:series) ? __getobj__.series : self
    end

    def edit_action(user)
      :edit if user.can?(:edit, series)
    end

    def schedule_action(user)
      :schedule if allow? && user.can?(:create, Request.new)
    end

    def all_series_requests_count
      @all_series.reduce(0) { |sum, series| sum += single_series_requests_count(series) }
    end

    def single_series_requests_count(series)
      series.events.where(environment_id: @environment_id)
                   .where(start_finish_arel_conditions)
                   .reduce(0) { |sum, events| sum += events.requests_count.to_i }
    end

    def try(attribute_name)
      __getobj__.respond_to?(attribute_name) && __getobj__.send(attribute_name)
    end

    def detailed_duration
      duration_days_hours_minutes.select { |_, v| v != 0 }
    end

    def duration_days_hours_minutes
      {
        day: days_duration,
        hour: hours_duration,
        minute: minutes_duration
      }
    end

    def days_duration
      (duration / SECONDS_IN_DAY).floor
    end

    def hours_duration
      ((duration - days_duration * SECONDS_IN_DAY) / SECONDS_IN_HOUR).floor
    end

    def minutes_duration
      ((duration - days_duration * SECONDS_IN_DAY - hours_duration * SECONDS_IN_HOUR) / SECONDS_IN_MINUTE).floor
    end
  end
end
