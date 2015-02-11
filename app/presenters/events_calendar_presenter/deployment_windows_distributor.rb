module EventsCalendarPresenter
  class DeploymentWindowsDistributor
    attr_reader :series

    def initialize(series, diagram_start, diagram_finish)
      @diagram_start = diagram_start
      @diagram_finish = diagram_finish
      @series = [series]
    end

    def distribute_series!
      i = -1
      while (i += 1) < @series.size
        distribute_series_on_level i
      end
      @series.map { |row| row.compact! }
    end

  private

    def distribute_series_on_level(level)
      each_to_each_other_pairs(level) do |left_series_index, right_series_index|
        if intersects? level, left_series_index, right_series_index
          move_to_next_level level, right_series_index
        end
      end
    end

    def each_to_each_other_pairs(level, &block)
      0.upto(last(level) - 1).each do |pointer|
        pointer.upto(last(level)) do |i|
          yield pointer, i
        end
      end
    end

    def last(level)
      @series[level].size - 1
    end

    def intersects?(level, left_series_index, right_series_index)
      left_series = @series[level][left_series_index]
      right_series = @series[level][right_series_index]
      left_series.present? && right_series.present? &&
      EventsCalendarPresenter::DeploymentWindowsIntersection.new(left_series, right_series, @diagram_start, @diagram_finish).intersect?
    end

    def move_to_next_level(level, index)
      series = @series[level][index]
      @series[level][index] = nil
      push level + 1, series
    end

    def push(level, series)
      if @series[level].present?
        @series[level].push series
      else
        @series.push [series]
      end
    end
  end
end
