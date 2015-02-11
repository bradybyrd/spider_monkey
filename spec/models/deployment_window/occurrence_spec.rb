require 'spec_helper'

describe DeploymentWindow::Occurrence do
  let(:number_of_test_environments){ 3 }
  let(:environments){ create_list(:environment, number_of_test_environments) }
  let(:series){ create(:recurrent_deployment_window_series, :with_occurrences, environment_ids: environments.map(&:id)) }

  before(:each) do
    DeploymentWindow::Series.delete_all
    Environment.delete_all
  end

  it { should belong_to :series }
  it { should have_many(:events).dependent(:destroy) }
  it { should have_many(:environments).through(:events) }

  it { expect(DeploymentWindow::Occurrence.new.state).to eq(DeploymentWindow::Occurrence::CREATED) }

  describe '#duration' do
    it 'occurrences duration equals series duration' do
      occurrences_duration = series.occurrences.map(&:duration).uniq
      expect(occurrences_duration).to eq([series.duration])
    end
  end

  describe '#build_events' do
    it 'builds events with valid params' do
      occurrence = series.occurrences.first
      expect(occurrence.events.map{|e| e.start_at}.uniq).to eq([occurrence.start_at])
      expect(occurrence.events.map{|e| e.finish_at}.uniq).to eq([occurrence.finish_at])
    end

    it 'builds events for each environment on each occurrence' do
      expect(series.events.size).to eq(number_of_test_environments * series.occurrences.count)
    end

    it 'builds same number of events on each occurrence' do
      expect(series.occurrences.map{|o| o.events.count}.uniq.size).to eq(1)
    end

    it 'does not change number of events during update when number of occurrence is the same' do
      old_events_count = series.events.count
      series.start_at = series.start_at + 1.hour
      series.save
      series.reload
      expect(series.events.count).to eq(old_events_count)
    end

    it 'deletes events when deleting occurrence' do
      series
      expect{series.occurrences.first.destroy}.to change{DeploymentWindow::Event.count}.by(-number_of_test_environments)
    end
  end

  describe '#prev' do
    it 'returns nil when occurrence is first' do
      expect(series.occurrences.first.prev).to be_nil
    end

    it 'returns previous' do
      occur = series.occurrences.second
      expect(occur.prev.next).to eq(occur)
    end

  end

  describe '#next' do
    it 'returns nil when occurrence is last' do
      expect(series.occurrences.last.next).to be_nil
    end

    it 'returns previous' do
      occur = series.occurrences.second
      expect(occur.next.prev).to eq(occur)
    end

  end

end
