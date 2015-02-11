################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

require 'spec_helper'

describe PlanStageDate do

  describe "validations" do

    before(:each) do
      @plan_stage_date = create(:plan_stage_date)
    end

    it { should validate_presence_of(:plan_stage_id) }
    it { should validate_presence_of(:plan_id) }
    it { should validate_uniqueness_of(:plan_stage_id).scoped_to(:plan_id)}

  end

end
