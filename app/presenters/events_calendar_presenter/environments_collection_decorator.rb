module EventsCalendarPresenter
  class EnvironmentsCollectionDecorator < SimpleDelegator
    def initialize(environments, start_date, finish_date)
      @start_date = start_date
      @finish_date = finish_date
      super environments.map { |e| EventsCalendarPresenter::EnvironmentDecorator.new e, @start_date, @finish_date }
    end

    def map(&block)
      __getobj__.map { |environment_decorator| map_series environment_decorator, &block }.flatten
    end

    def events_count
      __getobj__.reduce(0) { |sum, environment_decorator| sum += environment_decorator.events_count }
    end

    def size
      return @counter if @counter.present?
      @counter = 0
      map { @counter += 1 }
      @counter
    end

  private

    def map_series(environment_decorator, &block)
      if environment_decorator.has_intersected_events?
        i = -1
        environment_decorator.distributed_series.map { |series_row| yield environment_decorator, series_row, i += 1 }
      else
        yield environment_decorator, environment_decorator.series
      end
    end
  end
end
