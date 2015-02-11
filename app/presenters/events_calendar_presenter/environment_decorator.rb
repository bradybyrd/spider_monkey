module EventsCalendarPresenter
  class EnvironmentDecorator < SimpleDelegator
    include EventsCalendarPresenter::EventsLimiter

    def initialize(environment, diagram_start, diagram_finish)
      @diagram_start = diagram_start
      @diagram_finish = diagram_finish
      super environment
    end

    def distributed_series
      @series ||= distributed_series_without_memoization
    end

    def series
      deployment_window_events_with_sql_limitation.includes(:series).map { |e| e.series }.uniq
    end

    def has_intersected_events?
      distributed_series.size > 1
    end

    def events_count
      deployment_window_events_with_sql_limitation.count
    end

  private

    def deployment_window_events_with_sql_limitation
      @deployment_window_events_with_sql_limitation ||= deployment_window_events.not_archived.series_visible.where(start_finish_arel_conditions)
    end

    def distributed_series_without_memoization
      start = Time.now
      distributor = EventsCalendarPresenter::DeploymentWindowsDistributor.new series, @diagram_start, @diagram_finish
      distributor.distribute_series!
      distributor.series
    end
  end
end
