module EventsCalendarPresenter
  class CategoriesCollection < Collection
    DEFAULT_SCALE_UNIT = 'm'
    SECONDS_PER_WEEK = 60 * 60 * 24 * 7

    def initialize(scale_unit, start_date, finish_date)
      @start_date = start_date
      @finish_date = finish_date
      @scale_unit = scale_unit.presence || DEFAULT_SCALE_UNIT
      super
    end

  private

    def build_collection
      result = []

      if @scale_unit == "m"
        while @finish_date > @start_date do
          result << { :start => @start_date.to_date,
                      :end => @start_date.end_of_month.to_date,
                      :label=> @start_date.strftime("%b '%y") }
          @start_date = @start_date.next_month
        end
      elsif @scale_unit == "d"
        while @finish_date > @start_date do
          result << { :start => @start_date.beginning_of_day.to_date,
                      :end => @start_date.end_of_day.to_date,
                      :label=> @start_date.strftime("%d %b '%y") }
          @start_date = @start_date.tomorrow
        end
      elsif @scale_unit == "w"
        while @finish_date > @start_date do
          week_start = @start_date.beginning_of_day.to_date
          week_end = @start_date.beginning_of_day.since(SECONDS_PER_WEEK).to_date
          result << { :start => week_start,
                      :end => week_end,
                      :label=> week_start.strftime("%d %b")+ "-" + (week_end - 1).strftime("%d %b '%y") }
          @start_date = @start_date.since(SECONDS_PER_WEEK)
        end
      end

      result
    end
  end
end
