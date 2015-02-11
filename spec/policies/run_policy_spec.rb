################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

require 'spec_helper'

describe RunPolicy do
  let(:run) { build :run}
  let(:run_policy) { RunPolicy.new run }

  describe '#aasm_states_to_check' do
    it 'should return true if run is started' do
      run.aasm_state = 'started'
      expect(run_policy.aasm_states_to_check).to be_truthy
    end

    it 'should return true if run is going to be started' do
      run.aasm_event = 'start'
      expect(run_policy.aasm_states_to_check).to be_truthy
    end

    it 'should return true regardless run state if state should be ignored' do
      run_policy.stub(:ignore_states).and_return true
      expect(run_policy.aasm_states_to_check).to be_truthy
    end
  end

  describe '#validate_can_start' do
    it 'should receive #cannot_start!' do
      run_policy.stub(:requests_have_notices?).and_return true
      run_policy.stub(:aasm_states_to_check).and_return true
      run_policy.should_receive :cannot_start!
      run_policy.validate_can_start
    end
  end

end
