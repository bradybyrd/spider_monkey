module Calendar
  module DateCompatible
    include Comparable

    attr_reader :date_object
    private :date_object

    [:date, :strftime, :to_date, :today?, :weekend?, :past?, :day, :beginning_of_week, :end_of_week, :-, :to_time, :to_s, :+]
      .each { |method| delegate method, to: :date_object }

    def <=>(another_day)
      date_object <=> another_day.send(:date_object)
    end

    def succ
      new_date = date_object.succ
      self.class.build new_date
    end

    def first_day_date
      date_object
    end
  end
end
