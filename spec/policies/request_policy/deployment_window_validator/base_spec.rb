################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

require 'spec_helper'

describe RequestPolicy::DeploymentWindowValidator::Base do
  let(:scheduled_at)    { Time.now + 1.day }
  let(:estimate)        { 12 * 60 } # minutes
  let(:request)         { build :request }
  let(:env_closed)      { build :environment, deployment_policy: 'closed' }
  let(:env_opened)      { build :environment, deployment_policy: 'opened' }
  let(:request_policy)  { RequestPolicy::DeploymentWindowValidator::Base.new request }
  let(:validator_for_environment) { request_policy.validator_for_environment }

  describe '#validate' do
    after { validator_for_environment.send :validate }

    context 'request with estimate and scheduled_at' do
      let(:request) { build :request, scheduled_at: scheduled_at, estimate: estimate }

      describe 'if invalid data' do
        it 'add message' do
          estimate_error_msg = I18n.t('request.deployment_window.closed_environment.estimate_missing')
          schedule_error_msg = I18n.t('request.deployment_window.closed_environment.scheduled_at_missing')
          env = build(:environment, deployment_policy: 'closed')
          invalid_request = build(:request, scheduled_at: nil, estimate: nil, environment: env)
          policy = RequestPolicy::DeploymentWindowValidator::Base.new invalid_request
          policy.validator_for_environment.stub(:requires_dwe_dependencies?).and_return(true)
          policy.validator_for_environment.send(:validate)

          expect(policy.request.errors[:base]).to match_array [estimate_error_msg, schedule_error_msg]
          expect(policy.request).to have_notices
        end
      end

      describe 'on created request' do
        it 'should #check_if_valid_with_dwe if request is creating' do
          request.aasm_state    = 'created'
          validator_for_environment.should_receive(:validate_with_dwe)
        end
      end

      describe 'on planned request' do
        let(:request) { create :request, scheduled_at: scheduled_at, estimate: estimate }

        it 'should not #check_if_valid_with_dwe if request is going to planned' do
          request.aasm_state    = 'planned'
          validator_for_environment.should_not_receive(:validate_with_dwe)
        end

        it 'should #check_if_valid_with_dwe if request was already planned' do
          request.update_attributes aasm_state: 'planned'
          validator_for_environment.should_receive(:validate_with_dwe)
        end
      end

      describe 'on started request' do
        it 'should #check_if_valid_with_dwe' do
          request.aasm_state    = 'started'
          validator_for_environment.should_receive(:check_if_valid_with_dwe)
        end

        it 'should not #check_if_valid_with_dwe if no deployment window exists on environment' do
          request.aasm_state    = 'started'
          validator_for_environment.should_not_receive(:check_for_dwe_dependencies)
        end
      end
    end

    describe 'on request regardless state' do
      let(:request)         { build :request }

      it 'should #validate_with_dwe if #requires_dwe_dependencies?' do
        validator_for_environment.stub(:requires_dwe_dependencies?).and_return true
        validator_for_environment.should_receive(:check_for_dwe_dependencies)
      end

      it 'should #validate_with_dwe if #requires_deployment_window_event?' do
        validator_for_environment.stub(:requires_deployment_window_event?).and_return true
        validator_for_environment.should_receive(:deployment_window_event_missing!)
      end

      it 'should not #validate_with_dwe if request has only estimate' do
        request.estimate = estimate
        validator_for_environment.should_not_receive(:validate_with_dwe)
      end

      it 'should not #validate_with_dwe if request has only scheduled_at' do
        request.scheduled_at = scheduled_at
        validator_for_environment.should_not_receive(:validate_with_dwe)
      end
    end
  end

  describe '#check_for_dwe_dependencies' do
    after { validator_for_environment.send :check_for_dwe_dependencies }

    it 'should validate request for presence of estimate if dwe is present' do
      request.scheduled_at = scheduled_at
      validator_for_environment.should_receive :estimate_missing!
    end

    it 'should validate request for presence of scheduled_at if dwe is present' do
      request.estimate = estimate
      validator_for_environment.should_receive :scheduled_at_missing!
    end
  end

  describe '#validate_with_dwe' do
    let(:environment) {build :environment, name: Environment::DEFAULT_NAME }
    let(:request) { build :request, environment: environment }

    it 'should skip validation for default environment' do
      expect(request_policy.send(:validate_with_dwe)).to eq 'skipping validations'
    end
  end

  describe '#aasm_states_to_check? without ignoring states' do
    it 'should return true if request is created' do
      request.aasm_state = 'created'
      expect(request_policy.send(:aasm_states_to_check)).to be_truthy
    end

    it 'should return true if request is being planned' do
      request.aasm_state = 'planned'
      expect(request_policy.send(:aasm_states_to_check)).to be_falsey
    end

    it 'should return true if request was planned' do
      request.save # should be persisted
      request.update_attribute :aasm_state, 'planned'
      expect(request_policy.send(:aasm_states_to_check)).to be_truthy
    end

    it 'should return true if request is started' do
      request.aasm_state = 'started'
      expect(request_policy.send(:aasm_states_to_check)).to be_truthy
    end
  end

  describe '#aasm_states_to_check? with ignoring states' do
    let(:request_policy)  { RequestPolicy::DeploymentWindowValidator::Base.new request, ignore_states: true }
    after { expect(request_policy.send(:aasm_states_to_check)).to be_truthy }

    it 'should return true if request is created' do
      request.aasm_state = 'created'
    end

    it 'should return true if request is being planned' do
      request.aasm_state = 'planned'
    end

    it 'should return true if request was planned' do
      request.save(validate: false) # should be persisted
      request.update_attribute :aasm_state, 'planned'
    end

    it 'should return true if request is started' do
      request.aasm_state = 'started'
    end
  end

  describe '#request_started?' do
    it 'should return true if request is started' do
      request.aasm_state = 'started'
      expect(request_policy.send(:request_started?)).to be_truthy
    end

    it 'should return true if request is not started but with ignore_states' do
      request_policy      = RequestPolicy::DeploymentWindowValidator::Base.new request, ignore_states: true
      request.aasm_state  = 'planned'
      expect(request_policy.send(:request_started?)).to be_truthy
    end
  end

  describe '#validator_for_environment' do
    it 'should create closed environment validator_for_environment' do
      request_policy.send :validator_for_environment=, env_closed
      expect(request_policy.validator_for_environment).to be_an_instance_of RequestPolicy::DeploymentWindowValidator::ClosedEnvironment
    end

    it 'should create opened environment validator_for_environment' do
      request_policy.send :validator_for_environment=, env_opened
      expect(request_policy.validator_for_environment).to be_an_instance_of RequestPolicy::DeploymentWindowValidator::OpenedEnvironment
    end
  end

end
