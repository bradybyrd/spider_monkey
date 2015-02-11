require 'spec_helper'

describe DeploymentWindowOccurrencesHelper do
  describe 'display_state' do
    let(:events) { [double('Event', state: 'created'), double('Event_1', state: 'created')] }
    let(:occurrence) { double('Occurrence', events: events) }

    it 'returns shared state for all occurrences' do
      expect(helper.display_state(occurrence)).to eq('created')
    end

    it "returns 'modified' if occurrences have different states" do
      events.first.stub(:state).and_return('moved')
      expect(helper.display_state(occurrence)).to eq('modified')
    end
  end
end
