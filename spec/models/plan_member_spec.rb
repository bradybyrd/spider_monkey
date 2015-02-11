################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################
require 'spec_helper'

describe PlanMember do

  describe "validations" do

    before(:each) do
      @plan_member = create(:plan_member)
    end

    it { should validate_presence_of(:plan_id) }

  end

  describe "named scopes" do
    before do
      @user = create(:user)
      User.stub(:current_user) { @user }
    end
    describe "#for_stage" do
      before(:each) do
        @plan = create(:plan)
        @plan_stage = create(:plan_stage, :plan_template => @plan.plan_template)
        @plan_member = create(:plan_member,
                                    :plan => @plan,
                                    :stage => @plan_stage)
        @plan_stage_not_to_be_found = create(:plan_stage, :plan_template => @plan.plan_template)
        @plan_member_not_to_be_found = create(:plan_member,
                                    :plan => @plan,
                                    :stage => @plan_stage_not_to_be_found)
      end

      it "should return all plan members for a particular plan stage" do
        PlanMember.for_stage(@plan_stage).should include(@plan_member)
      end

      it "should not return plans not linked to a particular plan stage" do
        PlanMember.for_stage(@plan_stage).should_not include(@plan_member_not_to_be_found)
      end
    end

    describe "#available_for" do
      before(:each) do
        @plan = create(:plan)
        @plan_stage = create(:plan_stage, :plan_template => @plan.plan_template)
        @plan_member = create(:plan_member,
                                    :plan => @plan,
                                    :stage => @plan_stage)
        @plan_not_to_be_found = create(:plan)
        @plan_member_not_to_be_found = create(:plan_member,
                                    :plan => @plan_not_to_be_found,
                                    :stage => @plan_stage)
      end

      it "should return all plan members for a particular plan" do
        PlanMember.available_for(@plan).should include(@plan_member)
      end

      it "should not return plans not matching the id" do
        PlanMember.available_for(@plan).should_not include(@plan_member_not_to_be_found)
      end
    end

    describe "#for_plans" do
      before(:each) do
        @plan = create(:plan)
        @plan2 = create(:plan)
        @plan_stage = create(:plan_stage, :plan_template => @plan.plan_template)
        @plan_stage2 = create(:plan_stage, :plan_template => @plan2.plan_template)
        @plan_member = create(:plan_member,
                                    :plan => @plan,
                                    :stage => @plan_stage)
        @plan_member2 = create(:plan_member,
                                    :plan => @plan2,
                                    :stage => @plan_stage2)
      end

      it "should return all plan members for a particular plan" do
        PlanMember.for_plans(@plan.id).should include(@plan_member)
      end

      it "should not return plans not included in the id set" do
        PlanMember.for_plans(@plan.id).should_not include(@plan_member2)
      end

      it "should return all plans if given an array of ids" do
        results = PlanMember.for_plans([@plan.id, @plan2.id])
        results.should include(@plan_member)
        results.should include(@plan_member2)
      end
    end

    describe "#for_requests" do
      before(:each) do
        @plan = create(:plan)
        @plan2 = create(:plan)
        @plan_stage = create(:plan_stage, :plan_template => @plan.plan_template)
        @plan_stage2 = create(:plan_stage, :plan_template => @plan2.plan_template)
        @plan_member = create(:plan_member,
                                    :plan => @plan,
                                    :stage => @plan_stage)
        @plan_member2 = create(:plan_member,
                                    :plan => @plan2,
                                    :stage => @plan_stage2)
        @request = create(:request, :plan_member => @plan_member)
        @request2 = create(:request, :plan_member => @plan_member2)
      end

      it "should return plan members for a particular request" do
        PlanMember.for_requests(@request.id).should include(@plan_member)
      end

      it "should not return plan members not included in the id set" do
        PlanMember.for_requests(@request.id).should_not include(@plan_member2)
      end

      it "should return all plan members if given an array of ids" do
        results = PlanMember.for_requests([@request.id, @request2.id])
        results.should include(@plan_member)
        results.should include(@plan_member2)
      end
    end

    describe "#for_request_aasm_state" do
      before(:each) do
        @plan = create(:plan)
        @plan2 = create(:plan)
        @plan_stage = create(:plan_stage, :plan_template => @plan.plan_template)
        @plan_stage2 = create(:plan_stage, :plan_template => @plan2.plan_template)
        @plan_member = create(:plan_member,
                                    :plan => @plan,
                                    :stage => @plan_stage)
        @plan_member2 = create(:plan_member,
                                    :plan => @plan2,
                                    :stage => @plan_stage2)

        @plan_member3 = create(:plan_member,
                                    :plan => @plan2,
                                    :stage => @plan_stage2)
        @request = create(:request, :plan_member => @plan_member)
        @request2 = create(:request, :plan_member => @plan_member2)
        @request2.plan_it!
        @request3 = create(:request, :plan_member => @plan_member3)
        create(:step, :request => @request3)
        @request3.plan_it!
        @request3.start!
        @request3.put_on_hold!
      end

      it "should return plan members for requests in a created aasm state" do
        PlanMember.for_request_aasm_state('created').should include(@plan_member)
      end

      it "should not return plan members from request not in this aasm states" do
        PlanMember.for_request_aasm_state('created').should_not include(@plan_member2)
        PlanMember.for_request_aasm_state('created').should_not include(@plan_member3)
      end

      it "should return all plan members if given an array of ids" do
        results = PlanMember.for_request_aasm_state(['created', 'hold'])
        results.should include(@plan_member)
        results.should include(@plan_member3)
      end
    end

    describe "#run_execution_order" do
      before(:each) do
        @plan = create(:plan)
        @plan_stage = create(:plan_stage, :plan_template => @plan.plan_template)
        @run = FactoryGirl.create(:run, :plan => @plan, :plan_stage => @plan_stage)
        @plan_member = create(:plan_member,
                                    :plan => @plan,
                                    :stage => @plan_stage,
                                    :run => @run,
                                    :position => 1)
        @plan_member2 = create(:plan_member,
                                    :plan => @plan,
                                    :stage => @plan_stage,
                                    :run => @run,
                                    :position => 2)
        @plan_member3 = create(:plan_member,
                                    :plan => @plan,
                                    :stage => @plan_stage,
                                    :run => @run,
                                    :position => 3)
        @request = create(:request, :plan_member => @plan_member)
        @request2 = create(:request, :plan_member => @plan_member2)
        @request2 = create(:request, :plan_member => @plan_member3)
      end

      it "should return plan members in execution order" do
        PlanMember.run_execution_order.first.should == @plan_member
        PlanMember.run_execution_order.last.should == @plan_member3
      end

      it "should reflect latest updates to position" do
        @plan_member2.move_to_top
        PlanMember.run_execution_order.first.should == @plan_member2
        PlanMember.run_execution_order.last.should == @plan_member3
      end
    end
  end



  # high level call from @plan that exercises a callback chain ending with "create_request_for_template in this class"
  # see next test for an experimental, mock based (partially), and more encapsulated approach
  describe "request creation for new plans (high dependency on call back chain working from plan)" do
    before(:each) do
      @user = create(:user)
      User.stub(:current_user).and_return(@user)
      @request_template_1 = create(:request_template, :request => create(:request))
      @request_template_2 = create(:request_template, :request => create(:request))
      @plan_template = create(:plan_template)
      @plan_stage = create(:plan_stage, :plan_template => @plan_template)
      @plan_stage.request_templates << [@request_template_1, @request_template_2]
      RequestTemplate.any_instance.stub(:create_request_for).and_return(create(:request))
      @plan = create(:plan, :plan_template => @plan_template)
    end
    it "should have the right number of members created through callbacks" do
      @plan.requests.count == 2
    end
  end

  # alternative test focusing on the local behavior and using mocks instead of full database objects: wip
  describe "request creation for new plans (encapsulated behavior)" do
    pending do
      before(:each) do
        @user = create(:user)
        User.stub(:current_user).and_return(@user)
        @request = mock_model(Request, :save => true)
        @request.stub('[]=').and_return(@request)
        @request_template = create(:request_template, :create_request_for => @request)
        @plan = create(:plan)
        @plan_stage = create(:plan_stage, :plan_template => @plan.plan_template)
        @plan_member = create(:plan_member,
                                      :plan => @plan,
                                      :stage => @plan_stage)
      end
      it "should have the right number of members created through callbacks" do
          @plan_member.create_request_for_template(@request_template).should == @request
      end
    end
  end

  describe "stage moving functions" do
    before(:each) do
      @plan = create(:plan)
      @plan_stage_1 = create(:plan_stage, :plan_template => @plan.plan_template)
      @plan_stage_2 = create(:plan_stage, :plan_template => @plan.plan_template)
      @plan_member = create(:plan_member,
                                    :plan => @plan,
                                    :stage => @plan_stage_1)
    end

    it "should be promotable to the next stage" do
      @plan_member.promote!
      @plan_member.reload
      @plan_member.stage.should == @plan_stage_2
    end

    it "should not be promotable if already on the bottom stage" do
      @plan_member.update_attributes(:stage => @plan_stage_2)
      @plan_member.promote!
      @plan_member.stage.should == @plan_stage_2
    end

    it "should be demotable to the previous stage" do
      @plan_member.update_attributes(:stage => @plan_stage_2)
      @plan_member.demote!
      @plan_member.stage.should == @plan_stage_1
    end

    it "should not be demotable if already on the top stage" do
      @plan_member.demote!
      @plan_member.stage.should == @plan_stage_1
    end

  end

  # FIXME: These tests need to be redone for new runs sorting abilities.
  # describe "reordering abilities" do
#
    # before(:each) do
      # @plan = create(:plan)
      # @plan_stage_1 = create(:plan_stage, :plan_template => @plan.plan_template)
      # @plan_stage_2 = create(:plan_stage, :plan_template => @plan.plan_template)
      # @plan_member = create(:plan_member,
                                    # :plan => @plan,
                                    # :stage => @plan_stage_1)
      # @plan_member_2 = create(:plan_member,
                                    # :plan => @plan,
                                    # :stage => @plan_stage_2)
      # @plan_member_3 = create(:plan_member,
                                    # :plan => @plan,
                                    # :stage => @plan_stage_2)
      # @plan_member_4 = create(:plan_member,
                                    # :plan => @plan,
                                    # :stage => @plan_stage_2)
#
      # @plan_foreign = create(:plan)
      # @plan_stage_foreign = create(:plan_stage, :plan_template => @plan_foreign.plan_template)
      # @plan_member_foreign = create(:plan_member,
                                    # :plan => @plan_foreign,
                                    # :stage => @plan_stage_foreign)
    # end
#
    # it "should be able to be reordered when passed a target plan member belonging to the same stage" do
      # @plan_member_2.move_to_member_or_stage(@plan_member_3.id).should == true
      # PlanMember.count(:conditions => {:plan_stage_id => @plan_stage_2.id, :plan_id => @plan.id}).should == 3
       # @plan_member_2.stage.should == @plan_stage_2
       # @plan_member_2.position.should == 2
       # @plan_member_2.higher_item.should == @plan_member_3
    # end
#
    # it "should be able to be reordered when passed a target plan member belonging to a new stage" do
      # @plan_member.move_to_member_or_stage(@plan_member_3.id).should == true
      # PlanMember.count(:conditions => {:plan_stage_id => @plan_stage_2.id, :plan_id => @plan.id}).should == 4
      # @plan_member.stage.should == @plan_stage_2
      # @plan_member.position.should == 2
      # @plan_member.higher_item.should == @plan_member_2
      # # FIXME: caching or some issue is blocking renumbering of lower down entries
    # end
#
    # it "should be able to be reordered when passed just a new stage" do
      # @plan_member.move_to_member_or_stage(nil, @plan_stage_2.id).should == true
      # @plan_member.stage.should == @plan_stage_2
      # @plan_member.position.should == 4
      # # FIXME: For some reason, I am having trouble getting this to go to the bottom when scope changes to a new stage
    # end
#
    # it "should prefer the member when passed both a target member and a new stage" do
      # @plan_member.move_to_member_or_stage(@plan_member_3.id, @plan_stage_foreign.id).should == true
      # @plan_member.stage.should == @plan_stage_2
    # end
#
    # it "should reject bad plan member ids" do
      # @plan_member.move_to_member_or_stage(939393939).should == true
      # @plan_member.stage.should be_nil
    # end
#
    # it "should reject bad stage ids" do
      # @plan_member.move_to_member_or_stage(nil, 9999999999).should == true
      # @plan_member.stage.should be_nil
    # end
#
    # it "should reject members different plans" do
      # @plan_member.move_to_member_or_stage(@plan_member_foreign.id).should == true
      # @plan_member.stage.should be_nil
    # end
#
    # it "should reject stages from different plans" do
      # @plan_member.move_to_member_or_stage(nil, @plan_stage_foreign.id).should == true
      # @plan_member.stage.should be_nil
    # end
#
    # it "should reject members and stages from different plans" do
      # @plan_member.move_to_member_or_stage(@plan_member_foreign.id, @plan_stage_foreign.id).should == true
      # @plan_member.stage.should be_nil
    # end
  # end
end
