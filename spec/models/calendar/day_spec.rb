require 'spec_helper'

describe Calendar::Day, calendar: true do
  describe '#requests' do
    it 'returns requests of current day' do
      day = Calendar::Day.build(Time.current)

      request1 = create(:request, scheduled_at: (Time.current))
      request2 = create(:request, scheduled_at: (1.day.from_now))

      expect(day.requests).to eq [request1]
    end
  end
end

