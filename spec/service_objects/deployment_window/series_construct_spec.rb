require 'spec_helper'

describe DeploymentWindow::SeriesConstruct do
  let(:number_of_test_environments){ 3 }
  let(:environments){ create_list(:environment, number_of_test_environments, deployment_policy: 'closed') }

  let(:series) { build(:deployment_window_series) }
  let(:params) { { deployment_window_series: {
                    name: 'Ubik',
                    behavior: 'allow',
                    start_at: '01/01/3000',
                    "start_at(4i)"  => "04",
                    "start_at(5i)"  => "27",
                    finish_at: '02/01/3000',
                    "finish_at(4i)" => "05",
                    "finish_at(5i)" => "27",
                    recurrent: false,
                    frequency: 'null',
                    duration_in_days: '1',
                    environment_ids: environments.map(&:id).to_s
                  }
                } }
  let(:prepared_params) { DeploymentWindow::SeriesConstructHelper.prepare_params(params) }

  before do
    stub_activity_log
    DeploymentWindow::SeriesBackgroundable.stub(:background) { DeploymentWindow::SeriesBackgroundable }
  end

  describe '#build_occurrences' do
    let(:series_construct) { DeploymentWindow::SeriesConstruct.new(prepared_params, series) }
    let(:background) { mock 'background' }

    context 'when series is recurrent' do
      before do
        series_construct.stub(:recurrent?).and_return(true)
        DeploymentWindow::SeriesBackgroundable.stub(:background) { background }
      end

      it 'calls build_recurrent_occurrences in a background' do
        series_construct.should_receive(:build_recurrent_occurrences)
        series_construct.send(:build_occurrences)
      end
    end

    context 'when series is not recurrent' do
      before do
        series_construct.stub(:recurrent?).and_return(false)
      end

      it 'calls build_nonrecurrent_occurrences' do
        series_construct.should_receive(:build_nonrecurrent_occurrences).once
        series_construct.send(:build_occurrences)
      end
    end
  end

  describe '#update_occurrences' do
    let(:series)            { create(:deployment_window_series) }
    let(:series_construct)  { DeploymentWindow::SeriesConstruct.new(prepared_params, series) }

    context 'when series is recurrent' do
      before { series_construct.stub(:recurrent?).and_return(true) }

      it 'calls update_recurrent_occurrences' do
        series_construct.should_receive(:update_recurrent_occurrences)
        series_construct.send(:update_occurrences)
      end
    end

    context 'when series is not recurrent' do
      before  { series_construct.stub(:recurrent?).and_return(false) }
      after   { series_construct.send(:update_occurrences) }

      it 'calls update_nonrecurrent_occurrences when #non_recurrent_changed?' do
        series_construct.stub(:non_recurrent_changed?).and_return(true)
        series_construct.should_receive(:update_nonrecurrent_occurrences).and_return(true)
      end

      it 'calls update_nonrecurrent_occurrences when #environments_changed?' do
        series_construct.stub(:non_recurrent_changed?).and_return(true)
        series_construct.should_receive(:update_nonrecurrent_occurrences).and_return(true)
      end

      it 'does not call update_nonrecurrent_occurrences when neither #environments_changed and #non_recurrent_changed?' do
        series_construct.stub(:non_recurrent_changed?).and_return(false)
        series_construct.stub(:environments_changed?).and_return(false)
        series_construct.should_not_receive(:update_nonrecurrent_occurrences)
      end
    end
  end

  describe '#create' do
    let(:series) { create(:deployment_window_series) }
    let(:series_construct) { DeploymentWindow::SeriesConstruct.new(prepared_params, series) }

    it 'returns false if series is not valid' do
      series.stub(:valid?).and_return(false)
      expect(series_construct.create).to be_falsey
    end

    it 'builds occurrences' do
      series_construct.should_receive(:build_occurrences).and_return(true)
      series_construct.create
    end

    describe 'persists series' do
      it 'calls save on series' do
        series.should_receive(:save).and_return(true)
        series_construct.create
      end

      it 'saves the series' do
        DeploymentWindow::SeriesConstruct.new(prepared_params).create
        expect(DeploymentWindow::Series.last.name).to eq('Ubik')
      end
    end

    context 'when occurrence.start_at < series.finish_at but occurrence.finish_at > series.finish_at' do
      let(:created_series)  { DeploymentWindow::Series.find_by_name(name) }
      let(:name)            { 'Ruby-ruby-ruby-ruby-aAa-aAa-aaa' }
      let(:start_at_str)    { '01/01/3000' }
      let(:finish_at_str)   { '01/05/3000' } # for 5 days
      let(:params) do
        {
            deployment_window_series: {
                name: name,
                behavior: 'prevent',
                start_at: start_at_str,
                finish_at: finish_at_str,
                'start_at(4i)'  => '00',
                'start_at(5i)'  => '00',
                'finish_at(4i)' => '19',
                'finish_at(5i)' => '00',
                recurrent: 'true',
                frequency: {interval: 2, rule_type: 'IceCube::DailyRule'},
                duration_in_days: '1',
                environment_ids: '[1, 2]'
            }
        }
      end

      before { DeploymentWindow::SeriesBackgroundable.stub(:background).and_return(DeploymentWindow::SeriesBackgroundable) }

      it 'should create series with 2 occurrences as the 3rd finish_at is after series.finish_at' do
        DeploymentWindow::SeriesConstruct.new(prepared_params).create
        expect(created_series.occurrences.count).to eq 2
        expect(created_series.occurrences_ready?).to be_truthy
      end

    end
  end

  describe '#update' do
    let(:series) { create(:deployment_window_series) }
    let!(:series_construct) { DeploymentWindow::SeriesConstruct.new(prepared_params, series) }

    before {series_construct.stub(:update_occurrences)}

    it 'returns false if series is not valid' do
      series.stub(:valid?).and_return(false)
      expect(series_construct.update).to be_falsey
    end

    it 'calls save on series' do
      series.should_receive(:save).and_return(true)
      series_construct.update
    end

    it 'updates occurrences if series was saved' do
      series.should_receive(:save).and_return(true)
      series_construct.should_receive(:update_occurrences)
      series_construct.update
    end

    it 'does not update occurrences if series is not saved' do
      series.should_receive(:save).and_return(false)
      series_construct.should_not_receive(:update_occurrences)
      series_construct.update
    end

    describe '#send_notification' do
      let!(:series)           { create(:deployment_window_series) }
      let!(:request)          { create(:request) }
      let!(:series_construct) { DeploymentWindow::SeriesConstruct.new(prepared_params, series) }

      before do
        series_construct.series.stub(:requests).and_return([request])
        series_construct.stub(:update_occurrences).and_return(true)
      end

      it 'sends notification for each request' do
        series_construct.stub(:store_requests)
        series_construct.should_receive(:send_notification).exactly(1).times
        series_construct.update
      end

    end
  end

  describe '#build_nonrecurrent_occurrences' do
    let(:series_construct) { DeploymentWindow::SeriesConstruct.new(prepared_params) }
    subject { series_construct.series }
    before { series_construct.create }

    it 'builds occurrence with valid params' do
      occurrence = subject.occurrences.first
      expect(occurrence.start_at).to eq(subject.start_at)
      expect(occurrence.finish_at).to eq(subject.finish_at)
    end

    it 'builds 1 occurrence' do
      expect(subject.occurrences.size).to eq(1)
    end

    it 'builds events for each environment' do
      expect(subject.events.count).to eq(3)
    end
  end

  describe '#update_nonrecurrent_occurrences' do
    let(:series)           { create(:deployment_window_series) }
    let(:occurrence)       { build(:deployment_window_occurrence, start_at: Time.now - 1.year, finish_at: Time.now + 1.year, series_id: series.id) }
    let(:series_construct)  { DeploymentWindow::SeriesConstruct.new(prepared_params, series) }
    let(:events)            { mock('events') }
    let(:new_attributes)    { {position: 1, start_at: series.start_at, finish_at: series.finish_at, name: series.name, behavior: series.behavior, environment_names: environments.map(&:name).join(', ')} }
    let(:environments_to_delete) { [1] }
    let(:environments_to_create) { [4] }

    before {
      series_construct.stub(:environments_to_delete) { environments_to_delete }
      series_construct.stub(:environments_to_create) { environments_to_create }
      series.stub(:occurrences).and_return([occurrence])
      series_construct.stub(:non_recurrent_changed?).and_return(false)
    }

    after { series_construct.send(:update_nonrecurrent_occurrences) }

    it 'deletes series events when series environments have been deleted' do
      DeploymentWindow::Event.stub(:where).and_return(events)
      events.should_receive(:delete_all)
    end

    it 'assigns new environment_ids' do
      occurrence.stub(:save).and_return(true)
      series.occurrences[0].should_receive(:environment_ids=).with(environments_to_create)
    end

    it 'updates the occurrence' do
      series_construct.stub(:environments_changed?).and_return(true)
      series.stub(:environment_names).and_return(environments.map(&:name).join(', '))
      series.occurrences[0].should_receive(:attributes=).with(new_attributes)
    end

    it 'saves the occurrence' do
      series.occurrences[0].should_receive(:save)
    end
  end

  describe '#store_requests' do
    let(:series_construct)    { DeploymentWindow::SeriesConstruct.new(prepared_params, series) }
    let!(:request_preserver)  { DeploymentWindow::SeriesRequestPreserver.new series}

    before { DeploymentWindow::SeriesRequestPreserver.stub(:new) { request_preserver } }

    it 'should call #store_requests of SeriesRequestPreserver' do
      request_preserver.should_receive :store_requests
      series_construct.send :store_requests
    end
  end

  describe '#restore_requests' do
    let(:series)              { create :deployment_window_series }
    let(:stored_requests)     { {1 => 'some_request'} }
    let!(:request_preserver)  { DeploymentWindow::SeriesRequestPreserver.new series}

    before { DeploymentWindow::SeriesRequestPreserver.stub(:new) { request_preserver } }

    it 'should call #restore_requests of SeriesRequestPreserver' do
      request_preserver.should_receive(:restore_requests).with(stored_requests)
      DeploymentWindow::SeriesConstruct.restore_requests(series, stored_requests)
    end
  end

  describe '#initialize' do
    context 'with wrong start_at date format' do
      let(:initialize) { DeploymentWindow::SeriesConstruct.new(prepared_params, series)  }
      let(:params) { { deployment_window_series: {
          name: 'Monkey',
          behavior: 'prevent',
          start_at: '2030/01/13',
          'start_at(4i)'  => '04',
          'start_at(5i)'  => '00',
          finish_at: '02/01/3000',
          'finish_at(4i)' => '05',
          'finish_at(5i)' => '00',
          recurrent: false,
          frequency: 'null',
          duration_in_days: '0',
          environment_ids: '1,2,3'
      }
      } }

      it 'is not raising error' do
        expect{initialize}.to_not raise_error
      end

      it 'saves the errors in @exception' do
        construct = initialize
        exception = construct.instance_variable_get(:@exception)
        expect(exception.errors.size).to eq(1)
      end

      it 'builds environments for series' do
        expect(initialize.series.environment_ids).to include 1, 2, 3
      end
    end
  end

  describe '#valid?' do
    let(:series_construct) { DeploymentWindow::SeriesConstruct.new(prepared_params, series) }

    context 'with any @exception' do
      before do
        series_construct.instance_variable_set(:@exception, [] )
        DeploymentWindow::SeriesValidator.any_instance.stub(:check_bad_date_format)
      end

      it 'does not validate series' do
        series_construct.series.should_not_receive(:valid?)
        series_construct.valid?
      end
    end

    context 'without @exception' do
      before { series_construct.instance_variable_set(:@exception, nil ) }

      it 'does not validate series' do
        series_construct.series.should_receive(:valid?)
        series_construct.valid?
      end
    end
  end

  describe '#dates_existing' do
    context 'valid dates' do
      let(:valid_params) { { deployment_window_series: {
                                   :"start_at(1i)"=> '2030',
                                   :"start_at(2i)"=> '03',
                                   :"start_at(3i)"=> '29',
                                   :"finish_at(1i)"=> '2030',
                                   :"finish_at(2i)"=> '03',
                                   :"finish_at(3i)"=> '31' } } }
      let(:valid_dates) { { start_at_invalid: false, finish_at_invalid: false } }
      context 'on create' do
        let(:series_construct_valid) { DeploymentWindow::SeriesConstruct.new(valid_params) }
        it 'builds hash' do
          expect(series_construct_valid.send(:dates_existing)).to eq valid_dates
        end

        it 'does not set to nil both dates field' do
          series_construct_valid.send(:dates_existing)
          expect(series_construct_valid.series.start_at).not_to be_nil
          expect(series_construct_valid.series.finish_at).not_to be_nil
        end
      end
    end

    context 'invalid start' do
      let(:invalid_start_valid_finish) { { start_at_invalid: true,  finish_at_invalid: false } }
      let(:invalid_start_only) { { deployment_window_series: {
                                   :"start_at(1i)"=> '2030',
                                   :"start_at(2i)"=> '02',
                                   :"start_at(3i)"=> '29',
                                   :"finish_at(1i)"=> '2030',
                                   :"finish_at(2i)"=> '03',
                                   :"finish_at(3i)"=> '31' } } }
      context 'on create' do
        let(:series_construct_invalid_start) { DeploymentWindow::SeriesConstruct.new(invalid_start_only) }
        it 'builds hash' do
          expect(series_construct_invalid_start.send(:dates_existing)).to eq invalid_start_valid_finish
        end

        it 'sets to nil start_at field' do
          series_construct_invalid_start.send(:dates_existing)
          expect(series_construct_invalid_start.series.start_at).to be_nil
          expect(series_construct_invalid_start.series.finish_at).not_to be_nil
        end
      end
    end

    context 'invalid finish' do
      let(:valid_start_invalid_finish) { { start_at_invalid: false, finish_at_invalid: true  } }
      let(:invalid_finish_only) { { deployment_window_series: {
                                   :"start_at(1i)"=> '2030',
                                   :"start_at(2i)"=> '02',
                                   :"start_at(3i)"=> '14',
                                   :"finish_at(1i)"=> '2030',
                                   :"finish_at(2i)"=> '02',
                                   :"finish_at(3i)"=> '31' } } }
      context 'on create' do
        let(:series_construct_invalid_finish) { DeploymentWindow::SeriesConstruct.new(invalid_finish_only) }
        it 'builds hash' do
          expect(series_construct_invalid_finish.send(:dates_existing)).to eq valid_start_invalid_finish
        end

        it 'sets to nil finish_at field' do
          series_construct_invalid_finish.send(:dates_existing)
          expect(series_construct_invalid_finish.series.start_at).not_to be_nil
          expect(series_construct_invalid_finish.series.finish_at).to be_nil
        end
      end
    end

    context 'invalid dates' do
      let(:invalid_params) { { deployment_window_series: {
                                   :"start_at(1i)"=> '2030',
                                   :"start_at(2i)"=> '02',
                                   :"start_at(3i)"=> '29',
                                   :"finish_at(1i)"=> '2030',
                                   :"finish_at(2i)"=> '02',
                                   :"finish_at(3i)"=> '31' } } }
      let(:invalid_dates) { { start_at_invalid: true,  finish_at_invalid: true  } }
      context 'on create' do
        let(:series_construct_invalid) { DeploymentWindow::SeriesConstruct.new(invalid_params) }
        it 'builds hash' do
          expect(series_construct_invalid.send(:dates_existing)).to eq invalid_dates
        end

        it 'sets to nil both dates field' do
          series_construct_invalid.send(:dates_existing)
          expect(series_construct_invalid.series.start_at).to be_nil
          expect(series_construct_invalid.series.start_at).to be_nil
        end
      end
    end
  end

end
