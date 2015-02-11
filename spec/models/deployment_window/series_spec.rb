require 'spec_helper'

describe DeploymentWindow::Series do
  before do
    stub_activity_log
    DeploymentWindow::SeriesBackgroundable.stub(:background) {DeploymentWindow::SeriesBackgroundable}
    DeploymentWindow::SeriesConstruct.any_instance.stub(:dates_existing)
  end

  let(:number_of_test_environments){ 3 }
  let(:environments){ create_list(:environment, number_of_test_environments, deployment_policy: 'closed') }

  it { should have_many(:occurrences).dependent(:destroy) }
  it { should have_many(:events).through(:occurrences) }
  it { should have_many(:environments).through(:events) }

  it { should ensure_inclusion_of(:behavior).in_array(DeploymentWindow::Series::BEHAVIOR) }
  it { should validate_presence_of :behavior }
  it { should validate_presence_of :name }

  # shoulda mathers working unexpected for these ones

  # it { should validate_uniqueness_of :name }
  # it { should ensure_length_of(:name).is_at_most(255) }

  it { should serialize(:schedule).as(IceCube::Schedule) }

  describe '.fetch_depends_on_user' do
    let(:admin) { create(:user) }
    let(:coordinator_role) { create(:role, name: 'deployment_coordinator') }
    let(:deployer_role) { create(:role, name: 'deployer') }
    let(:coordinator) { create(:user, roles: [coordinator_role], admin: false) }
    let(:deployer) { create(:user, roles: [deployer_role], admin: false) }

    let(:coordinator_env) { create(:environment, id: 10) }
    let(:deployer_env) { create(:environment, id: 11) }

    let(:admin_dws) { create(:deployment_window_series, environment_ids: [10, 11]) }
    let(:coordinator_dws) { create(:deployment_window_series, environment_ids: [10]) }
    let(:deployer_dws) { create(:recurrent_deployment_window_series, environment_ids: [11]) }

    it 'returns all DWs if user is admin' do
      admin.stub(:environments).and_return([deployer_env, coordinator_env])
      expect(DeploymentWindow::Series.fetch_depends_on_user(admin)).to eq [admin_dws, coordinator_dws, deployer_dws]
    end

    it 'returns only DWs with environments assigned to applications of coordinator' do
      coordinator.stub(:environments).and_return([coordinator_env])
      expect(DeploymentWindow::Series.fetch_depends_on_user(coordinator)).to eq [coordinator_dws]
    end

    it 'returns only DWs with environments assigned to applications of deployer' do
      deployer.stub(:environments).and_return([deployer_env])
      expect(DeploymentWindow::Series.fetch_depends_on_user(deployer)).to eq [deployer_dws]
    end
  end

  context 'date validations' do
    let(:series_with_valid_start_date) { build(:recurrent_deployment_window_series, start_at: Time.now + 1.day) }
    let(:series_with_invalid_start_date) { build(:recurrent_deployment_window_series, start_at: Time.now - 1.day) }

    let(:series_with_valid_start_time) { build(:recurrent_deployment_window_series, start_at: Time.now + 1.hour) }
    let(:series_with_invalid_start_time) { build(:recurrent_deployment_window_series, start_at: Time.now - 1.hour) }

    let(:series_with_valid_finish_date) { build(:recurrent_deployment_window_series, start_at: Time.now, finish_at: Time.now + 1.day) }
    let(:series_with_valid_finish_time) { build(:recurrent_deployment_window_series, start_at: Time.now, finish_at: Time.now + 1.hour) }

    let(:series_with_invalid_finish_date) { build(:recurrent_deployment_window_series, start_at: Time.now, finish_at: Time.now - 1.day) }
    let(:series_with_invalid_finish_time) { build(:recurrent_deployment_window_series, start_at: Time.now, finish_at: Time.now - 1.hour) }

    describe '#start_in_past?' do
      it 'checks if start_at date/time is valid' do
        expect(series_with_valid_start_date.start_in_past?).to be_falsey
      end

      it 'checks if start_at date/time is in the past' do
        expect(series_with_invalid_start_date.start_in_past?).to be_truthy
        expect(series_with_valid_start_time.start_in_past?).to be_falsey
        expect(series_with_invalid_start_time.start_in_past?).to be_truthy
      end
    end

    describe '#start_in_past_date?' do
      it 'checks if start_at date is valid' do
        expect(series_with_valid_start_date.start_in_past_date?).to be_falsey
      end

      it 'checks if start_at date is in the past' do
        pending 'fix in custom role release'

        expect(series_with_invalid_start_date.start_in_past_date?).to be_truthy
        expect(series_with_valid_start_time.start_in_past_date?).to be_falsey
        expect(series_with_invalid_start_time.start_in_past_date?).to be_falsey
      end
    end

    describe '#start_in_past_date?' do
      it 'checks if start_at time is valid' do
        expect(series_with_valid_start_time.start_in_past_time?).to be_falsey
      end

      it 'checks if start_at time is in the past' do
        pending 'fix in custom role release'

        expect(series_with_invalid_start_time.start_in_past_time?).to be_truthy
      end
    end

    describe '#finish_before_past_date?' do
      it 'checks if start_at date is valid' do
        expect(series_with_valid_finish_date.finish_before_past_date?).to be_falsey
      end

      it 'checks if start_at date is in the past' do
        expect(series_with_invalid_finish_date.finish_before_past_date?).to be_truthy
      end
    end

    describe '#finish_before_past_time?' do
      it 'checks if start_at hours/minutes is valid' do
        expect(series_with_valid_finish_time.finish_before_past_time?).to be_falsey
      end

      it 'checks if start_at hours/minutes is in the past' do
        expect(series_with_invalid_finish_time.finish_before_past_time?).to be_truthy
      end
    end
  end

  context "date/time validation messages" do

    describe '#check_start_in_past' do
      let(:recurrent_start_time_invalid)             { build(:recurrent_deployment_window_series, start_at: Time.now - 1.hour) }
      let(:non_recurrent_start_time_invalid)         { build(:deployment_window_series, start_at: Time.now - 1.hour) }
      let(:recurrent_start_date_before_current)      { build(:recurrent_deployment_window_series, start_at: Time.now - 1.day) }
      let(:non_recurrent_start_date_before_current)  { build(:deployment_window_series, start_at: Time.now - 1.day) }

      it 'generate right error message if start time is before current time for recurrent DWs' do
        pending 'fix in custom role release'

        recurrent_start_time_invalid.check_start_in_past
        expect(recurrent_start_time_invalid.errors[:base]).to eq [I18n.t('deployment_window.validations.date.recurrent.start_at_before_current_time')]
      end

      it 'generate right error message if start time is before current time for non recurrent DWs' do
        pending 'fix in custom role release'

        non_recurrent_start_time_invalid.check_start_in_past
        expect(non_recurrent_start_time_invalid.errors[:base]).to eq [I18n.t('deployment_window.validations.date.non_recurrent.start_at_before_current_time')]
      end

      it 'generate right error message if start date is before current date DWs' do
        [non_recurrent_start_date_before_current, recurrent_start_date_before_current].each{|w| w.check_start_in_past}
        expect(non_recurrent_start_date_before_current.errors[:base]).to eq [I18n.t('deployment_window.validations.date.start_at_before_current_date')]
        expect(recurrent_start_date_before_current.errors[:base]).to eq [I18n.t('deployment_window.validations.date.start_at_before_current_date')]
      end
    end

    describe '#check_finish_before_past' do
      let(:recurrent_finish_time_invalid)            { build(:recurrent_deployment_window_series, start_at: Time.now + 1.hour, finish_at: Time.now) }
      let(:non_recurrent_finish_time_invalid)        { build(:deployment_window_series, start_at: Time.now + 1.hour, finish_at: Time.now) }
      let(:recurrent_finish_before_start)            { build(:recurrent_deployment_window_series, start_at: Time.now + 1.day, finish_at: Time.now) }
      let(:non_recurrent_finish_before_start)        { build(:deployment_window_series, start_at: Time.now + 1.day, finish_at: Time.now) }

      it 'generate right error message if finish time is before start time for recurrent DWs' do
        recurrent_finish_time_invalid.check_finish_before_past
        expect(recurrent_finish_time_invalid.errors[:base]).to eq [I18n.t('deployment_window.validations.date.recurrent.finish_at_before_start_at_time')]
      end

      it 'generate right error message if finish time is before start time for non recurrent DWs' do
        non_recurrent_finish_time_invalid.check_finish_before_past
        expect(non_recurrent_finish_time_invalid.errors[:base]).to eq [I18n.t('deployment_window.validations.date.non_recurrent.finish_at_before_start_at_time')]
      end

      it 'generate right error message if finish date is before start date DWs' do
        [non_recurrent_finish_before_start, recurrent_finish_before_start].each{|w| w.check_finish_before_past}
        expect(non_recurrent_finish_before_start.errors[:base]).to eq [I18n.t('deployment_window.validations.date.finish_at_before_start_at_date')]
        expect(recurrent_finish_before_start.errors[:base]).to eq [I18n.t('deployment_window.validations.date.finish_at_before_start_at_date')]
      end
    end

    describe '#check_finish_equal_start' do
      let(:recurrent_finish_time_equal_start)        { build(:recurrent_deployment_window_series, start_at: Time.now + 2.days + 1.hour, finish_at: Time.now + 2.days + 1.hour) }
      let(:non_recurrent_finish_time_equal_start)    { build(:deployment_window_series, start_at: Time.now + 2.days + 1.hour, finish_at: Time.now + 2.days + 1.hour) }

      it 'generate right error message if finish time is equal start time for recurrent DWs' do
        recurrent_finish_time_equal_start.check_finish_equal_start
        expect(recurrent_finish_time_equal_start.errors[:base]).to eq [I18n.t('deployment_window.validations.date.recurrent.start_at_equal_finish_at')]
      end

      it 'generate right error message if finish time is equal start time for non recurrent DWs' do
        non_recurrent_finish_time_equal_start.check_finish_equal_start
        expect(non_recurrent_finish_time_equal_start.errors[:base]).to eq [I18n.t('deployment_window.validations.date.non_recurrent.start_at_equal_finish_at')]
      end
    end
  end

  describe '#update_schedule' do
    subject{ build(:recurrent_deployment_window_series) }

    it 'updates start_at time and duration' do
      expect(subject.valid?).to be_truthy
      expect(subject.schedule.start_time).to eq(subject.start_at)
    end
  end

  describe '#duration' do
    let(:start_at)    { Time.parse('7th Nov 2030 12:00') }
    let(:finish_at)   { start_at + duration  }
    let(:duration)    { 4.days + 1.hour }

    it 'return correct value for non recurrent' do
      nonrecurrent = build(:deployment_window_series, start_at: start_at, finish_at: finish_at)
      expect(nonrecurrent.duration).to eq(duration)
    end

    it 'return correct value for recurrent' do
      recurrent = build(:recurrent_deployment_window_series, start_at: start_at, finish_at: finish_at, duration_in_days: 1,
                        frequency: {interval: 2, rule_type: 'IceCube::DailyRule'})
      expect(recurrent.duration).to eq(1.day + 1.hour)
    end
  end

  describe '#duration_upon_day' do
    let(:start_at)    { Time.parse('7th Nov 2030 12:00') }
    let(:finish_at)   { start_at + duration  }
    let(:duration)    { 4.days - 1.hour }

    it 'return 0 when dates are missing' do
      nonrecurrent = build(:recurrent_deployment_window_series, start_at: nil)
      expect(nonrecurrent.duration_upon_day).to be_zero
    end

    it 'return correct value' do
      recurrent =  build(:recurrent_deployment_window_series, start_at: start_at, finish_at: finish_at, duration_in_days: 1,
                            frequency: {interval: 2, rule_type: 'IceCube::DailyRule'})
      expect(recurrent.duration_upon_day).to eq(-1.hour)
    end
  end

  context 'Duration validations' do
    let(:series_with_overlapped_duration) { build(:recurrent_deployment_window_series, duration_in_days: 5,
                                                  start_at: Time.now + 1.day, finish_at: Time.now + 3.day) }
    let(:series_without_overlapped_duration) { build(:recurrent_deployment_window_series, duration_in_days: 2,
                                                     start_at: Time.now + 1.day, finish_at: Time.now + 6.day) }

    describe '#duration_overlap?' do
      it 'returns false if duration is less than whole time' do
        expect(series_without_overlapped_duration.duration_overlap?).to be_falsey
      end

      it 'returns true if duration is greater than whole time' do
        expect(series_with_overlapped_duration.duration_overlap?).to be_truthy
      end
    end
  end

  describe '#toggle_archive' do
    context 'archived' do
      let(:archived_deployment_window_series) { create(:deployment_window_series, archive_number: '123', archived_at: Date.today, aasm_state: 'archived_state') }
      it 'archives not archived series' do
        expect(archived_deployment_window_series.archived?).to be_truthy
        archived_deployment_window_series.toggle_archive
        expect(archived_deployment_window_series.archived?).to be_falsey
      end
    end

    context 'not archived' do
      let(:deployment_window_series) { create(:deployment_window_series, aasm_state: 'retired') }
      it 'unarchives archived series' do
        expect(deployment_window_series.archived?).to be_falsey
        deployment_window_series.toggle_archive
        expect(deployment_window_series.archived?).to be_truthy
      end
    end
  end

  context 'callbacks' do
    describe '#check_if_destroyable' do
      context 'archived' do
        let!(:archived_deployment_window_series) { create(:deployment_window_series, archive_number: '123', archived_at: Date.today) }
        it 'deletes deployment window series' do
          expect{ archived_deployment_window_series.destroy }.to change(DeploymentWindow::Series, :count).by(-1)
        end
      end

      context 'not archived' do
        let!(:deployment_window_series) { create(:deployment_window_series) }
        it 'does not delete deployment window series' do
          expect{ deployment_window_series.destroy }.to_not change(DeploymentWindow::Series, :count)
        end
      end
    end
  end

  describe '#can_be_archived?' do
    let(:environments) { create_list(:environment, 5) }
    let(:environment_ids) { environments.map { |e| e.id } }
    let(:series) { create(:deployment_window_series, :with_active_request, environment_ids: environment_ids) }
    it 'returns true if has no active requests' do
      expect(series.can_be_archived?).to be_truthy
    end

    it 'returns false if has no active requests' do
      series.stub(:has_active_requests?).and_return(true)
      expect(series.can_be_archived?).to be_falsey
    end
  end

  describe '#validator' do
    let(:series) { DeploymentWindow::Series.new }

    it 'should create new validator from self' do
      DeploymentWindow::SeriesValidator.should_receive(:new).with(series)
      series.validator
    end
  end

  describe '#check_behavior' do
    it 'should be valid if it is a new record' do
      series = build :deployment_window_series
      series.behavior = DeploymentWindow::Series::PREVENT
      expect(series.valid?).to be_truthy
    end
    it 'should be invalid if we change behavior' do
      series = create :deployment_window_series
      series.behavior = DeploymentWindow::Series::PREVENT
      expect(series.valid?).to be_falsey
    end
  end

  describe '#schedule_rule' do
    let(:series) {
      series = build :recurrent_deployment_window_series, frequency: {interval: 2, rule_type: 'IceCube::DailyRule'}
      series.send(:update_schedule)
      series
    }

    it 'returns IceCube Rule object' do
      expect(series.schedule_rule).to be_a(IceCube::DailyRule)
    end
  end

  describe '#frequency_hash' do
    let(:series) { build :recurrent_deployment_window_series }

    it "converts frequency json to hash" do
      series.stub(:frequency).and_return('{"interval": 1, "rule_type": "IceCube::DailyRule"}')
      expect(series.frequency_hash).to be_a(Hash)
    end

    it "returns frequency if it's a hash" do
      expect(series.frequency_hash).to eq(series.frequency)
    end
  end

  describe '#schedule_from' do
    let(:series) { build :recurrent_deployment_window_series }

    it "creates schedule instance" do
      expect(series.schedule_from(series.start_at)).to be_a(IceCube::Schedule)
    end
  end

  context 'frequency validations' do
    let(:series_valid) { build :recurrent_deployment_window_series, frequency: valid_frequency }
    let(:series_invalid) { build :recurrent_deployment_window_series, frequency: invalid_frequency }

    before :each do
      DeploymentWindow::SeriesConstruct.any_instance.stub(:build_occurrences).and_return(true)
    end

    describe "#check_daily_frequency" do
      let(:valid_frequency) { {interval: 999, rule_type: 'IceCube::DailyRule'} }
      let(:invalid_frequency) { {interval: 1000, rule_type: 'IceCube::DailyRule'} }

      it "should be valid if daily frequency is on range 1-999" do
        expect(series_valid.valid?).to be_truthy
      end

      it "should be invalid if daily frequency is not on range 1-999" do
        expect(series_invalid.valid?).to be_falsey
        expect(series_invalid.errors.full_messages).to include(I18n.t('deployment_window.validations.frequency.daily_range', range: '1-999'))
      end
    end

    describe "#check_weekly_frequency" do
      let(:valid_frequency) { {interval: 99, rule_type: 'IceCube::WeeklyRule', validations: {day: [1,2]}} }
      let(:invalid_frequency) { {interval: 100, rule_type: 'IceCube::WeeklyRule', validations: {day: [1,2]}} }

      it "should be valid if weekly frequency is on range 1-99" do
        expect(series_valid.valid?).to be_truthy
      end

      it "should be invalid if weekly frequency is not on range 1-99" do
        expect(series_invalid.valid?).to be_falsey
        expect(series_invalid.errors.full_messages).to include(I18n.t('deployment_window.validations.frequency.weekly_range', range: '1-99'))
      end
    end

    describe "#check_monthly_frequency" do
      let(:valid_frequency) { {interval: 99, rule_type: 'IceCube::MonthlyRule', validations: {day_of_month: [1,2]}} }
      let(:invalid_frequency) { {interval: 100, rule_type: 'IceCube::MonthlyRule', validations: {day_of_month: [1,2]}} }

      it "should be valid if monthly frequency is on range 1-99" do
        expect(series_valid.valid?).to be_truthy
      end

      it "should be invalid if monthly frequency is not on range 1-99" do
        expect(series_invalid.valid?).to be_falsey
        expect(series_invalid.errors.full_messages).to include(I18n.t('deployment_window.validations.frequency.monthly_range', range: '1-99'))
      end
    end

    describe "#check_weekly_days" do
      let(:valid_frequency) { {interval: 1, rule_type: 'IceCube::WeeklyRule', validations: {day: [1,2]}} }
      let(:invalid_frequency) { {interval: 1, rule_type: 'IceCube::WeeklyRule', validations: {}} }

      it "should be valid if weekly frequency has selected days" do
        expect(series_valid.valid?).to be_truthy
      end

      it "should be invalid if weekly frequency does not have selected days" do
        expect(series_invalid.valid?).to be_falsey
        expect(series_invalid.errors.full_messages).to include(I18n.t('deployment_window.validations.frequency.weekly_days'))
      end
    end

    describe "#check_monthly_days" do
      let(:valid_frequency) { {interval: 1, rule_type: 'IceCube::MonthlyRule', validations: {day_of_month: [1,2]}} }
      let(:invalid_frequency) { {interval: 1, rule_type: 'IceCube::MonthlyRule', validations: {}} }

      it "should be valid if monthly frequency has selected days" do
        expect(series_valid.valid?).to be_truthy
      end

      it "should be invalid if monthly frequency does not have selected days" do
        expect(series_invalid.valid?).to be_falsey
        expect(series_invalid.errors.full_messages).to include(I18n.t('deployment_window.validations.frequency.monthly_days'))
      end
    end
  end

  describe '#delete_events_by_environment_ids' do
    let(:environments)              { create_list :environment, 3, :closed }
    let(:start_at)                  { Time.parse('7th Nov 2030 12:00').in_time_zone }
    let(:finish_at)                 { start_at + 2.days + 1.hour  }
    let(:start_at_from_the_past)    { Time.zone.now - 1.week }
    let(:finish_from_the_past)      { start_at_from_the_past + 1.day }
    let(:finish_from_the_future)    { Time.zone.now + 1.day }
    let(:environment_ids_to_delete) { [environments.last.id] }
    let(:prepared_params)           { {deployment_window_series: {recurrent: true}} }
    let(:series)                    { create :recurrent_deployment_window_series, environment_ids: environments.map(&:id),
                                             start_at: start_at, finish_at: finish_at, duration_in_days: 0 }

    before do
      create_occurrences_with_first_passed(prepared_params, series, start_at_from_the_past, finish_from_the_past)
    end

    def delete
      series.delete_events_by_environment_ids(environment_ids_to_delete)
    end

    def environment_ids_per_not_passed_event
      series.events.reload.where('deployment_window_occurrences.finish_at > ?', Time.zone.now).pluck(:environment_id).uniq
    end

    def events_from_not_passed_occurrence
      series.occurrences.reload.where('deployment_window_occurrences.finish_at < ?', Time.zone.now).first.events
    end

    it 'de-associates environments from not passed occurrences events' do
      expect{delete}.to change{environment_ids_per_not_passed_event.count}.from(3).to(2)
    end

    it 'does not affect passed occurrences events' do
      expect{delete}.to_not change{events_from_not_passed_occurrence.count}
    end
  end

  describe '#delete_occurrences_not_finished_and_their_events' do
    let(:environments)              { create_list :environment, 3, :closed }
    let(:start_at)                  { Time.parse('7th Nov 2030 12:00').in_time_zone }
    let(:finish_at)                 { start_at + 2.days + 1.hour  }
    let(:start_at_from_the_past)    { Time.zone.now - 1.week }
    let(:finish_from_the_past)      { start_at_from_the_past + 1.day }
    let(:finish_from_the_future)    { Time.zone.now + 1.day }
    let(:environment_ids_to_delete) { [environments.last.id] }
    let(:prepared_params)           { {deployment_window_series: {recurrent: true}} }
    let(:series)                    { create :recurrent_deployment_window_series, environment_ids: environments.map(&:id),
                                             start_at: start_at, finish_at: finish_at, duration_in_days: 0 }

    before do
      create_occurrences_with_first_passed(prepared_params, series, start_at_from_the_past, finish_from_the_past)
    end

    def delete
      series.delete_occurrences_not_finished_and_their_events
    end

    it 'deletes occurrences from future and in-progress' do
      expect{delete}.to change{series.occurrences.count}.from(3).to(1)
    end

    it 'deletes events from not_passed occurrences' do
      expect{delete}.to change{series.events.count}.from(9).to(3)
    end
  end

  describe '#start_date_changed?' do
    let(:series) { build(:recurrent_deployment_window_series) }

    it 'returns true when one of dates is nil' do
      series.start_at = DateTime.now + 1.day
      expect(series.start_date_changed?).to be_truthy
    end

    context 'when both dates are nil' do
      before do
        series.stub(:start_at_change).and_return([nil, nil])
      end

      it 'returns true' do
        expect(series.start_date_changed?).to be_truthy
      end
    end

    context 'with previously set start date' do
      before do
        series.stub(:start_at_change).and_return([DateTime.now + 1.day, DateTime.now + 2.days])
      end
      it 'returns true when previous date does not equal current' do
        expect(series.start_date_changed?).to be_truthy
      end
    end

    context 'when both dates are equal' do
      before do
        series.stub(:start_at_change).and_return([DateTime.now + 1.day, DateTime.now + 1.day])
      end
      it 'returns false' do
        expect(series.start_date_changed?).to be_falsey
      end
    end
  end

  context 'denormalization' do
    let(:environments)                       { create_list :environment, 3, :closed }
    let(:series)                             { create :recurrent_deployment_window_series, :with_occurrences,
                                                      environment_ids: environments.map(&:id) }
    let(:event)                              { create :deployment_window_event, :with_allow_series }
    let(:attributes_for_series)              { FactoryGirl.attributes_for :recurrent_deployment_window_series, :with_occurrences }
    let(:deployment_window_series_construct) { DeploymentWindow::SeriesConstruct.new(attributes_for_series, series) }
    let(:request_params)                     { FactoryGirl.attributes_for(:request).merge(environment_id: create(:environment).id) }

    context '#environment_names' do
      before do
        deployment_window_series_construct.stub(:valid?).and_return(true)
        series.stub(:save).and_return(true)
        DeploymentWindow::SeriesBackgroundable.stub(:background).and_return(DeploymentWindow::SeriesBackgroundable)
      end

      let(:expected_value) { environments.map(&:name).sort.join(', ') }

      it 'precalculates and stores environment names' do
        series = deployment_window_series_construct.series
        series.stub(:environment_ids).and_return(environments.map(&:id))
        deployment_window_series_construct.create

        series.attributes['environment_names'].should == expected_value
      end
    end

    it 'increases requests count' do
      ActivityLog.stub(:log_event_with_user_readable_format)
      ActivityLog.stub(:inscribe)

      2.times {
        event.requests.build(request_params)
                      .tap { |r| r.requestor = create :user
                                 r.deployment_coordinator = create :user }
                      .save }

      event.series.reload.attributes['requests_count'].should == 2
    end
  end
end

# create occurrences for given series with:
# - first occurrence passed in time
# - second occurrence in-progress
# - third occurrence in future
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
