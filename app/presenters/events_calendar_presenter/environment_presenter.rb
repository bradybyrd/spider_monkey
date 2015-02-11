module EventsCalendarPresenter
  class EnvironmentPresenter < SimpleDelegator
    attr_writer :view_switch

    def initialize(environment_decorator, series, index, start_date, finish_date)
      @diagram_start = start_date
      @diagram_finish = finish_date
      @series = series
      @index = index
      super environment_decorator
    end

    def id
      "#{__getobj__.id}-#{@index}"
    end

    def deployment_windows
      EventsCalendarPresenter::DeploymentWindowsCollection.new __getobj__,
                                                               @series,
                                                               @index,
                                                               @diagram_start,
                                                               @diagram_finish,
                                                               @view_switch
    end

    def release_plan_diagram_label
      plans.any? && plans.map(&:name).join(', ') || '-'
    end

  private

    def plans
      plan_env_app_dates.map(&:plan).compact # exclude nils for deleted plans
    end
  end
end
