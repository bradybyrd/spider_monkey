module EventsCalendarPresenter
  class EnvironmentsFilter
    attr_reader :environments

    def initialize(environments, filters)
      @environments = environments
      @filters = filters
    end

    def filter!
      @filters.each { |key, value| send :"filter_by_#{key}", value if respond_to? :"filter_by_#{key}", true }
    end

  private

    def filter_by_app_id(ids)
      @environments = @environments.where 'plan_env_app_dates.app_id' => ids
    end

    def filter_by_environment_id(ids)
      @environments = @environments.where id: ids
    end

    def filter_by_plan_id(ids)
      @environments = @environments.where 'plan_env_app_dates.plan_id' => ids
    end
  end
end
