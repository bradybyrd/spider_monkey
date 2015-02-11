require 'spec_helper'

describe Calendar::Rolling, calendar: true do
  describe '#requests' do
    it 'returns requests of specific week' do
      rolling = Calendar::Rolling.new(Date.current)
      first_week = rolling.weeks.first
      request_in_first_week = create(:request, scheduled_at: (first_week.first_day + 1.hour))
      request_out_of_week = create(:request, scheduled_at: (first_week.last_day + 24.hours))

      expect(rolling.requests(first_week)).to eq [request_in_first_week]
    end

    it 'returns all requests of current rolling' do
      rolling = Calendar::Rolling.new(Date.current)
      request_in_first_day = create(:request, scheduled_at: (rolling.first_day + 1.hour))
      request_in_last_day = create(:request, scheduled_at: (rolling.last_day + 1.hour))

      expect(rolling.requests).to eq [request_in_first_day, request_in_last_day]
    end
  end
end
