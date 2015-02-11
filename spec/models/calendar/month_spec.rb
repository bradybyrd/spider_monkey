require 'spec_helper'

describe Calendar::Month, calendar: true do
  describe '#requests' do
    it 'returns requests of specific week' do
      month = Calendar::Month.new(Date.current)
      first_week = month.weeks.first
      request_in_first_week = create(:request, scheduled_at: (first_week.first_day + 1.hour))
      request_out_of_week = create(:request, scheduled_at: (first_week.last_day + 24.hours))

      expect(month.requests(first_week)).to eq [request_in_first_week]
    end

    it 'returns all requests of current month' do
      month = Calendar::Month.new(Date.current)
      request_in_first_day = create(:request, scheduled_at: (month.first_day + 1.hour))
      request_in_last_day = create(:request, scheduled_at: (month.last_day + 1.hour))

      expect(month.requests.map(&:id)).to match_array [request_in_first_day.id, request_in_last_day.id]
    end
  end
end
