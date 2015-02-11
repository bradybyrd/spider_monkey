################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

require 'spec_helper'

describe RequestPolicy::DeploymentWindowValidator::OpenedEnvironment do
  let(:scheduled_at)    { Time.now + 1.day }
  let(:estimate)        { 12 * 60 } # minutes
  let(:env_opened)      { build :environment, deployment_policy: 'opened' }
  let(:request)         { build :request }
  let(:dwe)             { build :deployment_window_event }
  let(:dws_prevent)     { create_deployment_window_series behavior: 'prevent', environment_ids: [env_opened.id] }
  let(:validator)       { RequestPolicy::DeploymentWindowValidator::OpenedEnvironment.new(request, false) }

  before { DeploymentWindow::SeriesConstruct.any_instance.stub(:dates_existing) }

  describe '#validate' do
    let(:request) { build :request, scheduled_at: scheduled_at, estimate: estimate }
    after { validator.send(:validate) }

    context 'on started request if request has estimate and scheduled_at, and is starting' do
      it 'should #check_if_valid_with_dwe if any deployment window exists on environment' do
        request.aasm_state    = 'started'
        request.environment   = env_opened # with preventing deployment window
        dws_prevent
        validator.should_receive(:check_for_dwe_dependencies)
      end
    end
  end

  describe '#requires_dwe_dependencies?' do
    let(:request) { build :request, environment: env_opened }

    context 'when request is starting' do
      before { validator.stub(:request_started?).and_return true }

      it 'should return true if any_preventing_dwe_exists' do
        validator.stub(:any_preventing_dwe_exists?).and_return true
        validator.requires_dwe_dependencies?.should be_truthy
      end

      it 'should return false unless any_preventing_dwe_exists?' do
        validator.stub(:any_preventing_dwe_exists?).and_return false
        validator.requires_dwe_dependencies?.should be_falsey
      end
    end

    context 'when request is not starting' do
      before { validator.stub(:request_started?).and_return false }

      it 'should return true if any_preventing_dwe_exists' do
        validator.stub(:any_preventing_dwe_exists?).and_return true
        validator.requires_dwe_dependencies?.should be_falsey
      end

      it 'should return false unless any_preventing_dwe_exists?' do
        validator.stub(:any_preventing_dwe_exists?).and_return false
        validator.requires_dwe_dependencies?.should be_falsey
      end
    end
  end

  describe '#any_preventing_dwe_exists?' do
    let(:dws_prevent)     { create_deployment_window_series environment_ids: [env_opened.id], behavior: 'prevent' }
    let(:request)         { build :request, environment: env_opened }

    it 'should return true' do
      expect(dws_prevent.events.preventing.count).to eq 1
      expect(validator.any_preventing_dwe_exists?).to be_truthy
    end

    it 'should return false' do
      expect(env_opened.deployment_window_events.preventing.count).to eq 0
      expect(validator.any_preventing_dwe_exists?).to be_falsey
    end
  end

  describe '#check_if_valid_with_dwe' do
    let(:request) { build :request, environment: env_opened }
    after { validator.check_if_valid_with_dwe }

    it 'should call #overlays_with_preventing_dwe if #overlays_with_preventing_dwe?' do
      validator.stub(:overlays_with_preventing_dwe?).and_return true
      validator.should_receive(:overlays_with_preventing_dwe!)
    end

    it 'should not call #overlays_with_preventing_dwe unless #overlays_with_preventing_dwe?' do
      validator.stub(:overlays_with_preventing_dwe?).and_return false
      validator.should_not_receive(:overlays_with_preventing_dwe!)
    end
  end

  describe '#overlays_with_preventing_dwe?' do
    let(:env_opened)  { create :environment, deployment_policy: 'opened' }
    let(:dws_prevent) { create_deployment_window_series environment_ids: [env_opened.id],
                               behavior: 'prevent', start_at: start, finish_at: finish }
    let(:request)     { build :request, environment: env_opened, scheduled_at: scheduled_at, estimate: 60 } # minutes

    context 'in case of overlaying' do
      let(:start)       { scheduled_at + 30.minutes }
      let(:finish)      { scheduled_at + 45.minutes }

      it 'should return `true` ' do
        expect(dws_prevent.events.count).to eq 1
        validator.overlays_with_preventing_dwe?.should be_truthy
      end

      it 'should return `false` if dwe is in draft ' do
        dws_prevent.aasm_state = 'draft'
        dws_prevent.save
        validator.overlays_with_preventing_dwe?.should be_falsey
      end

      it 'should return `false` if dwe is suspended ' do
        dws_prevent.events.update_all(state: DeploymentWindow::Event::SUSPENDED)
        validator.overlays_with_preventing_dwe?.should be_falsey
      end

      it 'should return `false` if request is not on the env preventing dwe is at' do
        request.environment = build :environment, deployment_policy: 'opened'
        expect(dws_prevent.events.first.environment).to_not eq request.environment
        expect(validator.overlays_with_preventing_dwe?).to be_falsey
      end
    end

    context 'in case of not overlaying before' do
      let(:start)       { scheduled_at - 45.minutes }
      let(:finish)      { scheduled_at - 5.minutes }

      it 'should return `false`' do
        expect(dws_prevent.events.count).to eq 1
        validator.overlays_with_preventing_dwe?.should be_falsey
      end
    end

    context 'in case of not overlaying after' do
      let(:start)       { scheduled_at + 65.minutes }
      let(:finish)      { scheduled_at + 95.minutes }

      it 'should return `false`' do
        expect(dws_prevent.events.count).to eq 1
        validator.overlays_with_preventing_dwe?.should be_falsey
      end
    end
  end

  describe 'deployment_window_event_suspended?' do
    it 'should return false with no dw' do
      validator.deployment_window_event_suspended?.should be_falsey
    end

    it 'should return false with dw' do
      validator.deployment_window_event_suspended?.should be_falsey
    end
  end


end

def create_deployment_window_series(*args, &block)
  series        = create :deployment_window_series, *args
  # params        = series.attributes
  construct     = DeploymentWindow::SeriesConstruct.new({}, series)
  construct.create
  series
end