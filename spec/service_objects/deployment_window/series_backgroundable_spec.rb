require 'spec_helper'

describe DeploymentWindow::SeriesBackgroundable do
  let(:start_at)          { Time.parse('7th Nov 2030 12:00') }
  let(:finish_at)         { start_at + 4.days + 1.hour  }
  let(:duration_in_days)  { 1 }
  let(:environments)      { create_list :environment, 2, :closed }
  let(:series) do
    create :recurrent_deployment_window_series,
                     start_at: start_at,
                     finish_at: finish_at,
                     duration_in_days: duration_in_days,
                     frequency: { interval: 2, rule_type: 'IceCube::DailyRule' }
  end

  before { DeploymentWindow::SeriesBackgroundable.stub(:find_series!) { series } }

  describe '#create_recurrent_occurrences' do
    before  { DeploymentWindow::SeriesBackgroundable.create_recurrent_occurrences(series.id, environments.map(&:id)) }
    after   { series.occurrences.destroy_all }

    it 'builds occurrences with valid duration' do
      expect(series.occurrences.map{|o| o.finish_at - o.start_at}.uniq).to eq([series.duration])
    end

    it 'builds occurrences with valid occurrences count' do
      expect(series.occurrences.size).to eq(2)
    end

    it 'builds events for each environment on each environment' do
      expect(series.events.size).to eq(environments.count * series.occurrences.count)
    end
  end

  describe '#update_recurrent_occurrences_environments' do
    let(:environment_ids_to_delete) { environments.first(2) }
    let(:environment_ids_to_create) { [(create(:environment)).id] }
    let(:passed_occurrence)         { series.occurrences[0] }

    before { DeploymentWindow::SeriesBackgroundable.stub(:background) {DeploymentWindow::SeriesBackgroundable} }

    it 'should delete events for given environment_ids if any' do
      series.should_receive(:delete_events_by_environment_ids).with(environment_ids_to_delete)
      DeploymentWindow::SeriesBackgroundable.update_recurrent_occurrences_environments(series.id, [], environment_ids_to_delete)
    end

    it 'should not delete events for given environment_ids if none' do
      series.should_not_receive(:delete_events_by_environment_ids)
      DeploymentWindow::SeriesBackgroundable.update_recurrent_occurrences_environments(series.id, [], [])
    end

    it 'should update the existing non finished occurrences with given environment_ids if any' do
      DeploymentWindow::SeriesConstruct.new({deployment_window_series:{recurrent:true}}, series).create
      passed_occurrence.update_column(:start_at, Time.zone.now - 2.days)
      passed_occurrence.update_column(:finish_at, Time.zone.now - 1.days)
      DeploymentWindow::Occurrence.any_instance.should_receive(:environment_ids=).once

      DeploymentWindow::SeriesBackgroundable.update_recurrent_occurrences_environments(series.id, environment_ids_to_create, [])
    end

    it 'should not update the existing non finished occurrences with given environment_ids if none' do
      series.should_not_receive(:occurrences)
      DeploymentWindow::SeriesBackgroundable.update_recurrent_occurrences_environments(series.id, [], [])
    end

    it 'should be performed as a #safe_action' do
      DeploymentWindow::SeriesBackgroundable.should_receive(:safe_action).with(series.id)
      DeploymentWindow::SeriesBackgroundable.update_recurrent_occurrences_environments(series.id, [], [])
    end
  end

  describe '#recreate_recurrent_occurrences_and_restore_requests' do
    it 'should work' do
      series.should_receive(:delete_occurrences_not_finished_and_their_events)
      DeploymentWindow::SeriesBackgroundable.should_receive(:create_recurrent_occurrences)
      DeploymentWindow::SeriesConstruct.should_receive(:restore_requests)

      DeploymentWindow::SeriesBackgroundable.recreate_recurrent_occurrences_and_restore_requests(series.id, series.environment_ids, [])
    end

    it 'should be performed as a #safe_action' do
      DeploymentWindow::SeriesBackgroundable.should_receive(:safe_action).with(series.id)
      DeploymentWindow::SeriesBackgroundable.recreate_recurrent_occurrences_and_restore_requests(series.id, series.environment_ids, [])
    end
  end

  describe '#safe_action' do
    it 'should #ensure_timezone' do
      DeploymentWindow::SeriesBackgroundable.should_receive(:ensure_timezone)
      DeploymentWindow::SeriesBackgroundable.send(:safe_action, series.id)
    end

    it 'should #unlock! the series' do
      series.should_receive(:unlock!)
      DeploymentWindow::SeriesBackgroundable.send(:safe_action, series.id)
    end

    it 'should unlock the series if something has crashes' do
      DeploymentWindow::SeriesBackgroundable.stub(:yield).and_raise RuntimeError, 'ops, I did it again'
      series.should_receive(:unlock!)
      DeploymentWindow::SeriesBackgroundable.send(:safe_action, series.id)
    end
  end

  describe '#ensure_timezone' do
    it 'should set a time zone from global settings' do
      GlobalSettings[:timezone] = Time.zone.name
      Time.should_receive(:zone=).with(GlobalSettings[:timezone])
      DeploymentWindow::SeriesBackgroundable.send(:ensure_timezone)
    end

    it 'should not set a time zone from global setting if there is none' do
      GlobalSettings[:timezone] = nil
      Time.should_not_receive(:zone=)
      DeploymentWindow::SeriesBackgroundable.send(:ensure_timezone)
    end
  end
end
