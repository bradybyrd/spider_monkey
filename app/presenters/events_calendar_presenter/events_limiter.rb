module EventsCalendarPresenter
  module EventsLimiter
    DEFAULT_AREL_TABLE = DeploymentWindow::Event.arel_table

    def start_finish_conditions
      ->(event) {
        @diagram_start < event.start_at && event.start_at < @diagram_finish ||
        @diagram_start < event.finish_at && event.finish_at < @diagram_finish ||
        event.start_at <= @diagram_start && @diagram_finish <= event.finish_at
      }
    end

    def start_finish_arel_conditions(arel_table = DEFAULT_AREL_TABLE)
      arel_table[:start_at].in(@diagram_start..@diagram_finish)
      .or(  arel_table[:finish_at].in(@diagram_start..@diagram_finish)  )
      .or(  arel_table[:start_at].lteq(@diagram_start)
            .and(arel_table[:finish_at].gteq(@diagram_finish))  )
    end
  end
end
