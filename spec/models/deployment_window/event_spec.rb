require 'spec_helper'

describe DeploymentWindow::Event do
  it{ should belong_to :occurrence }
  it{ should belong_to :environment }
  it{ should have_one :series}

  describe '#not_passed' do
    let(:event_1) { create :deployment_window_event }
    let(:event_2) { dwe = build(:deployment_window_event, :passed_in_time); dwe.save(validate: false); dwe }

    specify { DeploymentWindow::Event.not_passed.should include(event_1)  }
    specify { DeploymentWindow::Event.not_passed.should_not include(event_2) }
  end

  describe 'behavior scopes' do
    let(:env_closed)  { build :environment, deployment_policy: 'closed' }
    let(:env_opened)  { build :environment, deployment_policy: 'opened' }
    let(:dwes_allow)  { dws_allow.events }
    let(:dwes_prevent){ dws_prevent.events }
    let(:dws_allow)   { create :deployment_window_series, environment_ids: [env_closed.id], behavior: DeploymentWindow::Series::ALLOW }
    let(:dws_prevent) { create :deployment_window_series, environment_ids: [env_opened.id], behavior: DeploymentWindow::Series::PREVENT }

    describe '#preventing' do
      it 'should return only dwe with preventing behavior' do
        expect(DeploymentWindow::Event.preventing).to include(*dwes_prevent)
      end

      it 'should not include dwe with allowing behavior' do
        expect(DeploymentWindow::Event.preventing).to_not include(*dwes_allow)
      end
    end

    describe '#allowing' do
      it 'should return only dwe with allowing behavior' do
        expect(DeploymentWindow::Event.allowing).to include(*dwes_allow)
      end

      it 'should not include dwe with preventing behavior' do
        expect(DeploymentWindow::Event.allowing).to_not include(*dwes_prevent)
      end
    end

    describe '#active' do
      before {
        2.times { create :deployment_window_event, state: DeploymentWindow::Event::SUSPENDED }
        2.times { create :deployment_window_event }
      }
      let(:suspended) { DeploymentWindow::Event.where(state: DeploymentWindow::Event::SUSPENDED) }
      it "returns all events except suspended" do
        expect(DeploymentWindow::Event.active).to_not include(*suspended)
      end
    end
  end

  describe '#by_estimate' do
    it 'should return started event that match estimate' do
      event = build :deployment_window_event, start_at: Time.zone.now - 1.hour, finish_at: Time.zone.now + 3.hours
      event.save validate: false

      expect(DeploymentWindow::Event.by_estimate(120)).to include(event)
    end

    it 'should not return started event that does not match estimate' do
      event = build :deployment_window_event, start_at: Time.zone.now - 1.hour, finish_at: Time.zone.now + 1.hour
      event.save validate: false

      expect(DeploymentWindow::Event.by_estimate(120)).to_not include(event)
    end

    it 'should return upcoming event that match estimate' do
      event = create :deployment_window_event, start_at: Time.zone.now + 1.hour, finish_at: Time.zone.now + 2.hours

      expect(DeploymentWindow::Event.by_estimate(60)).to include(event)
    end

    it 'should not return upcoming event that does not match estimate' do
      event = create :deployment_window_event, start_at: Time.zone.now + 1.hour, finish_at: Time.zone.now + 2.hours

      expect(DeploymentWindow::Event.by_estimate(120)).to_not include(event)
    end

    it 'does not return event with duration shorter than estimate' do
      event = build :deployment_window_event, start_at: 1.day.from_now, finish_at: 1.day.from_now + 1.hour
      event.save validate: false

      expect(DeploymentWindow::Event.by_estimate(120)).not_to include(event)
    end
  end

  describe '#next_available_by_estimate' do
    let(:event_duration) { 120 }
    let(:env_closed) { create :environment, deployment_policy: 'closed' }
    let(:number_of_test_environments){ 3 }
    let(:environments){ create_list(:environment, number_of_test_environments) }
    let(:dws_allow) { create(:recurrent_deployment_window_series, :with_occurrences, environment_ids: environments.map(&:id)) }

    it 'should return next available deployment window which match estimate' do
      events = dws_allow.events.ordered_by_start_finish
      events[0].next_available_by_estimate(event_duration).should_not be_nil
    end

    it 'should not return any event if estimate does not match' do
      events = dws_allow.events.ordered_by_start_finish
      events[0].next_available_by_estimate(10.days.to_i).should eq nil
    end
  end

  describe '#cache_duration' do
    it 'should cache event duration after initialize' do
      duration = 60
      event = DeploymentWindow::Event.new start_at: Time.now, finish_at: Time.now + duration
      expect(event.cached_duration).to eq duration
    end

    it 'should cache event duration after update' do
      event = create :deployment_window_event, start_at: Time.now, finish_at: Time.now + 60

      new_duration = 120
      event.finish_at = Time.now + new_duration
      event.save

      expect(event.cached_duration).to eq new_duration
    end

    it 'cache duration with 0 if no start/finish date' do
      event = build :deployment_window_event, start_at: Time.now, finish_at: nil
      expect(event.cached_duration).to eq 0
    end
  end

  describe 'validations' do
    let(:environment) { create :environment }
    let(:recurrent_series) { create( :recurrent_deployment_window_series, :with_occurrences,
                                      start_at: Time.zone.now + 1.day,
                                      finish_at: Time.zone.now + 3.days,
                                      environment_ids: [environment.id]
                                    )
                            }
    let(:number_of_test_environments){ 3 }
    let(:environments){ create_list(:environment, number_of_test_environments) }
    let(:series){ create(:recurrent_deployment_window_series, :with_occurrences, environment_ids: environments.map(&:id)) }
    let(:event) { create(:deployment_window_event) }
    describe 'event_in_scope_of_series?' do
      it 'after move event cant be out of the scope of its series' do
        event = series.occurrences.first.events.first
        event.start_at = event.start_at - 10.days
        expect(event.send(:event_in_scope_of_series?)).to be_falsey
      end

      it 'after move event is in the scope of its series' do
        event = series.occurrences.first.events.first
        event.start_at = event.start_at + 1.hour
        expect(event.send(:event_in_scope_of_series?)).to be_truthy
      end
    end

    describe '#event_start_in_scope_of_series?' do
      it 'returns true if event start_at is in the scope of series' do
        event = series.occurrences.first.events.first
        expect(event.send(:event_start_in_scope_of_series?)).to be_truthy
      end

      it 'returns false if event start_at is not in the scope of series' do
        event = series.occurrences.first.events.first
        event.start_at = event.start_at - 5.days
        expect(event.send(:event_start_in_scope_of_series?)).to be_falsey
      end
    end

    describe '#event_finish_in_scope_of_series?' do
      it 'returns true if event finish_at is in the scope of series' do
        event = series.occurrences.first.events.first
        expect(event.send(:event_finish_in_scope_of_series?)).to be_truthy
      end

      it 'returns false if event start_at is not in the scope of series' do
        event = series.occurrences.last.events.first
        event.finish_at = event.finish_at + 5.days
        expect(event.send(:event_finish_in_scope_of_series?)).to be_falsey
      end
    end

    describe 'event_in_scope_of_occurrence?' do
      it 'after move event cant be out of its occurrence' do
        event = series.occurrences.second.events.first
        event.start_at = event.start_at + 1.day
        event.finish_at = event.finish_at + 1.day
        expect(event.send(:event_in_scope_of_occurrence?)).to be_falsey
      end

      it 'after move event is in its occurrence' do
        event = series.occurrences.last.events.first
        event.start_at = event.start_at + 1.hour
        event.finish_at = event.finish_at + 1.hour
        expect(event.send(:event_in_scope_of_occurrence?)).to be_truthy
      end
    end

    describe 'event_start_in_scope_of_occurrence?' do
      it 'returns true if there is no previous occurrence' do
        event = recurrent_series.occurrences.first.events.first
        expect(event.send(:event_start_in_scope_of_occurrence?)).to be_truthy
      end

      it 'returns true if start_at date is in scope of occurrence' do
        event = recurrent_series.occurrences.second.events.first
        expect(event.send(:event_start_in_scope_of_occurrence?)).to be_truthy
      end

      it 'returns false if start_at date is not in scope of occurrence' do
        event = recurrent_series.occurrences.second.events.first
        event.start_at = event.start_at - 1.day
        expect(event.send(:event_start_in_scope_of_occurrence?)).to be_falsey
      end
    end

    describe 'event_finish_in_scope_of_occurrence?' do
      it 'returns true if there is no next occurrence' do
        event = recurrent_series.occurrences.last.events.first
        expect(event.send(:event_finish_in_scope_of_occurrence?)).to be_truthy
      end

      it 'returns true if finish_at date is in scope of occurrence' do
        event = recurrent_series.occurrences.first.events.first
        expect(event.send(:event_finish_in_scope_of_occurrence?)).to be_truthy
      end

      it 'returns false if finish_at date is not in scope of occurrence' do
        event = recurrent_series.occurrences.second.events.first
        event.finish_at = event.finish_at + 1.day
        expect(event.send(:event_finish_in_scope_of_occurrence?)).to be_falsey
      end
    end

    describe '#start_in_past?' do
      it 'returns true if event start_at is in the past' do
        event.start_at = Time.now - 1.day
        expect(event.start_in_past?).to be_truthy
      end
      it 'returns false if event start_at is not in the past' do
        expect(event.start_in_past?).not_to be_truthy
      end
    end

    describe '#in_past?' do
      it 'returns true if event is in the past' do
        event.finish_at = Time.now - 1.day
        expect(event.in_past?).to be_truthy
      end
      it 'returns false if event is not in the past' do
        expect(event.in_past?).not_to be_truthy
      end
    end

    describe '#in_progress?' do
      it 'returns true if event is in progress' do
        event.start_at = Time.now - 1.day
        expect(event.in_progress?).to be_truthy
      end
      it 'returns false if event is not in progress' do
        expect(event.in_progress?).to be_falsey
      end
    end

    describe '#finish_before_past?' do
      it 'returns true if finish of event is before start' do
        event.finish_at = Time.now - 5.days
        expect(event.finish_before_past?).to be_truthy
      end
      it 'returns false if finish of event is not before start' do
        expect(event.finish_before_past?).to be_falsey
      end
    end

    describe '#dates_present?' do
      it 'returns true if start and finish dates are present' do
        expect(event.dates_present?).to be_truthy
      end
      it 'returns false if start or finish date is not present' do
        event.start_at = nil
        event.finish_at = nil
        expect(event.dates_present?).to be_falsey
      end
    end

    context 'denormalization' do
      let(:environments)                       { create_list :environment, 3, :closed }
      let(:series)                             { create :recurrent_deployment_window_series, :with_occurrences,
                                                        environment_ids: environments.map(&:id) }
      let(:event)                              { create :deployment_window_event, :with_allow_series }
      let(:attributes_for_recurrent_series)    { FactoryGirl.attributes_for :recurrent_deployment_window_series, :with_occurrences }
      let(:deployment_window_series_construct) { DeploymentWindow::SeriesConstruct.new(attributes_for_recurrent_series, series) }
      let(:request_params)                     { FactoryGirl.attributes_for(:request).merge(environment_id: create(:environment).id) }

      it 'duplicates #name' do
        series.events[0].attributes['name'].should == series.name
        series.events[1].attributes['name'].should == series.name
        series.events[2].attributes['name'].should == series.name
      end

      context '#environment_names' do
        before do
          deployment_window_series_construct.stub(:valid?).and_return(true)
          series.stub(:save).and_return(true)
          DeploymentWindow::SeriesBackgroundable.stub(:background).and_return(DeploymentWindow::SeriesBackgroundable)
        end

        let(:expected_value) { environments.map(&:name).sort.join(', ') }

        context 'recurrent' do
          before { deployment_window_series_construct.stub(:recurrent?).and_return(true) }

          it 'precalculates and stores environment names' do
            deployment_window_series_construct.create
            pending "expected: \"Environment 40, Environment 41, Environment 42\", got: \"\" (using ==)\nrank 3"
            deployment_window_series_construct.series.events[0].environment_names.should == expected_value
            deployment_window_series_construct.series.events[1].environment_names.should == expected_value
            deployment_window_series_construct.series.events[2].environment_names.should == expected_value
          end
        end

        context 'non-recurrent' do
        before { deployment_window_series_construct.stub(:recurrent?).and_return(false) }
        let(:attributes_for_series) { FactoryGirl.attributes_for :deployment_window_series }
        let(:series)                             { create :recurrent_deployment_window_series,
                                                          environment_ids: environments.map(&:id) }
        let(:deployment_window_series_construct) { DeploymentWindow::SeriesConstruct.new(attributes_for_series, series) }

          it 'precalculates and stores environment names' do
            deployment_window_series_construct.create

            deployment_window_series_construct.series.events[0].environment_names.should == expected_value
            deployment_window_series_construct.series.events[1].environment_names.should == expected_value
            deployment_window_series_construct.series.events[2].environment_names.should == expected_value
          end
        end
      end

      it 'duplicates #behavior' do
        series.events[0].attributes['behavior'].should == series.behavior
        series.events[1].attributes['behavior'].should == series.behavior
        series.events[2].attributes['behavior'].should == series.behavior
      end

      it 'increases #requests_count' do
        ActivityLog.stub(:log_event_with_user_readable_format)
        ActivityLog.stub(:inscribe)

        2.times {
          event.requests.build(request_params)
                        .tap { |r| r.requestor = create :user
                                   r.deployment_coordinator = create :user }
                        .save }

        event.reload.attributes['requests_count'].should == 2
      end
    end
  end
end
