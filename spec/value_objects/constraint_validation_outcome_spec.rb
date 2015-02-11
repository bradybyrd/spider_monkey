################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

require 'spec_helper'

describe ConstraintValidationOutcome do

  before :each do
    @double_candidate = double('Request')
    @double_governable = double('PlanStageInstance')
    @failure_message = 'Crimes against software.'
    @passed_cvo = ConstraintValidationOutcome.new(@double_governable,
                                                  @double_candidate, true)
    @failed_cvo = ConstraintValidationOutcome.new(@double_governable,
                                                  @double_candidate, false, @failure_message)
  end

  it 'should return passed true when passing' do
    @passed_cvo.passed.should be_truthy
  end

  it 'should return Passed as its message when passing' do
    @passed_cvo.message.should == 'Passed'
  end

  it 'should return passed false when failing' do
    @failed_cvo.passed.should be_falsey
  end

  it 'should return a failure notice as its message when failing' do
    @failed_cvo.message.should == @failure_message
  end

  it 'should provide access to the governable object' do
    @passed_cvo.governable.should == @double_governable
  end

  it 'should provide access to the governable object' do
    @passed_cvo.candidate.should == @double_candidate
  end

end

