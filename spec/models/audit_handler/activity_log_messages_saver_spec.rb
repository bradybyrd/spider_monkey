################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

require 'spec_helper'

describe AuditHandler::ActivityLogMessagesSaver do
  describe '.save' do
    let(:user) { create :user }
    let(:request) { create :request }
    let(:step) { create :step }

    it 'creates new activity log records' do
      messages = [
        {user_id: user.id, request_id: request.id, step_id: step.id, activity: 'test'},
        {user_id: user.id, request_id: request.id, activity: 'test'}
      ]
      expect { AuditHandler::ActivityLogMessagesSaver.send(:save, messages) }.to change { ActivityLog.count }.by(2)
    end

    it 'creates activity log from audit message' do
      step = create :step
      messages = [
        {'auditable_id' => step.id, auditable_type: 'Step', user_id: user.id, user_type: 'User', action: 'create',
         audited_changes: step.attributes, version: 1, created_at: Time.now}
      ]
      expect { AuditHandler::ActivityLogMessagesSaver.send(:save, messages) }.to change { ActivityLog.count }.by(1)
    end
  end
end