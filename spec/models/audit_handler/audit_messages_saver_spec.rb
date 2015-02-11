################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

require 'spec_helper'

describe AuditHandler::AuditMessagesSaver do
  describe '.save' do
    let(:messages) {
      user = create :user
      step1 = create :step
      step2 = create :step
      [
        {auditable_id: step1.id, auditable_type: 'Step', user_id: user.id, user_type: 'User', action: 'create',
         audited_changes: step1.attributes, version: 1, created_at: Time.now},
        {auditable_id: step2.id, auditable_type: 'Step', user_id: user.id, user_type: 'User', action: 'update',
         audited_changes: {aasm_state: ['locked', 'ready']}, version: 1, created_at: Time.now}
      ]
    }

    it 'creates new audit records' do
      messages
      expect { AuditHandler::AuditMessagesSaver.send(:save, messages) }.to change { Audit.count }.by(2)
    end
  end
end
