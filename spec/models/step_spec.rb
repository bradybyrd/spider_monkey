################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

require 'spec_helper'

describe Step do
  include StepHelper

  before(:each) do
    @user = create(:user)
    User.stub(:current_user) { @user }
    @dest_mock = mock("destination")
    @dest_mock.stub(:publish).and_return(true)
    EventableStompletBinder.stub(:fetch).and_return(@dest_mock)
  end
  describe 'validations' do
    before(:each) do
      @step = create(:step)
    end

    it 'should validate presence of owner when the step is not a procedure' do
      @step.owner = nil
      expect(@step).to_not be_procedure
      expect(@step).to_not be_valid
      expect(@step.errors[:owner].size).to eq(1)
    end

    it 'should validate presence of script if automation is enabled' do
      expect(@step).to be_valid
      @step.manual = false
      expect(@step).to_not be_valid
      expect(@step.errors[:script].size).to eq(1)
    end

    it 'should not belong to a procedure and a request at the same time' do
      expect(@step.request).to_not be_blank
      proc = create(:procedure)
      @step.floating_procedure = proc
      expect(@step).to_not be_valid
    end
  end

  describe "delegations" do

    subject { @step = create(:step) }
    it { should respond_to :environment }
    it { should respond_to :business_process_name }
    it { should respond_to :app_name }
    it { should respond_to :environment_name }
    it { should respond_to :plan }
    it { should respond_to :component_name }
    it { should respond_to :phase_name }
    it { should respond_to :work_task_name }
    it { should respond_to :owner_name }
    it { should respond_to :request_number }
    it { should respond_to :owner_contact_number }
  end

  describe "delegations 2" do
    before(:each) do
      @step = create(:step)
    end

    it "should have the same environment as the corresponding request's environment" do
      @step.environment.should == @step.request.environment
    end

    it "should have the same business process name as the request" do
      bp = create(:business_process)
      @step.request.business_process = bp
      #puts "Business Process name: #{@step.request.business_process_name}"
      @step.business_process_name.should == @step.request.business_process_name
    end

    it "should have the same app name as that of the request" do
      application = create(:app, :name => "My application")
      application.stub(:id).and_return(1)
      application.stub(:name).and_return("My application")
      @step.request.apps << application
      #puts "App Name: #{@step.app_name}"
      @step.app_name.should == @step.request.app_name
    end

    it "should have the same environment name as that of the request" do
      #puts "Env Name: #{@step.environment_name}"
      @step.environment_name.should == @step.request.environment_name
    end

    it "should have the same plan as that of the request" do
      l = mock_model(Plan)
      l.stub(:id).and_return(1)
      l.stub(:name).and_return("My LC")
      lm = mock_model(PlanMember)
      lm.stub(:id).and_return(1)
      lm.stub(:plan).and_return(l)
      @step.request.plan_member = lm
      #puts "LC Name: #{@step.plan.name}"
      @step.plan.should == @step.request.plan
    end

    it "should have the same component name as that of the component" do
      comp = mock_model(Component)
      comp.stub(:id).and_return(1)
      comp.stub(:name).and_return("Comp 1")
      @step.component = comp
      #puts "Component Name: #{@step.component_name}"
      @step.component_name.should == @step.component.name
    end

    it "should have the same phase name as that of the phase" do
      phase = mock_model(Phase)
      phase.stub(:id).and_return(1)
      phase.stub(:name).and_return("Phase 1")
      @step.phase = phase
      #puts "Phase Name: #{@step.phase_name}"
      @step.phase_name.should == @step.phase.name
    end

    it "should have the same worktask name as that of the worktask" do
      worktask = mock_model(WorkTask)
      worktask.stub(:id).and_return(1)
      worktask.stub(:name).and_return("Work Task 12")
      @step.work_task = worktask
      #puts "Work Task: #{@step.work_task_name}"
      @step.work_task_name.should == @step.work_task.name
    end

    it "should have the same owner name as that of the owner" do
      #puts "Owner: #{@step.owner_name}"
      @step.owner_name.should == @step.owner.name
    end

    it "should have the same request number as that of the request" do
      #puts "Request Number: #{@step.request_number}"
      @step.request_number.should == @step.request.number
    end

    it "should have the same owner contact number as that of the owner" do
      @step.owner.contact_number = "+91-9860504788"
      #puts "Owner Contact number: #{@step.owner_contact_number}"
      @step.owner_contact_number.should == @step.owner.contact_number
    end
  end

  describe "#has_package?" do
    it "is true if the related object type is package and one is present" do
      step = create(:step, related_object_type: "package")
      step.package = create(:package)

      expect(step).to have_package
    end

    it "is false if the related object type is package and none are present" do
      step = create(:step, related_object_type: "package")
      step.package = nil

      expect(step).to_not have_package
    end

    it "is false if the related object type is component but one is present" do
      step = create(:step, related_object_type: "component")
      step.package = create(:package)

      expect(step).to_not have_package
    end
  end

  describe '#has_invalid_package?' do
    it 'returns false if it is not associated with a package' do
      step = create(:step, related_object_type: 'component')
      expect(step).not_to have_invalid_package
    end

    it 'returns false if it is associated with a package' do
      step = create_step_with_valid_package
      expect(step).not_to have_invalid_package
    end

    it 'returns true if the package is no longer associated' do
      step = create_step_with_invalid_package
      expect(step).to have_invalid_package
    end

    it 'returns false if this is a procedure' do
      @procedure_step = create(:step, :procedure => true)
      expect(@procedure_step).not_to have_invalid_package
    end
  end

  describe '#has_invalid_package? procedures' do
    it 'returns false if it is associated with a package' do
      step = create_procedure_step_with_valid_package
      expect(step).not_to have_invalid_package
    end

    it 'returns true if the package is no longer associated' do
      step = create_procedure_step_with_invalid_package
      expect(step).to have_invalid_package
    end
  end

  describe '#enabled_editing?' do
    context 'when step does not belong to a request' do
      it 'returns true if user has the edit_step permission' do
        step = create_step_without_assigned_request
        user = create_user_with_permissions('Edit Steps')

        expect(step.enabled_editing?(user)).to be_truthy
      end
    end

    context 'when step does belong to a request' do
      it 'returns false if step id not #editable?' do
        user = create_user_with_permissions('Edit Steps')
        step = build :step
        step.stub(:editable?).and_return(false)

        expect(step.enabled_editing?(user)).to be_falsey
      end

       it 'returns false when user has no appropriate permissions' do
         user = create(:user, :with_role_and_group)
         step = build :step

         expect(step.enabled_editing?(user)).to be_falsey
       end

      it 'returns true when user has appropriate permissions and step is #editable?' do
        user = create_user_with_permissions('Edit Steps')
        step = build(:step)
        step.stub(:editable?).and_return(true)

        expect(step.enabled_editing?(user)).to be_truthy
      end
    end

    def create_user_with_permissions(permissions)
      user = create(:user, :with_role_and_group)
      permission_granter = TestPermissionGranter.new(user.groups.first.roles.first.permissions)
      permission_granter << permissions
      user
    end

    def create_step_without_assigned_request
      step = create(:step)
      step.request = nil
      step
    end
  end

  describe '#editable?' do
    context 'when step is in locked state' do
      it 'returns true when request is in created, planned, cancelled, hold states' do
        request_states = %w(created planned cancelled hold)
        locked_step = build(:step, aasm_state: :locked)
        request_states.each do |request_state|
          locked_step.request = build(:request, aasm_state: request_state)
          expect(locked_step).to be_editable
        end
      end
    end

    context 'when step is in non locked state' do
      it 'returns false when request is in started, problem, compelete, deleted states' do
        request_states = %w(started problem compelete deleted)
        non_locked_step = build(:step, aasm_state: :ready)
        request_states.each do |request_state|
          non_locked_step.request = build(:request, aasm_state: request_state)
          expect(non_locked_step).not_to be_editable
        end
      end
    end
  end

  describe "named scopes" do
    describe "#problem" do
      it "should return all steps in a problem state" do
        step = create(:step, :aasm_state => 'problem')
        Step.problem.should include(step)
      end
    end

    describe "#running" do
      it "should return all steps in 'in_process', 'ready' or in 'problem' state" do
        s1 = create(:step, :aasm_state => 'problem')
        s2 = create(:step, :aasm_state => 'in_process')
        s3 = create(:step, :aasm_state => 'ready')
        s4 = create(:step, :aasm_state => 'locked')
        #puts Step.running.map {|s| s.aasm_state}.inspect
        Step.running.should include(s1)
        Step.running.should include(s2)
        Step.running.should include(s3)
        Step.running.should_not include(s4)
      end
    end

    describe "#ready_or_in_process" do
      it "should return all steps in 'ready' or 'in_process' state" do
        s1 = create(:step, :aasm_state => 'problem')
        s2 = create(:step, :aasm_state => 'in_process')
        s3 = create(:step, :aasm_state => 'ready')
        s4 = create(:step, :aasm_state => 'locked')
        #puts Step.ready_or_in_process.map {|s| s.aasm_state}.inspect
        Step.ready_or_in_process.should_not include(s1)
        Step.ready_or_in_process.should include(s2)
        Step.ready_or_in_process.should include(s3)
        Step.ready_or_in_process.should_not include(s4)
      end
    end

    describe "#in_app" do
      it "should return the steps whose requests are in the given app and which have one of the given component ids" do
        User.current_user = User.first
        step = create(:step)
        step.request.apps = [create(:app)]
        step.request.environment = create(:environment)
        step.request.apps.first.environments << step.request.environment
        step.request.save!
        step.save!

        Step.in_app(step.request.apps.first).should include(step)
      end
    end

    describe "#with_component_ids" do
      it "should return the steps which have one of the given component ids" do
        step = create(:step)
        step.component = create(:component)
        step.save!

        comp2 = create(:component)

        Step.with_component_ids(step.component_id).should include(step)
        Step.with_component_ids(comp2.id).should_not include(step)
      end
    end

    describe "#in_environment" do
      it "should return the steps whose requests are in the given environment" do
        step = create(:step)
        env = create(:environment)
        step.request.environment = env
        step.request.save!
        step.save!

        env2 = create(:environment)

        Step.in_environment(step.request.environment).should include(step)
        Step.in_environment(env2).should_not include(step)
      end
    end

    describe "#with_server_ids" do
      before do
        @server = Server.create!(:name => "Server")
        @step = create(:step, server_ids: [@server.id])
      end

      it "should return the steps which have one of the given server ids" do
        Step.with_server_ids([@server.id]).should include(@step)
      end

      it "should not return steps that don't have a server with one of the given ids" do
        different_server = Server.create!(name: "Server 2")

        Step.all.should include(@step)
        Step.with_server_ids([different_server.id]).should_not include(@step)
      end

      it "should work with multiple ids" do
        different_server = Server.create!(name: "Server 2")
        unwanted_server = Server.create!(name: "Unwanted")
        another_step = create(:step, server_ids: [different_server.id])
        unwanted_step = create(:step, server_ids: [unwanted_server.id])

        all_steps = Step.all
        all_steps.should include(@step)
        all_steps.should include(another_step)
        all_steps.should include(unwanted_step)
        Step.with_server_ids([different_server.id, @server.id]).should == [@step, another_step]
      end
    end

    describe "#should_execute" do
      it "should return the steps where should_execute is true" do
        step_that_executes = create(:step, :should_execute => true)
        step_that_does_not_execute = create(:step, :should_execute => false)
        Step.should_execute.should include(step_that_executes)
        Step.should_execute.should_not include(step_that_does_not_execute)
      end
    end

    describe "#top_level" do
      it "should return steps that are directly on requests" do
        request = create(:request)
        step = create(:step, :request => request)
        procedure = create(:step, :request => request)
        procedure_step = create(:step, :request => request, :parent => procedure)
        top_level_steps = Step.top_level
        top_level_steps.should include(step)
        top_level_steps.should include(procedure)
        top_level_steps.should_not include(procedure_step)
      end
    end

    describe "#owned_by_user" do
      it "should return steps owned by the given user" do
        #user = create(:user, :login => "Billeroo")
        user = create(:user)
        step_we_want = create(:step, :owner => user)
        step_we_dont = create(:step)
        Step.owned_by_user(user).should == [step_we_want]
      end
    end

    describe "#owned_by_group" do
      it "should return steps owned by the given group" do
        #group = create(:group, :name => "Billeroo")
        group = create(:group)
        step_we_want = create(:step, :owner => group)
        step_we_dont = create(:step)
        Step.owned_by_group(group).should == [step_we_want]
      end
    end

    describe "#owned_by_user_including_groups" do
      it "should return steps owned by the given user and steps owned by that user's groups" do
        group = create(:group)
        user = create(:user, :group_ids => [group.id])
        user_step_we_want = create(:step, :owner => user)
        group_step_we_want = create(:step, :owner => group)
        step_we_dont_want = create(:step)
        Step.owned_by_user_including_groups([user.id]).should == [user_step_we_want, group_step_we_want]
      end
    end

    describe "atomic or procedure" do
      before do
        @atomic_step = create(:step, :procedure => false)
        @procedure_step = create(:step, :procedure => true)
      end

      describe "#atomic" do
        it "should return steps that are atomic i.e. not procedures" do
          atomic_steps = Step.atomic
          atomic_steps.should include(@atomic_step)
          atomic_steps.should_not include(@procedure_step)
        end
      end

      describe "#find_procedure" do
        it "should return steps that are procedures i.e. not atomic" do
          proc_steps = Step.find_procedure
          proc_steps.should include(@procedure_step)
          proc_steps.should_not include(@atomic_step)
        end
      end
    end

    describe "serial or parallel" do
      before do
        @serial_step = create(:step, :different_level_from_previous => true)
        @parallel_step = create(:step, :different_level_from_previous => false)
      end

      describe "#serial_steps" do
        it "should return all serial steps" do
          serial_steps = Step.serial_steps
          serial_steps.should include(@serial_step)
          serial_steps.should_not include(@parallel_step)
        end
      end

      describe "#parallel_steps" do
        it "should return all parallel steps" do
          parallel_steps = Step.parallel_steps
          parallel_steps.should include(@parallel_step)
          parallel_steps.should_not include(@serial_step)
        end
      end
    end

    #describe "#anytime_steps" do
    #  step1 = create(:step, :execute_anytime => false)
    #  step2 = create(:step, :execute_anytime => true)

    #  l = Step.anytime_steps.map(&:id)
    #  puts "Anytime steps: #{l.inspect}"
    #  l.should include(step1.id)
    #  l.should_not include(step2.id)
    #end

    describe "#in_completed_request" do
      it "should return steps only in completed requests" do
        step = create(:step)
        step.request.aasm_state = 'complete'
        step.request.save!
        step.save!
        Step.in_completed_request.should include(step)
      end
    end

    describe "#request_not_deleted" do
      it "should return steps only for those requests that are not deleted" do
        step1 = create(:step)
        step2 = create(:step)
        step1.request.update_attributes(aasm_state: 'deleted')
        steps_request_not_deleted = Step.request_in_progress
        steps_request_not_deleted.should_not include(step1)
        steps_request_not_deleted.should include(step2)
      end
    end

    describe "#next_step" do
      it "should return the step after current step" do
        req = create(:request)
        step1 = create(:step, :request => req)
        step2 = create(:step, :request => req)
        Step.next_step(req.id, step1.id).should include(step2)
      end
    end

    describe "#order_by_position" do
      it "should return the step ordered by position" do
        #user = create(:user, :login => "StepOrderBy")
        user = create(:user)
        step1 = create(:step, :owner => user, :position => 3)
        step2 = create(:step, :owner => user, :position => 1)
        step3 = create(:step, :owner => user, :position => 2)
        Step.owned_by_user(user.id).order_by_position.should == [step2, step3, step1]
      end
    end

    describe "#group_by_components" do
      it "should return steps grouped by components" do
        req = create(:request)
        #user = create(:user, :login => "StepGroupByComponent")
        user = create(:user)

        comp1 = create(:component)
        comp2 = create(:component)

        step1 = create(:step, :request => req, :owner => user, :component => comp1)
        step2 = create(:step, :request => req, :owner => user, :component => comp2)
        step3 = create(:step, :request => req, :owner => user, :component => comp1)
        step4 = create(:step, :request => req, :owner => user, :component => comp2)
        step_ids = Step.owned_by_user(user.id).group_by_components.map { |s| s.id }
        step_ids.should include(step1.id)
        step_ids.should include(step2.id)
        step_ids.should_not include(step3.id)
        step_ids.should_not include(step4.id)
      end
    end
  end

  describe "transitions" do
    describe "#finish_resolution!" do

      it "should transition the step from being resolved to in process" do
        step = create(:step, :aasm_state => 'being_resolved')
        step.finish_resolution!
        step.should be_in_process
      end

    end

    describe "#problem!" do

      it "should transition to problem from in_process" do
        request = create(:request)
        request.update_attributes!(:aasm_state => 'started')
        step = create(:step, :aasm_state => 'in_process', :request => request)
        #puts "Step state: #{step.aasm_state}"
        step.problem!
        step.should be_problem
        step.request.should be_problem
      end

    end

    describe "#resolve!" do

      it "should update the request's and steps's status" do
        request = create(:request)
        request.update_attributes!(:aasm_state => 'problem')
        step = create(:step, :aasm_state => 'problem', :request => request)

        step.should_receive(:run_script).once
        step.resolve!
        step.request.should be_started
        step.should be_in_process
      end
    end

    describe "#done!" do
      before(:each) do
        @step = create(:step)
        @step.request.stub(:started?).and_return(true)
      end

      context "when the step is in_process or problem" do
        it "should complete when in process" do
          @step.update_attributes :aasm_state => 'in_process'
          @step.done!
          @step.should be_complete
        end

        it "should complete when in problem" do
          @step.update_attributes :aasm_state => 'problem'
          @step.done!
          @step.should be_complete
        end
      end

      context "when one-click completion is on" do
        it "should not change state when the step is ready, but one click completion is not on" do
          @step.update_attributes(:aasm_state => 'ready')
          expect { @step.done! }.to raise_error(AASM::InvalidTransition)
          @step.should_not be_complete
        end

        it "should not change state when the step is locked and execute anytime is on, but one click completion is not on" do
          @step.update_attributes(:aasm_state => 'locked', :execute_anytime => true)
          expect { @step.done! }.to raise_error(AASM::InvalidTransition)
          @step.should_not be_complete
        end

        it "should change state to done when the step is ready, and one click completion is on" do
          GlobalSettings.stub(:one_click_completion?).and_return(true)
          @step.update_attributes(:aasm_state => 'ready')
          @step.done!
          @step.should be_complete
        end

        it "should change state when the step is locked and execute anytime is on, and one click completion is on" do
          GlobalSettings.stub(:one_click_completion?).and_return(true)
          @step.update_attributes(:aasm_state => 'locked', :execute_anytime => true)
          @step.done!
          @step.should be_complete
        end
      end

      context "when request state is problem and step state is inprocess/problem, there should be a way to complete the step" do

        it "should change state to complete when request state is problem, and step state is in_process" do
          @step.request.stub(:started?).and_return(false)
          @step.request.stub(:problem?).and_return(true)
          @step.update_attributes :aasm_state => 'in_process'
          @step.done!
          @step.should be_complete
        end

        it "should change state to complete when request state is problem, and step state is problem" do
          @step.request.stub(:started?).and_return(false)
          @step.request.stub(:problem?).and_return(true)
          @step.update_attributes :aasm_state => 'problem'
          @step.done!
          @step.should be_complete
        end
        it "should not change step state to complete when request state is not started or problem" do
          @step.request.stub(:started?).and_return(false)
          @step.request.stub(:problem?).and_return(false)
          @step.update_attributes :aasm_state => 'in_process'
          expect { @step.done! }.to raise_error(AASM::InvalidTransition)
          @step.should_not be_complete
        end
      end
    end

    describe "#ready_for_work!" do
      before(:each) do
        @step = create(:step)
      end

      context "Only transition from locked state into ready state" do
        it "should transition from locked state to ready state" do
          @step.update_attributes(:aasm_state => 'locked')
          @step.ready_for_work!
          @step.should be_ready
        end

        it "should not transition from some other state to ready state" do
          @step.update_attributes(:aasm_state => 'in_process')
          expect { @step.ready_for_work }.to raise_error(AASM::InvalidTransition)
        end
      end
    end

    describe "#start!" do
      before(:each) do
        @step = create(:step)
        @step.request.stub(:started?).and_return(true)
      end

      #ready, :locked, :complete, starttab;e
      it "should move into in_process state from ready state" do
        @step.update_attributes(:aasm_state => 'ready')
        @step.startable?.should be_truthy
        @step.start!
        @step.aasm_state.should == 'in_process'
      end

      it "should move into in_process state from locked state only if execute anytime is set to true" do
        @step.update_attributes(:aasm_state => 'locked')
        expect { @step.start! }.to raise_error(AASM::InvalidTransition)
        @step.aasm_state.should_not == 'in_process'
        @step.update_attributes(:aasm_state => 'locked', :execute_anytime => true)
        @step.start!
        @step.aasm_state.should == 'in_process'
      end

      it "should not move into in process state if the request is not started" do
        @step.update_attributes(:aasm_state => 'ready')
        @step.request.stub(:started?).and_return(false)
        expect { @step.start! }.to raise_error(AASM::InvalidTransition)
        @step.aasm_state.should_not == 'in_process'
      end
    end

    describe "#lock!" do
      before(:each) do
        @step = create(:step)
      end

      it "should move into locked state from ready state" do
        @step.update_attributes(:aasm_state => 'ready')
        @step.lock!
        @step.aasm_state.should == 'locked'
      end

      it "should not move into locked state from in_process state if it is note a procedure" do
        @step.update_attributes(:aasm_state => 'in_process')
        expect { @step.lock! }.to raise_error(AASM::InvalidTransition)
        @step.aasm_state.should_not == 'locked'
        new_step = create(:step, :aasm_state => 'in_process', :procedure => true)
        new_step.lock!
        new_step.aasm_state.should == 'locked'
      end

      it "should move into locked state from problem state" do # FIXME: Not sure if this is a valid transistion
        @step.update_attributes(:aasm_state => 'problem')
        @step.lock!
        @step.aasm_state.should == 'locked'
      end
    end

    describe "#reset!" do
      it "should move into locked state from complete state" do
        step = create(:step, :aasm_state => 'complete')
        step.reset!
        step.aasm_state.should == 'locked'
      end

      it "should not move into locked state from in_process state" do
        step = create(:step, :aasm_state => 'in_process')
        expect { step.reset! }.to raise_error(AASM::InvalidTransition)
      end
    end

    describe "#oops!" do # FIXME: Not sure if this is a valid event yet
      it "should move from complete to in_process state" do
        step = create(:step, :aasm_state => 'complete')
        step.oops!
        step.aasm_state.should == 'in_process'
      end

      it "should not move into in_process state from locked state" do
        step = create(:step, :aasm_state => 'locked')
        expect { step.oops! }.to raise_error(AASM::InvalidTransition)
      end
    end

    describe "#finish_resolution!" do
      it "should move from problem to in_process" do
        step = create(:step, :aasm_state => 'problem')
        step.finish_resolution!
        step.aasm_state.should == 'in_process'
      end

      it "should move from being_resolved state to in_process" do
        step = create(:step, :aasm_state => 'being_resolved')
        step.finish_resolution!
        step.aasm_state.should == 'in_process'
      end

      it "should not move from any other state to in_process" do
        step = create(:step, :aasm_state => 'locked')
        expect { step.finish_resolution! }.to raise_error(AASM::InvalidTransition)
      end
    end

    describe "#force_resolve!" do
      it "should move from problem to in_process" do
        step = create(:step, :aasm_state => 'problem')
        step.force_resolve!
        step.aasm_state.should == 'in_process'
      end

      it "should not move from any other state to in_process" do
        step = create(:step, :aasm_state => 'locked')
        expect { step.force_resolve! }.to raise_error(AASM::InvalidTransition)
      end
    end

    describe "#block!" do
      before(:each) do
        @step = create(:step)
      end

      it "should move from locked state to blocked state" do
        @step.update_attributes(:aasm_state => 'locked')
        @step.block!
        @step.should be_blocked
      end

      it "should move from ready state to blocked state" do
        @step.update_attributes(:aasm_state => 'ready')
        @step.block!
        @step.should be_blocked
      end

      it "should move from in_process state to blocked state" do
        @step.update_attributes(:aasm_state => 'in_process')
        @step.block!
        @step.should be_blocked
      end

      it "should not move from any other state to blocked state" do
        @step.update_attributes(:aasm_state => 'problem')
        expect { @step.block! }.to raise_error(AASM::InvalidTransition)
      end
    end

    describe "#unblock_ready!" do
      it "should move from blocked state to ready" do
        step = create(:step, :aasm_state => 'blocked')
        step.unblock_ready!
        step.should be_ready
      end

      it "should not respond to any other state other than blocked" do
        step = create(:step, :aasm_state => 'locked')
        expect { step.unblock_ready! }.to raise_error(AASM::InvalidTransition)
      end
    end

    describe "#unblock_in_process!" do
      it "should move from blocked state to ready" do
        step = create(:step, :aasm_state => 'blocked')
        step.unblock_in_process!
        step.aasm_state.should == 'in_process'
      end

      it "should not respond to any other state other than blocked" do
        step = create(:step, :aasm_state => 'locked')
        expect { step.unblock_in_process! }.to raise_error(AASM::InvalidTransition)
      end
    end
  end # transitions end

  describe '#commentable_by?' do
    before do
      Request.any_instance.stub(:check_if_able_to_create_request).and_return(true)
      @env = create(:environment)
      @app = create(:app, environments: [@env])
      @user_with_app = create(:user)
      @user_with_app.apps = [@app]
      @user_without_app = create(:user)
      @request = create(:request, :apps => [@app], environment: @env)
      @step = create(:step, :request => @request)
    end

    it 'should allow to add notes to step for user that assigned to app, for which request assigned' do
      @step.commentable_by?(@user_with_app).should be_truthy
    end

    it 'should not allow to add notes to step for user that not assigned to app, for which request assigned' do
      @step.commentable_by?(@user_without_app).should be_falsey
    end
  end

  describe '.filtered' do
    before(:all) do
      Step.delete_all

      @user = create(:user)
      User.current_user = @user

      @owner_user = create(:user)
      @request = create(:request)
      @version_tag = create(:version_tag)
      @runtime_phase = create(:runtime_phase)
      @category = create(:category)

      @owner_group = create(:group)
      @app = create(:app)
      @package_template = create(:package_template, name: 'Package template', app: @app, version: 'zzz')
      @script = create(:general_script, automation_category: 'cat @1')
      @phase = create(:phase)
      @procedure = create(:procedure)
      @work_task = create(:work_task)
      @server = create(:server)

      @step_1 = create_step(aasm_state: 'ready',
                            name: 'Step #1',
                            owner: @owner_user,
                            request: @request,
                            version_tag: @version_tag,
                            custom_ticket_id: 15,
                            runtime_phase: @runtime_phase,
                            category: @category,
                            servers: [@server])

      @step_2 = create_step(aasm_state: 'in_process',
                            name: 'Step #2',
                            owner: @owner_group,
                            component_version: 'aaa',
                            package_template: @package_template,
                            script: @script,
                            phase: @phase,
                            floating_procedure: @procedure, procedure: true, request: nil,
                            parent: @step_1,
                            work_task: @work_task,
                            work_started_at: Date.today)
    end

    after(:all) do
      Step.delete_all
    end

    describe 'filter by default' do
      subject { described_class.filtered() }
      it { should match_array([@step_1, @step_2]) }
    end

    describe 'filter by aasm_state, name, request_id, user_id, installed_component_id, version_tag_id, custom_ticket_id, runtime_phase_id, category_id, server_id' do
      subject { described_class.filtered(aasm_state: 'ready',
                                         name: 'Step #1',
                                         request_id: @request.id,
                                         user_id: @owner_user.id,
                                         version_tag_id: @version_tag.id,
                                         custom_ticket_id: 15,
                                         runtime_phase_id: @runtime_phase.id,
                                         category_id: @category.id,
                                         server_id: [@server.id]) }
      it { should match_array([@step_1]) }
    end

    describe 'filter by group_id, running, component_version, package_template_id, script_id, phase_id, procedure_id, parent_id, work_task_id' do
      subject { described_class.filtered(group_id: @owner_group.id,
                                         running: true,
                                         component_version: 'aaa',
                                         package_template_id: @package_template.id,
                                         script_id: @script.id,
                                         phase_id: @phase.id,
                                         procedure_id: @procedure.id,
                                         parent_id: @step_1.id,
                                         work_task_id: @work_task.id,
                                         started_at_range: {end_date: Date.today.strftime('%m/%d/%Y')}
      ) }
      it { should match_array([@step_2]) }
    end
  end

  describe '#allow_mail_delivery?' do
    let(:step) { build(:step, procedure: true, suppress_notification: true) }

    it 'denies mail delivery if flagged as procedure and skip notification' do
      step.allow_mail_delivery?.should eq false
    end

    it 'denies mail delivery if flagged as skip notification' do
      step.procedure = false
      step.allow_mail_delivery?.should eq false
    end

    it 'denies mail delivery if flagged as procedure' do
      step.suppress_notification = false
      step.allow_mail_delivery?.should eq false
    end

    it 'allows delivery if there is no procedure and skip notification flags' do
      step.assign_attributes(procedure: false, suppress_notification: false)
      step.allow_mail_delivery?.should eq true
    end
  end

  describe 'step with a script' do
    it 'should have a valid script' do
      step = create(:step_with_script)
      step.script.should be_valid
    end
  end

  describe '#belongs_to?' do
    let(:other_user) { build(:user) }
    let(:owner_user) { build(:user) }
    let(:requestor_user) { build(:user) }
    let(:request) { build(:request, owner: owner_user, requestor: requestor_user) }

    context 'owner is group' do
      let(:group) { create(:group, :with_users, user_count: 3) }
      let(:step_with_group) { build(:step, owner: group, request: request) }

      it 'returns true if user in group' do
        expect(step_with_group.belongs_to?(group)).to be_truthy
      end

      it 'false if user does not match' do
        expect(step_with_group.belongs_to?(other_user)).to be_falsey
      end
    end

    context 'owner is user' do
      let(:step_owner_user) { build(:user) }
      let(:step) { build(:step, owner: step_owner_user, request: request) }

      it 'returns true if user is step owner' do
        expect(step.belongs_to?(step_owner_user)).to be_truthy
      end

      it 'returns true if user is request owner' do
        expect(step.belongs_to?(owner_user)).to be_truthy
      end

      it 'returns true if user is request requestor' do
        expect(step.belongs_to?(requestor_user)).to be_truthy
      end

      it 'false if user does not match' do
        expect(step.belongs_to?(other_user)).to be_falsey
      end
    end
  end

  describe '.with_started_at_dates' do
    let(:yesterday) { (Date.today - 1.day).strftime('%m/%d/%Y') }
    let(:today) { Date.today.strftime('%m/%d/%Y') }
    let(:first_started_step) { create(:step, work_started_at: Date.strptime(yesterday, '%m/%d/%Y')) }
    let(:last_started_step) { create(:step, work_started_at: Date.strptime(today, '%m/%d/%Y')) }

    it 'is scoped if no dates present' do
      pending 'This is fantom test'
      Step.with_started_at_dates(initial_date: nil, end_date: nil).should =~ [first_started_step, last_started_step]
    end

    context 'with initial/end dates' do
      specify { Step.with_started_at_dates(initial_date: yesterday, end_date: today).should eq [first_started_step, last_started_step] }
    end

    context 'with initial date only' do
      specify { Step.with_started_at_dates(initial_date: today).should eq [last_started_step] }
      specify { Step.with_started_at_dates(initial_date: yesterday).should eq [first_started_step, last_started_step] }
    end

    context 'with end date only' do
      specify { Step.with_started_at_dates(end_date: today).should eq [first_started_step, last_started_step] }
      specify { Step.with_started_at_dates(end_date: yesterday).should eq [first_started_step] }
    end
  end

  describe 'aasm event' do
    let(:step) { create(:step) }

    context '.validate_aasm_event' do
      context 'with invalid event' do
        it 'returns error not supported event' do
          step.aasm_event = 'invalid_event'
          step.save
          expect(step.errors_on(:aasm_event).size).to eq(1)
        end
      end

      context 'when invalid transition' do
        it 'returns error not a valid transition' do
          step.aasm_event = 'problem'
          step.save
          expect(step.errors_on(:aasm_event).size).to eq(1)
        end
      end

      context 'with valid event' do
        it 'returns no error' do
          step.aasm_event = 'ready_for_work'
          step.save
          expect(step.errors_on(:aasm_event).size).to eq(0)
        end
      end
    end

    context '.run_aasm_event' do
      it 'update assm_state' do
        step.aasm_event = 'ready_for_work'
        step.save
        expect(step).to be_ready
      end
    end
  end


  describe 'output headers for script usage' do

    context 'package level step' do
      let(:package) { create :package }
      let(:app) { create :app, packages: [package] }

      let(:step) {
        create :step,
               related_object_type: 'package',
               package: package,
               create_new_package_instance: true,
               latest_package_instance: false
      }

      before (:each) {
        step.request.apps = [app]
        @headers = step.headers_for_step
      }

      it { @headers.should include("step_object_type" => 'package') }
      it { @headers.should include("step_package_id" => package.id) }
      it { @headers.should include("step_package_name" => package.name) }
      it { @headers.should include("step_create_new_package_instance" => step.create_new_package_instance) }
      it { @headers.should include("step_latest_package_instance" => step.latest_package_instance) }
      it { @headers.should include("step_ref_ids" => "") }

    end


    context 'package level step with properties' do

      let(:property) { create :property }
      let(:package) {
        create :package, properties: [property]
      }
      let(:app) { create :app, packages: [package] }

      let(:step) {
        create :step,
               related_object_type: 'package',
               package: package,
               create_new_package_instance: true,
               latest_package_instance: false
      }

      before (:each) {
        step.request.apps = [app]
        step.stub(:literal_property_value_for).with(property, app.application_packages[0]) {
          "test value"
        }
        @headers = step.headers_for_step
      }

      it { @headers.should include(property.name => "test value") }

    end


    context 'package level step with references' do

      let(:package_ref1) { create :reference }
      let(:package_ref2) { create :reference }

      let(:package) { create :package }
      let(:app) { create :app, packages: [package] }

      let(:step) {
        create :step,
               related_object_type: 'package',
               package: package,
               create_new_package_instance: true,
               latest_package_instance: false
      }

      before (:each) {
        step.request.apps = [app]
        step.reference_ids = [package_ref1.id, package_ref2.id]
        step.update_references!()
        @headers = step.headers_for_step
      }

      it { @headers.should include("step_ref_ids" => [package_ref1, package_ref2].map{ |r| r.id }.join(",") ) }
      it { @headers.should include("step_ref_names" => [package_ref1, package_ref2].map{ |r| r.name }.join(",")) }
      it { @headers.should include("step_package_id" => package.id) }
      it { @headers.should include("step_ref_#{package_ref1.name}_method" => package_ref1.resource_method) }
      it { @headers.should include("step_ref_#{package_ref1.name}_server" => package_ref1.server.name) }
      it { @headers.should include("step_ref_#{package_ref1.name}_uri" => package_ref1.uri) }

    end

    context 'package level step with references create new instance' do

      let(:package) { create :package }

      let(:package_ref1) { create :reference, package: package }
      let(:package_ref2) { create :reference, package: package }

      let(:app) { create :app, packages: [package] }

      let(:step) {
        create :step,
               related_object_type: 'package',
               package: package,
               create_new_package_instance: true,
               latest_package_instance: false
      }

      before (:each) {
        step.request.apps = [app]
        step.reference_ids = [package_ref1.id, package_ref2.id]
        step.update_references!
        params = step.create_package_instance_for_step_run
        @package_instance = PackageInstance.find(params[:temp_new_package_instance_id])
        @headers = step.headers_for_step( params )
      }

      it { @headers.should include("step_ref_ids" => "#{package_ref1.id},#{package_ref2.id}") }
      it { @headers.should include("step_ref_names" => "#{package_ref1.name},#{package_ref2.name}") }
      it { @headers.should include("step_package_id" => package.id) }
      it { @headers.should include("step_ref_#{package_ref1.name}_method" => package_ref1.resource_method) }
      it { @headers.should include("step_ref_#{package_ref1.name}_server" => package_ref1.server.name) }
      it { @headers.should include("step_package_instance_id" => @package_instance.id) }
      it { @headers.should include("step_package_instance_name" => @package_instance.name) }
      it { @package_instance.instance_references.size.should eq(2) }
    end

    context 'package instance level step' do
      let(:package_instance) { create :package_instance }

      let(:step) {
        create :step,
               related_object_type: 'package_instance',
               package_instance: package_instance,
               create_new_package_instance: false,
               latest_package_instance: false
      }

      before (:each) {
        @headers = step.headers_for_step
      }

      it { @headers.should include("step_object_type" => 'package_instance') }
      it { @headers.should include("step_package_instance_id" => package_instance.id) }
      it { @headers.should include("step_package_instance_name" => package_instance.name) }
      it { @headers.should include("step_create_new_package_instance" => step.create_new_package_instance) }
      it { @headers.should include("step_latest_package_instance" => step.latest_package_instance) }
      it { @headers.should include("step_ref_ids" => "") }

    end


    context 'package instance level step with properties' do

      let(:property) { create :property }
      let(:package) {
        create :package, properties: [property]
      }

      let(:package_instance) {
        create :package_instance, package: package
      }

      let(:step) {
        create :step,
               related_object_type: 'package_instance',
               package_instance: package_instance,
               create_new_package_instance: false,
               latest_package_instance: false
      }

      before (:each) {
        package_instance.copy_property_from_package
        step.stub(:literal_property_value_for).with(property, package_instance) {
          "test value2"
        }

        @headers = step.headers_for_step
      }

      it { @headers.should include("step_object_type" => 'package_instance') }
      it { @headers.should include("step_package_instance_id" => package_instance.id) }
      it { @headers.should include("step_package_instance_name" => package_instance.name) }
      it { @headers.should include("step_create_new_package_instance" => step.create_new_package_instance) }
      it { @headers.should include("step_latest_package_instance" => step.latest_package_instance) }
      it { @headers.should include("step_ref_ids" => "") }
      it { @headers.should include(property.name => "test value2") }

    end


    context 'package instance level step with references' do

      let(:package_inst_ref1) {
        create :instance_reference, server: create(:server)
      }

      let(:package_inst_ref2) {
        create :instance_reference, server: create(:server)
      }


      let(:package_instance) {
        create :package_instance
      }

      let(:step) {
        create :step,
               related_object_type: 'package_instance',
               package_instance: package_instance,
               create_new_package_instance: false,
               latest_package_instance: false
      }

      before (:each) {
        step.reference_ids = [package_inst_ref1.id, package_inst_ref2.id]
        step.update_references!()
        @headers = step.headers_for_step
      }

      it { @headers.should include("step_ref_ids" => [package_inst_ref1, package_inst_ref2].map{ |r| r.id }.join(",")) }
      it { @headers.should include("step_package_instance_id" => package_instance.id ) }
      it { @headers.should include("step_package_instance_name" => package_instance.name ) }
      it { @headers.should include("step_ref_#{package_inst_ref1.name}_method" => package_inst_ref1.resource_method ) }
      it { @headers.should include("step_ref_#{package_inst_ref1.name}_uri" => package_inst_ref1.uri ) }


    end

  end

  describe 'references at step maintain with update' do

    context 'step name updated' do
      let(:package) { create :package }
      let(:package_ref1) { create :reference, package: package }
      let(:package_ref2) { create :reference, package: package }

      let(:app) { create :app, packages: [package] }

      let(:step) {
        create :step,
               related_object_type: 'package',
               package: package,
               create_new_package_instance: true,
               latest_package_instance: false,
               reference_ids: [package_ref1.id, package_ref2.id]
      }

      before (:each) {
        step.request.apps = [app]
        step.name = "new name"
        step.save!
        step.reload
      }

      it { expect(step.step_references.size).to eq 2 }

    end

    context 'references cleared for component' do
      let(:package) { create :package }
      let(:package_ref1) { create :reference, package: package }
      let(:package_ref2) { create :reference, package: package }

      let(:app) { create :app, packages: [package] }

      let(:step) {
        create :step,
               related_object_type: 'package',
               package: package,
               create_new_package_instance: true,
               latest_package_instance: false,
               reference_ids: [package_ref1.id, package_ref2.id]
      }

      before (:each) {
        step.request.apps = [app]
        step.related_object_type = "component"
        step.save!
        step.reload
      }

      it { expect(step.step_references.size).to eq 0 }

    end

    context 'references not cleared on save' do
      let(:package) { create :package }
      let(:package_ref1) { create :reference, package: package }
      let(:package_ref2) { create :reference, package: package }

      let(:app) { create :app, packages: [package] }

      let(:step) {
        create :step,
               related_object_type: 'package',
               package: package,
               create_new_package_instance: true,
               latest_package_instance: false,
               reference_ids: [package_ref1.id, package_ref2.id]
      }

      before (:each) {
        step.request.apps = [app]
        step.save!
        step.reload
      }

      it { expect(step.step_references.size).to eq 2 }

    end

    context 'returns reference ids' do
      let(:package) { create :package }
      let(:package_ref1) { create :reference, package: package }
      let(:package_ref2) { create :reference, package: package }

      let(:app) { create :app, packages: [package] }

      let(:step) {
        create :step,
               related_object_type: 'package',
               package: package,
               create_new_package_instance: true,
               latest_package_instance: false,
               reference_ids: [package_ref1.id, package_ref2.id]
      }

      before (:each) {
        step.request.apps = [app]
        step.save!
        step.reload
      }

      it { expect(step.get_reference_ids.size).to eq 2 }
    end

    context 'returns parent object for request' do
      let (:request) { create :request }
      let (:step) { create :step, request: request }
      it { expect(step.parent_object).to eq request }
    end

    context 'returns parent object for procedure' do
      let (:procedure) { create :procedure }
      let (:step) { create :step, floating_procedure: procedure, request: nil }
      it { expect(step.parent_object).to eq procedure }
    end

  end

  describe '#all_currently_running' do
    it 'includes steps from request in progress' do
      user = create(:user)
      step_in_progress = create(:step, aasm_state: 'in_process', owner: user)
      step_locked = create(:step, aasm_state: 'locked', owner: user)
      request_planned = create(:request, aasm_state: 'created', steps: [step_locked])
      request_in_progress = create(:request, steps: [step_in_progress])
      request_in_progress.update_column(:aasm_state, 'started')

      expect(Step.all_currently_running(user)).to eq([step_in_progress])
    end

    it 'includes steps where user is owner' do
      user = create(:user)
      other_user = create(:user)
      step_of_user = create(:step, aasm_state: 'in_process', owner: user)
      step_of_other_user = create(:step, aasm_state: 'in_process', owner: other_user)
      request_in_progress = create(:request, steps: [step_of_user, step_of_other_user])
      request_in_progress.update_column(:aasm_state, 'started')

      expect(Step.all_currently_running(user)).to eq([step_of_user])
    end

    it 'includes steps where one of user groups is owner' do
      user_group = create(:group)
      other_user_group = create(:group)
      user = create(:user, groups: [user_group])
      other_user = create(:user, groups: [other_user_group])
      step_of_user_group = create(:step, aasm_state: 'in_process', owner: user_group)
      step_of_other_user_group = create(:step, aasm_state: 'in_process', owner: other_user_group)
      request_in_progress = create(:request, steps: [step_of_user_group, step_of_other_user_group])
      request_in_progress.update_column(:aasm_state, 'started')

      expect(Step.all_currently_running(user)).to eq([step_of_user_group])
    end

    it 'includes steps which user has access through apps' do
      user_app                = create(:app)
      other_user_app          = create(:app)
      user                    = create(:user, apps: [user_app])
      other_user              = create(:user, apps: [other_user_app])
      step_of_user_app        = create(:step, aasm_state: 'in_process', app: user_app)
      step_of_other_user_app  = create(:step, aasm_state: 'in_process', app: other_user_app)
      request_in_progress     = create(:request, steps: [step_of_user_app, step_of_other_user_app])
      request_in_progress.update_column(:aasm_state, 'started')

      expect(Step.all_currently_running(user)).to eq([step_of_user_app])
    end

    it 'does not include procedures' do
      user                  = create(:user)
      procedure_in_progress = create(:step, aasm_state: 'in_process', owner: user, procedure: true)
      step_in_progress      = create(:step, aasm_state: 'in_process', owner: user, parent_id: procedure_in_progress)
      request_in_progress   = create(:request, steps: [procedure_in_progress, step_in_progress])
      request_in_progress.update_column(:aasm_state, 'started')

      expect(Step.all_currently_running(user)).to eq([step_in_progress])
    end
  end

  protected

  def create_step(options = nil)
    create(:step, options)
  end

end

