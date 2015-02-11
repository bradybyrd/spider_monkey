################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################
require 'spec_helper'

describe Run do

  before(:each) do
    @user = create(:user, :admin => true)
    User.stub(:current_user).and_return(@user)
  end

  describe "validations" do

    before(:each) do
    # uniqueness matcher needs one other record to test against
      @custom_run = FactoryGirl.create(:run)
      @run = Run.new
    end

    it { @run.should validate_presence_of(:name) }
    it { @run.should validate_presence_of(:requestor_id) }
    it { @run.should validate_presence_of(:owner_id) }
    it { @run.should validate_presence_of(:plan_id) }
    it { @run.should validate_uniqueness_of(:name).scoped_to(:plan_id, :plan_stage_id) }

    it "should reject names greater than 255 characters" do
      @custom_run.should be_valid
      @custom_run.name = "l" * 300
      @custom_run.should_not be_valid
    end

    it "should reject descriptions greater than 255 characters" do
      @custom_run.should be_valid
      @custom_run.description = "l" * 300
      @custom_run.should_not be_valid
    end

  end

  describe "request building and cloning hooks" do

    let(:plan) { create :plan }
    let(:plan_stage) { create :plan_stage, plan_template: plan.plan_template }
    let(:old_run) { create :run, plan: plan, plan_stage: plan_stage }
    let(:plan_member1) { create :plan_member, stage: plan_stage, plan: plan, run: old_run }
    let(:plan_member2) { create :plan_member, stage: plan_stage, plan: plan }
    let(:plan_member3) { create :plan_member, stage: plan_stage, plan: plan }
    let(:request1) { create :request, plan_member: plan_member1 }
    let(:request2) { create :request, plan_member: plan_member2 }
    let(:request3) { create :request, plan_member: plan_member3 }

    it "should make a simple assignment for requests not already in assigned to a run" do
      new_run = create(:run, :plan => plan, :plan_stage => plan_stage, :request_ids => [request2.id])
      new_run.reload
      new_run.requests.first.should == request2
      new_run.plan_members.first.should == plan_member2
    end

    it "should leave already assigned runs alone and clone them instead" do
      pending 'wrong number of arguments calling `dup` (1 for 0)'
      new_run = create(:run, :plan => plan, :plan_stage => plan_stage, :request_ids => [request1.id])
      new_run.reload
      # it should not have grabbed request one because it belonged to old_run
      new_run.requests.first.should_not == request1
      # but it should have a request with the same title and plan assignments details
      new_run.requests.first.name.should == request1.name
      new_run.requests.first.plan.should == request1.plan
      new_run.requests.first.plan_member.stage.should == request1.plan_member.stage
      # and it should have created a template and a frozen request along the way to support it
      RequestTemplate.count.should == 1
      Request.find_by_request_template_id(RequestTemplate.first).should_not be_nil
    end

    describe "handling a mix of old and new requests" do
      let(:new_run) { create :run,
                             plan: plan,
                             plan_stage: plan_stage,
                             request_ids: [ request1.id, request3.id ] }

      let(:cloned_request) { new_run.reload.requests.find_by_name request1.name }

      it 'doesn\'t have grabbed request because it belongs to old_run' do
        cloned_request.should_not eq request1
      end

      it 'makes a clone from template' do
        cloned_request.created_from_template.should eq true
      end

      # and for the second one a simple test to make sure it was assigned
      it 'assigns the second request' do
        new_run.requests.find_by_name(request3.name).should eq request3
      end
    end
  end

  describe "attribute normalizations" do
    it { should normalize_attribute(:name).from('  Hello  ').to('Hello') }
    it { should normalize_attribute(:description).from('  Hello  ').to('Hello') }
  end

  describe "named scopes" do
    describe "#blocked" do
      it "should return all runs in a blocked state" do
        run = create(:run, :aasm_state => 'blocked')
        Run.blocked.should include(run)
      end

      it "should not return runs in a created state" do
        run = create(:run, :aasm_state => 'created')
        Run.blocked.should_not include(run)
      end
    end

    describe "#deleted" do
      it "should return all runs in a deleted state" do
        run = create(:run, :aasm_state => 'cancelled')
        run.delete!
        Run.deleted.should include(run)
      end
      it "should not return runs in a created state" do
        run = create(:run, :aasm_state => 'created')
        Run.deleted.should_not include(run)
      end
    end

    describe "#not_deleted" do
      it "should return all runs in a not deleted state" do
        run = create(:run, :aasm_state => 'created')
        run2 = create(:run, :aasm_state => 'blocked')
        run3 = create(:run, :aasm_state => 'started')
        Run.not_deleted.should include(run)
        Run.not_deleted.should include(run2)
        Run.not_deleted.should include(run3)
      end
      it "should not return runs in a deleted state" do
        run = create(:run, :aasm_state => 'cancelled')
        run.delete!
        Run.not_deleted.should_not include(run)
      end
    end

    describe "#functional" do
      it "should return all runs in a functional (not deleted) state" do
        run = create(:run, :aasm_state => 'created')
        Run.functional.should include(run)
      end
      it "should not return runs in a deleted state" do
        run = create(:run, :aasm_state => 'cancelled')
        run.delete!
        Run.functional.should_not include(run)
      end
    end

    describe "#mutable" do
      it "should return all runs in a mutable (created or planned) state" do
        run_created = create(:run, :aasm_state => 'created')
        run_planned = create(:run, :aasm_state => 'planned')
        run2 = create(:run, :aasm_state => 'completed')
        run3 = create(:run, :aasm_state => 'deleted')
        run4 = create(:run, :aasm_state => 'cancelled')
        run5 = create(:run, :aasm_state => 'blocked')
        run6 = create(:run, :aasm_state => 'held')
        run7 = create(:run, :aasm_state => 'started')
        results = Run.mutable
        results.should include(run_created)
        results.should include(run_planned)
        results.should_not include(run2)
        results.should_not include(run3)
        results.should_not include(run4)
        results.should_not include(run5)
        results.should_not include(run6)
        results.should_not include(run7)
      end
    end

    describe "#by_start_at_day" do
      before(:each) do
        @time = Time.now
      end
      it "should return all runs on a particular start date" do
        run = create(:run, :start_at => @time )
        Run.by_start_at_day(@time).should include(run)
      end
      it "should not return runs that do not have a matching start date" do
        run = create(:run, :start_at => Time.now + 2.days)
        Run.by_start_at_day(@time).should_not include(run)
      end
    end

    describe "#by_end_at_day" do
      before(:each) do
        @time = Time.now
      end
      it "should return all runs on a particular end date" do
        run = create(:run, :end_at => @time )
        Run.by_end_at_day(@time).should include(run)
      end
      it "should not return runs that do not have a matching end date" do
        run = create(:run, :end_at => Time.now + 2.days)
        Run.by_end_at_day(@time).should_not include(run)
      end
    end

    describe "#by_time" do
      before(:each) do
        @time = Time.now
      end
      it "should return all runs that include a particular time between start and end" do
        run = create(:run, :start_at => @time - 2.days, :end_at => @time + 2.days )
        Run.by_time(@time).should include(run)
      end
      it "should not return runs that do not include a particular time between start and end" do
        run = create(:run, :start_at => @time - 4.days, :end_at => @time - 2.days)
        Run.by_time(@time).should_not include(run)
      end
    end

    describe "#by_uppercase_name" do
      it "should return all runs with a case insensitive name match" do
        run = create(:run, :name => "Test Camel Case Name")
        Run.by_uppercase_name("test camel case name").first.name == 'Test Camel Case Name'
      end
    end

    describe "#by_aasm_state" do
      it "should return all runs included in a set of aasm states" do
        run1 = create(:run, :aasm_state => 'created')
        run2 = create(:run, :aasm_state => 'blocked')
        results = Run.by_aasm_state("created")
        results.should include(run1)
        results.should_not include(run2)
        results.count.should == 1
        # test the filtered method too
        results = Run.filtered({:aasm_state => ['blocked']})
        results.should include(run2)
        results.should_not include(run1)
      end
    end

    describe "#by_owner" do
      it "should return all runs linked to a particular set of releases" do
        owner1 = create(:user)
        owner2 = create(:user)
        run1 = create(:run, :owner => owner1)
        run2 = create(:run, :owner => owner2)
        results = Run.by_owner([owner1.id])
        results.should include(run1)
        results.should_not include(run2)
        results.count.should == 1
        results = Run.by_owner([owner1.id, owner2.id])
        results.count.should == 2
        # test the filtered method too
        results = Run.filtered({:owner_id => [owner1.id]})
        results.should include(run1)
        results.should_not include(run2)
      end
    end

    describe "#by_requestor" do
      it "should return all runs linked to a particular set of releases" do
        requestor1 = create(:user)
        requestor2 = create(:user)
        run1 = create(:run, :requestor => requestor1)
        run2 = create(:run, :requestor => requestor2)
        results = Run.by_requestor([requestor1.id])
        results.should include(run1)
        results.should_not include(run2)
        results.count.should == 1
        results = Run.by_requestor([requestor1.id, requestor2.id])
        results.count.should == 2
        # test the filtered method too
        results = Run.filtered({:requestor_id => [requestor1.id]})
        results.should include(run1)
        results.should_not include(run2)
      end
    end

    describe "#by_stage" do
      it "should return runs with a particular stage" do
        plan_template1 = create(:plan_template, :template_type => 'continuous_integration')
        plan_stage1 = create(:plan_stage, :plan_template => plan_template1)
        plan_stage2 = create(:plan_stage, :plan_template => plan_template1)
        run1 = create(:run, :plan_stage => plan_stage1, :aasm_state => "created")
        run2 = create(:run, :plan_stage => plan_stage2, :aasm_state => "created")
        plan_template2 = create(:plan_template, :template_type => 'continuous_integration')
        plan_stage3 = create(:plan_stage, :plan_template => plan_template2)
        run3 = create(:run, :plan_stage => plan_stage3, :aasm_state => "created")
        results = Run.by_stage([plan_stage1.id])
        results.count.should == 1
        results.should include(run1)
        results.should_not include(run2)
        results.should_not include(run3)
        results = Run.by_stage([plan_stage1.id, plan_stage2.id])
        results.should include(run1)
        results.should include(run2)
        results.should_not include(run3)
        results.all.size.should == 2
      end
    end

    describe "#by_plan_ids" do
      it "should return runs with a particular plan" do
        plan_template1 = create(:plan_template, :template_type => 'continuous_integration')
        plan1 = create(:plan, :plan_template => plan_template1)
        plan_stage1 = create(:plan_stage, :plan_template => plan_template1)
        plan_stage2 = create(:plan_stage, :plan_template => plan_template1)
        run1 = create(:run, :plan_stage => plan_stage1, :plan => plan1, :aasm_state => "created")
        run2 = create(:run, :plan_stage => plan_stage2, :plan => plan1,  :aasm_state => "created")
        plan_template2 = create(:plan_template, :template_type => 'continuous_integration')
        plan2 = create(:plan, :plan_template => plan_template2)
        plan_stage3 = create(:plan_stage, :plan_template => plan_template2)
        run3 = create(:run, :plan_stage => plan_stage3, :plan => plan2, :aasm_state => "created")
        results = Run.by_plan_ids([plan1.id])
        results.count.should == 2
        results.should include(run1)
        results.should include(run2)
        results.should_not include(run3)
        results = Run.by_plan_ids([plan1.id, plan2.id])
        results.should include(run1)
        results.should include(run2)
        results.should include(run3)
        results.all.size.should == 3
      end
    end
  end

  # because there is so much state needed for some of these named scopes to work
  # I wove most of the correct params cases into the named scoped tests above,
  # but here are some nil, etc. edge cases that should exercise the whole function
  describe "filter method edge cases" do
    before(:each) do
      @run1 = create(:run, :aasm_state => 'created')
      @run2 = create(:run, :aasm_state => 'deleted')
    end

    it "should return all functional runs when sent nothing" do
      results = Run.filtered
      results.should include(@run1)
      results.should_not include(@run2)
    end

    it "should return all functional runs when sent an empty object" do
      results = Run.filtered({})
      results.should include(@run1)
      results.should_not include(@run2)
    end

    it "should return all functional runs when sent a filter object with irrelevant fields" do
      results = Run.filtered({:random_sample_field => "[3,3,4,5]"})
      results.should include(@run1)
      results.should_not include(@run2)
    end

    it "should return an empty array, not an error, when sent a filter object with unfindable data" do
      results = Run.filtered({:aasm_state => ["completed"]})
      results.should be_empty
    end
  end

  describe "transitions" do
    before do
      plan_template = create(:plan_template, :template_type => 'continuous_integration')
      plan = create(:plan, :plan_template => plan_template)
      plan_stage = create(:plan_stage, :plan_template => plan_template)
      @run = create(:run, :plan => plan, :plan_stage => plan_stage)
      plan_member1 = create(:plan_member, :run => @run, :stage => plan_stage, :plan => plan)
      plan_member2 = create(:plan_member, :run => @run, :stage => plan_stage, :plan => plan)
      plan_member3 = create(:plan_member, :run => @run, :stage => plan_stage, :plan => plan)
      @request1 = create(:request, :plan_member => plan_member1)
      @request2 = create(:request, :plan_member => plan_member2)
      @request3 = create(:request, :plan_member => plan_member3)
      create(:step, :request => @request3)
    end

    describe "#plan_it!" do
      it "should transition the run from its default created state to planned" do
        @run.plan_it!
        @run.should be_planned
      end
      it "should transition the run from cancelled to planned" do
        @run.update_attribute(:aasm_state, "cancelled")
        @run.plan_it!
        @run.should be_planned
      end
      it "should transition the run from cancelled to planned using a restful attribute update" do
        @run.update_attributes(:aasm_event =>"plan_it")
        @run.should be_planned
      end
      it "should put eligible requests into the planned state" do
        @request1.should be_created
        @request2.should be_created
        @request3.plan_it!
        @request3.start!
        @request3.finish!
        @run.requests.find(@request3.id).should be_complete
        @run.plan_it!
        @run.requests.find(@request1.id).should be_planned
        @run.requests.find(@request2.id).should be_planned
        @run.requests.find(@request3.id).should be_complete
      end
    end

    describe "#start!" do
      it "should transition the run from planned to started" do
        @run.update_attribute(:aasm_state, "planned")
        @run.start!
        @run.should be_started
      end
      it "should transition the run from planned to started using a restful attribute update" do
        @run.update_attribute(:aasm_state, "planned")
        @run.update_attributes(:aasm_event =>"start")
        @run.should be_started
      end
      it "should transition the run from hold to started" do
        @run.update_attribute(:aasm_state, "held")
        @run.start!
        @run.should be_started
      end
      it "should transition the run from hold to started using a restful attribute update" do
        @run.update_attribute(:aasm_state, "held")
        @run.update_attributes(:aasm_event =>"start")
        @run.should be_started
      end
      it "should put eligible requests into the started state and complete when they are all finished" do
        @request1.should be_created
        @request2.should be_created
        @request3.should be_created
        @run.plan_it!
        @request1.reload
        @request2.reload
        @request3.reload
        @request1.should be_planned
        @request2.should be_planned
        @request3.should be_planned
        @run.start!
        @request1.reload
        @request2.reload
        @request3.reload
        @request1.should be_complete
        @request2.should be_complete
        @request3.finish!
        @request3.should be_complete
        @run.reload
        @run.should be_completed
      end

    end

    describe "#block!" do
      it "should transition the run from started to blocked" do
        @run.update_attribute(:aasm_state, "started")
        @run.block!
        @run.should be_blocked
      end
      it "should transition the run from started to blocked using a restful attribute update" do
        @run.update_attribute(:aasm_state, "started")
        @run.update_attributes(:aasm_event =>"block")
        @run.should be_blocked
      end
      # FIXME: Have to wait until requests are more stable to confirm
      it "should respond to hold in a request by moving to blocked" do
        # @run.plan_it!
        # @run.start!
        # @request1.reload
        # @request1.should be_started
        # @request1.put_on_hold!
        # @request1.reload
        # @request1.should be_hold
        # @run.check_status
        # @run.reload
        # @run.should be_blocked
      end
    end

    describe "#complete!" do
      it "should transition the run from started to finished" do
        @run.update_attribute(:aasm_state, "started")
        @run.complete!
        @run.should be_completed
      end
      it "should transition the run from started to finished using a restful attribute update" do
        @run.update_attribute(:aasm_state, "started")
        @run.update_attributes(:aasm_event =>"complete")
        @run.should be_completed
      end
    end

    describe "#hold!" do
      it "should transition the run from started to hold" do
        @run.update_attribute(:aasm_state, "started")
        @run.hold!
        @run.should be_held
      end
      it "should transition the run from started to hold using a restful attribute update" do
        @run.update_attribute(:aasm_state, "started")
        @run.update_attributes(:aasm_event =>"hold")
        @run.should be_held
      end
    end

    describe "#cancel!" do
      it "should transition the run from created to cancelled" do
        @run.update_attribute(:aasm_state, "created")
        @run.cancel!
        @run.should be_cancelled
      end
      it "should transition the run from created to cancelled using a restful attribute update" do
        @run.update_attribute(:aasm_state, "created")
        @run.update_attributes(:aasm_event =>"cancel")
        @run.should be_cancelled
      end
      it "should transition the run from planned to cancelled" do
        @run.update_attribute(:aasm_state, "planned")
        @run.cancel!
        @run.should be_cancelled
      end
      it "should transition the run from planned to cancelled using a restful attribute update" do
        @run.update_attribute(:aasm_state, "planned")
        @run.update_attributes(:aasm_event =>"cancel")
        @run.should be_cancelled
      end
      it "should transition the run from hold to cancelled" do
        @run.update_attribute(:aasm_state, "held")
        @run.cancel!
        @run.should be_cancelled
      end
      it "should transition the run from hold to cancelled using a restful attribute update" do
        @run.update_attribute(:aasm_state, "held")
        @run.update_attributes(:aasm_event =>"cancel")
        @run.should be_cancelled
      end
      it "should transition the run from started to cancelled" do
        @run.update_attribute(:aasm_state, "started")
        @run.cancel!
        @run.should be_cancelled
      end
      it "should transition the run from started to cancelled using a restful attribute update" do
        @run.update_attribute(:aasm_state, "started")
        @run.update_attributes(:aasm_event =>"cancel")
        @run.should be_cancelled
      end
      it "should transition the run from started to cancelled" do
        @run.update_attribute(:aasm_state, "blocked")
        @run.cancel!
        @run.should be_cancelled
      end
      it "should transition the run from started to cancelled using a restful attribute update" do
        @run.update_attribute(:aasm_state, "blocked")
        @run.update_attributes(:aasm_event =>"cancel")
        @run.should be_cancelled
      end
    end

    describe '#delete!' do
      it 'should transition the run from cancelled to deleted' do
        @run.update_attribute(:aasm_state, 'cancelled')
        @run.delete!
        expect(@run).to be_deleted
      end
      it 'should transition the run from created to deleted' do
        @run.update_attribute(:aasm_state, 'created')
        @run.delete!
        expect(@run).to be_deleted
      end
      it 'should transition the run from completed to deleted' do
        @run.update_attribute(:aasm_state, 'completed')
        @run.delete!
        expect(@run).to be_deleted
      end
      it 'should nullify related plan members after deletion' do
        plan_template = create(:plan_template, template_type: 'continuous_integration')
        plan = create(:plan, plan_template: plan_template)
        plan_stage = create(:plan_stage, plan_template: plan_template)
        run = create(:run, plan_stage: plan_stage, plan: plan, aasm_state: 'created')
        plan_member1 = create(:plan_member, run: run, stage: plan_stage, plan: plan)
        plan_member2 = create(:plan_member, run: run, stage: plan_stage, plan: plan)
        request1 = create(:request, plan_member: plan_member1)
        request2 = create(:request, plan_member: plan_member2)
        expect(run.plan_members.count).to eq(2)
        run.delete!
        expect(run).to be_deleted
        expect(run.plan_members.count).to eq(0)
        expect(PlanMember.where(run_id: run.id).count).to eq(0)
      end
    end

    describe "restful attribute method should give good error messages" do
      it "should invalidate the model when an unsupported event is submitted" do
        @run.update_attribute(:aasm_state, "created")
        @run.update_attributes(:aasm_event =>"INVALID")
        @run.should be_created
        @run.should_not be_valid
        @run.errors[:aasm_event].should == ["was not included in supported events: plan_it, start, block, hold, complete, cancel, and delete."]
      end
      it "should invalidate the model when a invalid transition is submitted" do
        @run.update_attribute(:aasm_state, "planned")
        @run.update_attributes(:aasm_event =>"hold")
        @run.should be_planned
        @run.should_not be_valid
        @run.errors[:aasm_event].should == ["was not a valid transition for current state: planned."]
      end
    end

    describe "select list of status fields" do
      it "should provide a select list" do
        Run.status_filters_for_select.should == [["Created", "created"], ["Planned", "planned"], ["Started", "started"], ["Held", "held"], ["Blocked", "blocked"], ["Completed", "completed"], ["Cancelled", "cancelled"], ["Deleted", "deleted"]]
      end
    end
  end

  describe 'convenience methods' do
    before(:each) do
      @run = Run.new(:start_at => start_at, :end_at => end_at, :description => 'An early morning smoke test.')
    end

    let(:start_at) { Time.zone.now }
    let(:end_at) { Time.zone.now + 2.days }

    it 'should provide a date label with both dates present' do
      pending 'to be fixed in custom roles release'

      @run.date_label.should == "#{start_at.try(:default_format_date)} <-> #{end_at.try(:default_format_date)}"
    end

    it 'should provide a date label with only start at present' do
      pending 'to be fixed in custom roles release'

      @run.end_at = nil
      @run.date_label.should == "#{start_at.try(:default_format_date)} <-> --"
    end

    it 'should provide a date label with only end at present' do
      pending 'to be fixed in custom roles release'

      @run.start_at = nil
      @run.date_label.should == "-- <-> #{end_at.try(:default_format_date)}"
    end

    it 'should provide a date label with no date present' do
      @run.start_at = nil
      @run.end_at = nil
      @run.date_label.should == '-- <-> --'
    end
  end

  describe '#filtered' do

    before(:all) do
      Run.delete_all

      @owner = create(:user)
      @requestor = create(:user)

      #template_type: 'continuous_integration', 'deploy', 'release_plan'
      @plan_template = create(:plan_template, :template_type => 'deploy')
      @plan_stage = create(:plan_stage, :plan_template => @plan_template)


      yesterday_1                   = '2013-04-23 14:15:01 UTC'
      @yesterday_2                  = '2013-04-23 16:25:01 UTC'
      yesterday_end_strict_2        = '2013-04-23 23:59:59.999999999999 UTC'
      @today_start_strict           = '2013-04-24 00:00:00 UTC'
      @today                        = '2013-04-24 14:15:01 UTC'
      @tomorrow                     = '2013-04-25 14:15:01 UTC'
      after_tomorrow_start_strict   = '2013-04-26 00:00:00 UTC'


      @run_1 = create_run(:name => 'Default run', :start_at => yesterday_1, :end_at => @today)

      #aasm: 'created', 'planned', 'started', 'locked', 'complete', 'archived', 'hold', 'cancelled', 'deleted'
      @run_2 = create_run(:name => 'Run #1', :aasm_state => 'planned', :plan_stage => @plan_stage,
                          :owner => @owner, :requestor => @requestor,
                          :start_at => yesterday_end_strict_2, :end_at => after_tomorrow_start_strict)

      @run_3 = create_run(:name => 'Run #2', :aasm_state => 'deleted')
    end

    after(:all) do
      Run.delete_all
      PlanStage.delete([@plan_stage])
      PlanTemplate.delete([@plan_template])
      User.delete([@owner, @requestor])
    end

    describe 'filter by default' do
      subject { described_class.filtered }
      it { should match_array([@run_1, @run_2]) }
    end

    describe 'filter by name, aasm_state, stage_id, owner_id, requestor_id' do
      subject { described_class.filtered(:name => 'Run #1', :aasm_state => 'planned', :stage_id => @plan_stage.id,
                                         :owner_id => @owner.id, :requestor_id => @requestor.id) }
      it { should match_array([@run_2]) }
    end

    describe 'filter by aasm_state' do
      subject { described_class.filtered(:aasm_state => ['planned', 'deleted']) }
      it { should match_array([@run_2, @run_3]) }
    end

    describe 'filter by start_at empty' do
      subject { described_class.filtered(:start_at => @today) }
      it { should be_empty }
    end

    describe 'filter by end_at empty' do
      subject { described_class.filtered(:end_at => @tomorrow) }
      it { should be_empty }
    end

    describe 'filter by start_at' do
      subject { described_class.filtered(:start_at => @yesterday_2) }
      it { should match_array([@run_1, @run_2]) }
    end

    describe 'filter by end_at' do
      subject { described_class.filtered(:end_at => @today_start_strict) }
      it { should match_array([@run_1]) }
    end

    describe 'filter by time' do
      subject { described_class.filtered(:time => @yesterday_2) }
      it { should match_array([@run_1]) }
    end
  end

  describe '#validate_can_start' do
    let(:run) { build :run }
    let(:run_policy) { mock 'policy' }

    it 'should call validate_can_start on its policy object' do
      RunPolicy.stub(:new).with(run).and_return run_policy
      run_policy.should_receive(:validate_can_start)
      run.send :validate_can_start
    end
  end

  describe '#requests_have_notices?' do
    let(:run)       { build :run, requests: requests }
    let(:requests)  { create_list(:request, 2) }

    specify { run.should be_valid }

    it 'should return false' do
      expect(run.requests_have_notices?).to be_falsey
    end

    it 'should return true' do
      requests.last.stub(:has_notices?).and_return true
      expect(run.requests_have_notices?).to be_truthy
    end
  end

  describe '#requests_notices_message' do
    let(:run)       { build :run, requests: requests }
    let(:requests)  { create_list(:request, 2) }

    specify { run.should be_valid }

    it 'should return nil' do
      expect(run.requests_notices_message).to be_nil
    end

    it 'should return error message' do
      requests.last.stub(:has_notices?).and_return true
      requests.last.stub(:notices).and_return %w(jingle bells)
      expect(run.requests_notices_message).to_not be_empty
    end
  end

  protected

  def create_run(options = nil)
    create(:run, options)
  end
end
