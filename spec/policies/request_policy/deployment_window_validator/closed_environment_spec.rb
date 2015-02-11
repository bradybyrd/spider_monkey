################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

require 'spec_helper'

describe RequestPolicy::DeploymentWindowValidator::ClosedEnvironment do
  let(:scheduled_at)    { Time.now + 1.day }
  let(:estimate)        { 12 * 60 } # minutes
  let(:env_closed)      { create :environment, deployment_policy: 'closed' }
  let(:request)         { build :request }
  let(:dwe)             { build :deployment_window_event }
  let(:validator)       { RequestPolicy::DeploymentWindowValidator::ClosedEnvironment.new request, false }

  before { DeploymentWindow::SeriesConstruct.any_instance.stub(:dates_existing) }

  describe '#validate' do
    let(:request) { build :request, scheduled_at: scheduled_at, estimate: estimate }
    after { validator.send(:validate) }

    context 'on started request' do
      it 'should #check_if_valid_with_dwe if request on closed environment has estimate and scheduled_at, and is starting' do
        request.aasm_state    = 'started'
        request.environment   = env_closed
        validator.should_receive(:deployment_window_event_missing!)
      end
    end
  end

  describe '#requires_dwe_dependencies?' do
    it 'should return true if request in any state has a dwe' do
      request.deployment_window_event = dwe
      validator.requires_dwe_dependencies?.should be_truthy
    end

    it 'should return true if request is in any state on opened env with any preventing dwe' do
      validator.requires_dwe_dependencies?.should be_falsey
    end
  end

  describe '#requires_deployment_window_event?' do
    context 'request started' do
      before { validator.stub(:request_started?).and_return true }

      it 'should return true with env' do
        request.environment = env_closed
        validator.requires_deployment_window_event?.should be_truthy
      end

      it 'should return false without env' do
        request.environment = nil
        validator.requires_deployment_window_event?.should be_falsey
      end
    end

    context 'request not started' do
      before { validator.stub(:request_started?).and_return false }

      it 'should return false with env' do
        request.environment = env_closed
        validator.requires_deployment_window_event?.should be_falsey
      end

      it 'should return false without env' do
        request.environment = nil
        validator.requires_deployment_window_event?.should be_falsey
      end
    end
  end

  describe '#check_if_valid_with_dwe' do
    after { validator.check_if_valid_with_dwe }

    it 'should not perform validation if dwe is missing for request' do
      validator.should_not_receive :fits_to_allowing_dwe?
    end

    it 'should perform validation if dwe is present for request' do
      request.deployment_window_event = dwe
      validator.should_receive :fits_to_allowing_dwe?
    end

    it 'should call #fits_not_to_allowing_dwe! if dwe not valid for request' do
      request.deployment_window_event = dwe
      validator.stub(:fits_to_allowing_dwe?).and_return false
      validator.should_receive :fits_not_to_allowing_dwe!
    end
  end

  describe '#fits_to_allowing_dwe?' do
    let(:dwe)         { dws_allow.events.first }
    let(:dws_allow)   { create_deployment_window_series environment_ids: [env_closed.id], behavior: 'allow', start_at: start, finish_at: finish }
    let(:request)     { build :request, environment: env_closed, scheduled_at: scheduled_at, estimate: 60, deployment_window_event: dwe }

    context 'in case of fitting' do
      let(:start)       { scheduled_at - 5.minutes }
      let(:finish)      { scheduled_at + 65.minutes }

      it 'should return `true`' do
        expect(validator.fits_to_allowing_dwe?).to be_truthy
      end
    end

    context 'in case of not fitting finish' do
      let(:start)       { scheduled_at - 5.minutes }
      let(:finish)      { scheduled_at + 55.minutes }

      it 'should return `true`' do
        expect(validator.fits_to_allowing_dwe?).to be_falsey
      end
    end

    context 'in case of not fitting start' do
      let(:start)       { scheduled_at + 5.minutes }
      let(:finish)      { scheduled_at + 65.minutes }

      it 'should return `true`' do
        expect(validator.fits_to_allowing_dwe?).to be_falsey
      end
    end
  end

  describe 'deployment_window_event_suspended?' do
    let(:dwe_active)                    { build :deployment_window_event }
    let(:dwe_suspended)                 { build :deployment_window_event, state: DeploymentWindow::Event::SUSPENDED }
    let(:request_with_active_event)     { build :request, deployment_window_event: dwe_active }
    let(:request_with_suspended_event)  { build :request, deployment_window_event: dwe_suspended }
    let(:validator_with_active)         { RequestPolicy::DeploymentWindowValidator::ClosedEnvironment.new request_with_active_event, false }
    let(:validator_with_suspended)      { RequestPolicy::DeploymentWindowValidator::ClosedEnvironment.new request_with_suspended_event, false }

    it 'should return false with no dw' do
      validator.deployment_window_event_suspended?.should be_falsey
    end

    it 'should return false with dw active' do
      validator_with_active.deployment_window_event_suspended?.should be_falsey
    end

    it 'should return true with dw suspended' do
      validator_with_suspended.deployment_window_event_suspended?.should be_truthy
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
