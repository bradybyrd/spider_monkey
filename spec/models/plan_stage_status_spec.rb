################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

require 'spec_helper'

describe PlanStageStatus do
  describe "validations" do

    before(:each) do
      @plan_stage_status = PlanStageStatus.new
      @sample_attributes = {
        :plan_stage_id => 1,
        :name => "On Hold"
      }
    end

    it "should create a new instance given valid attributes" do
      @plan_stage_status.update_attributes(@sample_attributes)
      @plan_stage_status.should be_valid
    end

    it "should require a plan_stage_id" do
      @sample_attributes[:plan_stage_id] = nil
      @plan_stage_status.update_attributes(@sample_attributes)
      @plan_stage_status.should_not be_valid
    end

    it "should require a name" do
      @sample_attributes[:name] = nil
      @plan_stage_status.update_attributes(@sample_attributes)
      @plan_stage_status.should_not be_valid
    end

    it "should require a unique name scoped to the plan_stage_id" do
      @plan_stage_status.update_attributes(@sample_attributes)
      @plan_stage_status.should be_valid
      @plan_stage_status2 = PlanStageStatus.new(@sample_attributes)
      @plan_stage_status2.should_not be_valid
      @plan_stage_status2.name = "New Name"
      @plan_stage_status2.should be_valid
      @plan_stage_status2.name = "On Hold"
      @plan_stage_status2.plan_stage_id = 2
      @plan_stage_status2.should be_valid
    end
  end

  describe "attribute normalizations" do
    it { should normalize_attribute(:name).from('  Hello  ').to('Hello') }
  end

end
