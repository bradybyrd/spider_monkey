module EventsCalendarPresenter
  class DeploymentWindowsCollection < Collection
    include EventsCalendarPresenter::EventsLimiter

    def initialize(environment, series, row_index, diagram_start, diagram_finish, view_switch = nil)
      @environment = environment
      @series = series
      @row_index = row_index
      @diagram_start = diagram_start.to_datetime.change offset: '+0000'
      @diagram_finish = diagram_finish.to_datetime.change offset: '+0000'
      @view_switch = view_switch
      super
    end

  private

    def build_collection
      if @view_switch.display_series? @diagram_start, @diagram_finish, @environment.id
        series
      else
        events
      end
    end

    def series
      @series.map do |series|
        EventsCalendarPresenter::DeploymentWindowPresenter.new(series,
                                                               @environment.id,
                                                               @diagram_start,
                                                               @diagram_finish,
                                                               @series)
      end
    end

    def events
      deployment_windows.map do |event|
        EventsCalendarPresenter::DeploymentWindowPresenter.new event,
                                                               @environment.id,
                                                               @diagram_start,
                                                               @diagram_finish
      end
    end

    def deployment_windows
      @environment.deployment_window_events.where(start_finish_arel_conditions)
                                           .where(occurrence_id: occurrence_ids)
    end

    def occurrence_ids
      @series.map(&:occurrence_ids).flatten.uniq
    end
  end
end
