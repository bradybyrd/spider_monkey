require 'spec_helper'

describe Calendar::Week, calendar: true do
  describe '#requests' do
    it 'returns requests of specific day' do
      week = Calendar::Week.new(Time.current)
      request_in_first_day = create(:request, scheduled_at: week_start_time(week))
      request_in_last_day = create(:request, scheduled_at: week_end_time(week))

      expect(week.requests(week.first_day.date_object)).to eq [request_in_first_day]
      expect(week.requests(week.last_day.date_object)).to eq [request_in_last_day]
    end

    it 'returns all requests of current week' do
      week = Calendar::Week.new(Time.current)
      request_in_first_day = create(:request, scheduled_at: week_start_time(week))
      request_in_last_day = create(:request, scheduled_at: week_end_time(week))

      expect(week.requests).to eq [request_in_first_day, request_in_last_day]
    end
  end

  private

  def time_in_zone(date)
    Time.zone.parse(date.to_s)
  end

  def week_start_time(week)
    time_in_zone(week.first_day.date_object)
  end

  def week_end_time(week)
    time_in_zone(week.last_day.date_object)
  end
end

