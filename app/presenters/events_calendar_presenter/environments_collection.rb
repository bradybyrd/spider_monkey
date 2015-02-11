module EventsCalendarPresenter
  class EnvironmentsCollection < Collection
    attr_reader :decorated_environments
    private :decorated_environments
    delegate :size, to: :decorated_environments

    def initialize(environments, start_date, finish_date, scale_unit, filters)
      environments = environments.includes(plan_env_app_dates: :plan)
                                 .select('count(plan_env_app_dates.id) as plan_env_app_dates_count')
                                 .select(columns)
                                 .joins('LEFT OUTER JOIN plan_env_app_dates ON plan_env_app_dates.environment_id = environments.id')
                                 .group(columns)
                                 .order('plan_env_app_dates_count desc, environments.name')
      environments = filter environments, filters
      @start_date = start_date
      @finish_date = finish_date
      @scale_unit = scale_unit
      @decorated_environments = EventsCalendarPresenter::EnvironmentsCollectionDecorator.new environments,
                                                                                             @start_date,
                                                                                             @finish_date
      super
      set_total_deployment_windows_on_each_row
    end

  private

    def build_collection
      @decorated_environments.map do |decorated_environment, series_row, index = nil|
        EventsCalendarPresenter::EnvironmentPresenter.new decorated_environment,
                                                          series_row,
                                                          index,
                                                          @start_date,
                                                          @finish_date
      end
    end

    def columns
      involved_columns.map { |e| "environments.#{e}" }
    end

    def involved_columns
      @involved_columns ||= begin
        columns = Environment.column_names
        reserved_words.any? ? columns.reject { |column| reserved_words.include? column } : columns
      end
    end

    def reserved_words
      @reserved_words ||= defined?(DATABASE_RESERVED_WORDS) ? DATABASE_RESERVED_WORDS.map(&:downcase) : []
    end

    def set_total_deployment_windows_on_each_row
      view_switch = ViewSwitcher.new @decorated_environments.events_count, @scale_unit
      @collection.each { |environment_presenter| environment_presenter.view_switch = view_switch }
    end

    def filter(environments, filters)
      filter = EnvironmentsFilter.new environments, filters
      filter.filter!
      filter.environments
    end
  end
end
