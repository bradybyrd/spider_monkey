module EventsCalendarPresenter
  class DeploymentWindowsIntersection
    include EventsCalendarPresenter::EventsLimiter

    def initialize(first_series, second_series, diagram_start, diagram_finish)
      @diagram_start = diagram_start
      @diagram_finish = diagram_finish
      @first_series = first_series
      @second_series = second_series
    end

    def intersect?
      have_intersected_series?(@first_series, @second_series) &&
      have_intersected_occurrences?(@first_series, @second_series) &&
      have_intersected_events?(@first_series, @second_series)
    end

  private

    def have_intersected_occurrences?(first_series, second_series)
      first_series.occurrences.where(start_finish_arel_conditions(DeploymentWindow::Occurrence.arel_table)).each do |o1|
        second_series.occurrences.where(start_finish_arel_conditions(DeploymentWindow::Occurrence.arel_table)).each do |o2|
          return true if simple_intersect? o1, o2
        end
      end
      false
    end

    def have_intersected_events?(first_series, second_series)
      intersected_occurrences(first_series, second_series).each do |(o1, o2)|
        o1.events.where(start_finish_arel_conditions).each do |e1|
          o2.events.where(start_finish_arel_conditions).each do |e2|
            return true if simple_intersect? e1, e2
          end
        end
      end
      false
    end

    def intersected_occurrences(first_series, second_series)
      result = []
      # NOTE: do not add .include(:series) for occurrences here. It slows down the diagram page.
      first_series.occurrences.where(start_finish_arel_conditions(DeploymentWindow::Occurrence.arel_table)).each do |o1|
        second_series.occurrences.where(start_finish_arel_conditions(DeploymentWindow::Occurrence.arel_table)).each do |o2|
          result.push [o1, o2] if simple_intersect? o1, o2
        end
      end
      result
    end

    def simple_intersect?(first, second)
      first.start_at <= second.start_at && first.finish_at >= second.start_at ||
      first.start_at >= second.start_at && first.finish_at <= second.finish_at ||
      first.start_at <= second.finish_at && first.finish_at >= second.finish_at
    end

    alias_method :have_intersected_series?, :simple_intersect?

    def arel_table
      DeploymentWindow::Event.arel_table
    end
  end
end
