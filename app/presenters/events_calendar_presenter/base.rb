module EventsCalendarPresenter
  class Base
    delegate :size, to: :environments, prefix: true

    def initialize(environments, scale_unit, start_date, finish_date, filters)
      @start_date = start_date
      @finish_date = finish_date
      @origin_environments = environments
      @scale_unit = scale_unit
      @filters = filters
    end

    def each_environment(&block)
      environments.each { |environment| yield environment }
    end

    def each_category(&block)
      categories.each { |category| yield category }
    end

    def trendline_attributes
      if @start_date.to_date < Date.today && Date.today < @finish_date.to_date
        { :start => Date.today.strftime('%Y-%m-%d'),
          :color => 'FF0000',
          :displayValue => 'Today',
          :thickness => '2',
          :dashed => '1' }
      end
    end

  private

    def environments
      @environments ||= EnvironmentsCollection.new @origin_environments, @start_date, @finish_date, @scale_unit, @filters
    end

    def categories
      @categories ||= CategoriesCollection.new @scale_unit, @start_date, @finish_date
    end
  end
end
