require 'spec_helper'

describe DeploymentWindow::SeriesRequestPreserver do
  let(:request_preserver)         { DeploymentWindow::SeriesRequestPreserver.new(series) }
  let(:environments)              { create_list :environment, 3, :closed }
  let(:env_1)                     { environments[0] }
  let(:env_2)                     { environments[1] }
  let(:events_with_env_1)         { series.events.filter_by_environment_ids(env_1.id) }
  let(:events_with_env_2)         { series.events.filter_by_environment_ids(env_2.id) }
  let(:event_1)                   { events_with_env_1.sort_by(&:start_at).first }
  let(:event_2)                   { events_with_env_2.sort_by(&:start_at).first }
  let(:start_at)                  { Time.parse('7th Nov 2030 12:00').in_time_zone }
  let(:finish_at)                 { start_at + 2.days + 1.hour  }
  let(:start_at_from_the_past)    { Time.zone.now - 1.week }
  let(:finish_from_the_past)      { start_at_from_the_past + 1.day }
  let(:finish_from_the_future)    { Time.zone.now + 1.day }
  let(:environment_ids_to_delete) { [environments.last.id] }
  let(:prepared_params)           { {deployment_window_series: {recurrent: true}} }
  let(:req_1)                     { create :request, environment: env_1, estimate: 1, scheduled_at: event_1.start_at }
  let(:req_2)                     { create :request, environment: env_1, estimate: 1, scheduled_at: event_2.start_at }
  let(:request_ids)               { [req_1.id, req_2.id] }
  let(:series)                    { create :recurrent_deployment_window_series, environment_ids: environments.map(&:id),
                                           start_at: start_at, finish_at: finish_at, duration_in_days: 0 }


  before do
    stub_activity_log
    DeploymentWindow::SeriesBackgroundable.stub(:background) { DeploymentWindow::SeriesBackgroundable }
    create_occurrences_with_first_passed(prepared_params, series, start_at_from_the_past, finish_from_the_past)
  end

  describe '#occurrences_to_preserve_request' do
    it 'returns occurrences which are not yet finished' do
      expect(request_preserver.send(:occurrences_to_preserve_request)).to eq series.occurrences.not_finished.all
    end
  end

  describe '#request_ids_in_a_hash' do
    let(:series)  { create :recurrent_deployment_window_series, start_at: start_at, finish_at: finish_at, duration_in_days: 0,
                                                                environment_ids: [env_1.id, env_2.id]}
    let(:req_1)   { create :request, environment: env_1, deployment_window_event_id: event_1.id,
                                     estimate: 1, scheduled_at: event_1.start_at }
    let(:req_2)   { create :request, environment: env_2, deployment_window_event_id: event_2.id,
                                     estimate: 1, scheduled_at: event_2.start_at }

    before do
      req_1 # touch req_1 to create it after occurrences and events have been created
      req_2 # touch req_2 to create it after occurrences and events have been created
    end

    it 'returns a hash like {occurrence_position => {env.id => [request.id]}} item' do
      expect_part_result = { 0 => { env_1.id => [req_1.id], env_2.id => [req_2.id] } }
      expect(request_ids_in_a_hash(series.occurrences)).to include expect_part_result
    end
  end

  describe '#event_id_by' do
    it 'returns events by environment_id and occurrence_relative_position' do
      expect(event_id_by(env_2, 0)).to eq event_2.id
    end
  end

  describe '#assign_event_to_requests' do
    before do
      req_1 # touch req_1 to create it after occurrences and events have been created
      req_2 # touch req_2 to create it after occurrences and events have been created
    end

    it 'assigns event back to their requests' do
      expect{assign_event_to_requests(request_ids, event_1.id)}.to change{event_1.requests.count}.from(0).to(2)
    end
  end

  describe '#restore_requests!' do
    let(:series)            { create :recurrent_deployment_window_series,
                                     start_at: start_at, finish_at: finish_at, duration_in_days: 0,
                                     environment_ids: [env_1.id, env_2.id]}
    let(:stores_requests)   { {0=>{env_1.id=>[], env_2.id=>[]},
                               1=>{env_1.id=>[], env_2.id=>[]},
                               2=>{env_1.id=> request_ids, env_2.id=>[]}} }
    let(:event_id)          { request_preserver.send(:event_id_by, env_1.id, 2) }

    it 'assigns events back to requests from stored_request hash' do
      request_preserver.should_receive(:assign_event_to_requests).with(request_ids, event_id)
      restore_requests!(stores_requests)
    end
  end

  describe '#store_requests' do
    it 'assigns stored_request to series' do
      series.should_receive(:stored_requests=)
      request_preserver.store_requests
    end
  end

  describe '#restore_requests' do
    let(:stored_requests) { mock 'stored_requests' }

    it 'rollbacks requests if exception happens' do
      DeploymentWindow::SeriesRequestPreserver.any_instance.stub(:restore_requests!).and_raise(RuntimeError)
      expect{request_preserver.restore_requests(stored_requests)}.to_not raise_error
    end
  end
end

# create occurrences for given series with:
# - first occurrence passed in time
# - second occurrence in-progress
# - others occurrences in future
def create_occurrences_with_first_passed(prepared_params, series, start_from_the_past, finish_from_the_past)
  construct     = DeploymentWindow::SeriesConstruct.new(prepared_params, series)
  construct.create
  series        = construct.series
  occurrence_0  = series.occurrences[0]
  occurrence_1  = series.occurrences[1]
  occurrence_0.update_column(:start_at, start_from_the_past)
  occurrence_0.update_column(:finish_at, finish_from_the_past)
  occurrence_1.update_column(:start_at, start_from_the_past)
end

def request_ids_in_a_hash(*args)
  request_preserver.send(:request_ids_in_a_hash, *args)
end

def event_id_by(*args)
  request_preserver.send(:event_id_by, *args)
end

def assign_event_to_requests(*args)
  request_preserver.send(:assign_event_to_requests, *args)
end

def restore_requests!(*args)
  request_preserver.send(:restore_requests!, *args)
end
