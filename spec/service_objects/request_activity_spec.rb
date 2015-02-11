################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

require 'spec_helper'
include RequestActivity

describe ActivityMessage do
  let(:user) { create :user }
  let(:source_model) { create :step, name: 'Step', position: 1 }
  let(:activity_message ) { ActivityMessage.new(source_model, user) }

  describe '.activity_info' do
    it 'returns valid activity info instance' do
      expect(ActivityMessage.activity_info(source_model)).to be_a StepActivityInfo
    end
    it 'returns nil if wrong source model given' do
      expect(ActivityMessage.activity_info(Object.new)).to be_nil
    end
  end

  describe '#valid?' do
    it 'valid for source model with assigned request' do
      expect(activity_message.valid?).to be_truthy
    end

    context 'wrong source model' do
      let(:source_model) { Object.new }
      it 'should be invalid' do
        expect(activity_message.valid?).to be_falsey
      end
    end

    context 'source model without request' do
      let(:source_model) {
        step = create :step
        step.request_id = nil
        step
      }
      it 'should be invalid if request missed' do
        expect(activity_message.valid?).to be_falsey
      end
    end
  end

  describe '#attrs' do
    let (:attrs) { activity_message.attrs('test') }

    it 'returns attrs for mass insert' do
      expect(attrs).to include(user_id: user.id, activity: 'test')
      expect(attrs.keys).to include(:created_at, :usec_created_at)
    end
  end

  describe '#log_activity' do
    it 'publish activity with current timestamp' do
      activity_message.stub(:attrs).and_return('message')
      ActivityMessage.should_receive(:publish).with('message')
      activity_message.log_activity('test')
    end
  end

  describe '#log_state' do
    it 'logs activity' do
      activity_message.should_receive(:message_with_comments).and_return('message')
      activity_message.should_receive(:log_activity).with('message')
      activity_message.log_state('created')
    end
  end

  describe '#log_modification' do
    it 'logs activity' do
      activity_message.should_receive(:message_with_comments).and_return('message')
      activity_message.should_receive(:log_activity).with('message')
      activity_message.log_modification('created')
    end
  end

  describe '#message_with_comments' do
    it 'adds comments to message' do
      expect(activity_message.send(:message_with_comments, 'message', 'comments')).to eq 'message -- comments'
    end

    it 'returns message without comments if its nil' do
      expect(activity_message.send(:message_with_comments, 'message', nil)).to eq 'message'
    end
  end

  describe '#user_id' do
    it 'returns id for User instance' do
      expect(activity_message.send(:user_id)).to eq user.id
    end

    it 'returns user id if it is not User instance' do
      message = ActivityMessage.new(source_model, 1)
      expect(message.send(:user_id)).to eq 1
    end
  end
end

describe RequestActivityInfo do
  let(:request) { create :request }
  let(:activity) { RequestActivityInfo.new(request) }

  describe '#attrs' do
    it 'returns valid attrs hash' do
      expect(activity.attrs).to eq({request_id: request.id})
    end
  end

  describe '#state' do
    it 'returns valid request state' do
      expect(activity.state('created')).to eq 'Created'
    end
  end

  describe '#modification_prefix' do
    it 'returns valid message prefix' do
      expect(activity.modification_prefix).to eq 'Request modification'
    end
  end
end

describe StepActivityInfo do
  let(:step) { create :step, name: 'Step', position: 1 }
  let(:activity) { StepActivityInfo.new(step) }

  describe '#attrs' do
    it 'returns valid attrs hash' do
      expect(activity.attrs).to eq({request_id: step.request.id, step_id: step.id})
    end

    context 'step with no request' do
      before { step.stub(:request).and_return nil }

      it 'returns valid attrs hash' do
        expect(activity.attrs).to eq({request_id: nil, step_id: step.id})
      end
    end
  end

  describe '#state' do
    it 'returns valid request state' do
      expect(activity.state('ready')).to eq 'Step 1:  , Ready'
    end
  end

  describe '#modification_prefix' do
    it 'returns valid message prefix' do
      expect(activity.modification_prefix).to eq 'Step modification 1 : Step'
    end
  end

  context 'child step' do

  end
end

describe AuditActivityMessage do
  let(:user) { create :user }
  let(:source_model) { create :step, name: 'Step', position: 1 }
  let(:audit) {
    audit = Audit.new({action: 'create'})
    audit.user = user
    audit.auditable = source_model
    audit
  }
  let(:audit_message) { AuditActivityMessage.new audit }

  describe '#audit_model' do
    it 'init auditable model for activity log' do
      expect(audit_message.model).to be_a Step
    end
  end

  describe '#request_or_step?' do
    it 'returns true if record is related to step or request' do
      expect(audit_message.request_or_step?).to be_truthy
    end
  end

  describe '#activity_log_attrs' do
    it 'returns activity log attrs' do
      ActivityMessage.any_instance.should_receive(:modification_message).with(audit_message.comments).and_return('test')
      ActivityMessage.any_instance.should_receive(:attrs).with('test').and_return('attrs')
      expect(audit_message.activity_log_attrs).to eq 'attrs'
    end
  end
end