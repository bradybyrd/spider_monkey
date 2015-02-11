################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

require File.dirname(__FILE__) + '/../spec_helper'

describe Request do
  describe 'associations' do
    it { should belong_to(:environment) }
    it { should belong_to(:business_process) }
    it { should belong_to(:deployment_coordinator) }
    it { should belong_to(:requestor) }
    it { should belong_to(:owner) }
    it { should belong_to(:release) }
    it { should belong_to(:category) }
    it { should belong_to(:request_template) }
    it { should belong_to(:request_template_origin) }
    it { should belong_to(:activity) }
    it { should belong_to(:plan_member) }
    it { should belong_to(:server_association) }
    it { should belong_to(:parent_request_origin) }
    it { should belong_to(:deployment_window_event) }

    it { should have_many(:apps_requests).dependent(:destroy) }
    it { should have_many(:apps).through(:apps_requests) }
    it { should have_many(:steps).dependent(:destroy) }
  end

  let(:user){ create(:user) }
  let(:request){ create(:request) }
  let(:group){ create(:group) }
  let(:environment){ create(:environment) }

  before(:each) do
    @user = create(:user)
    User.stub(:current_user) { @user }
    @request = create(:request)
    @dest_mock = mock("destination")
    @dest_mock.stub(:publish).and_return(true)
    EventableStompletBinder.stub(:fetch).and_return(@dest_mock)
  end

  describe "assigned user visibility" do
    it "has assigned user available" do
      request = create_request_app_assigned_to_user
      users = request.available_users_with_app
      expect(users).to include(@user)
    end

    def create_request_app_assigned_to_user
      @app = create(:app)
      @env = create(:environment)
      @app.environments << @env
      AssignedEnvironment.create!(:environment_id => @env.id, :assigned_app_id => @app.assigned_apps.first.id, :role => @user.roles.first)
      create(:request, :apps => [@app], :environment_id => @env.id)
    end
  end

  describe "#clone_via_template" do
    it "creates a clone of the request" do
      request = create(:request, name: "A Test Request!")

      cloned_request = request.clone_via_template

      expect(request.name).to eq cloned_request.name
      expect(request.id).to_not eq cloned_request.id
    end

    it "does not leave the template hanging around" do
      request = create(:request, name: "A Test Request!")

      expect { request.clone_via_template }.
        to_not change { RequestTemplate.count }
    end
  end

  describe "validations" do
    it { should validate_presence_of(:requestor) }
    it { should validate_presence_of(:deployment_coordinator) }
    it 'validates permissions per environment', custom_roles: true do
      should validate_permissions_per_environments
    end

    it 'validates environment is associated with app' do
      env = create(:environment)
      app = create(:app)
      req = build(:request, app_ids: [app.id], environment_id: env.id)

      expect(req).not_to be_valid
      expect(req.errors.messages[:base]).to include I18n.t('request.validations.environment_not_associated')
    end

    context 'logged in as admin without assigned apps' do
      it 'passes validation' do
        admin = create(:user).tap { |this| this.stub(root?: true) }
        app = create :app
        env = create :environment
        app.environments << env
        User.stub(:current_user).and_return(admin)

        request = create(:request, app_ids: [app.id], environment_id: env.id).tap { |this| this.stub(:environment_id_changed?).and_return(true) }

        expect(request).to be_valid
      end
    end

    describe 'auto_start validations' do
      describe 'valid w/o scheduled_at and w/o auto_start' do
        let(:req) { build(:request) }
        it { req.should be_valid }
      end

      describe 'valid with scheduled_at and w/o auto_start' do
        let(:req) { build(:request, :scheduled_at => Time.now) }
        it { req.should be_valid }
      end

      describe 'invalid w/o scheduled_at and with auto_start' do
        let(:req) { build(:request, :auto_start => true) }
        it { req.should_not be_valid }
      end

      describe 'invalid with past scheduled_at and with auto_start' do
        let(:req) { build(:request, :scheduled_at => Time.now - 1.hour, :auto_start => true) }
        it { req.should_not be_valid }
      end

      describe 'valid with future scheduled_at and with auto_start' do
        let(:req) { build(:request, :scheduled_at => Time.now + 1.hour, :auto_start => true) }
        it { req.should be_valid }
      end

      it 'is invalid when user has no permission' do
        request = build(:request, auto_start: true, check_permissions: true)
        User.any_instance.stub(:cannot?).and_return(true)

        expect(request).not_to be_valid
        expect(request.errors.messages[:base]).to include I18n.t('request.validations.permit_auto_promote')
      end
    end
  end

  describe "belong_to" do
    it { should belong_to(:activity) }
    it { should belong_to(:request_template_origin) }
    it { should belong_to(:parent_request_origin) }
  end

  describe "delegations" do
  end

  context 'when frozen' do
    it 'should not corrupt data' do
      request.environment = environment
      request.freeze_request!
      request.reload
      request.environment.id.should == request.environment_id
    end
  end

  describe "named scope" do
    describe "#unique_request_ids" do
      it "allows case-insensitivity" do
        lowercase_request = create(:request, name: "abcde")
        uppercase_request = create(:request, name: "ABCDE")

        lowercase_results = Request.inner_apps_requests.unique_request_ids("abcde").all.map(&:unique_id)
        uppercase_results = Request.inner_apps_requests.unique_request_ids("ABCDE").all.map(&:unique_id)

        expected_results = [lowercase_request.id, uppercase_request.id]
        expect(lowercase_results).to match_array expected_results
        expect(uppercase_results).to match_array expected_results
      end
    end

    describe "#participated_in_by" do
      it "should return a request with steps owned by the given user" do
        request.steps.create!(attributes_for(:step).merge(:owner => user, :request => nil))

        Request.participated_in_by(user).should include(request)
      end

      it "should return a requests containing a procedure with steps owned by the given user" do
        request.steps.create!(attributes_for(:step).merge(:owner => create(:user, :login => Time.now.to_s), :request => nil))
        request.steps.first.steps.create!(attributes_for(:step).merge(:owner => user, :request => request))

        Request.participated_in_by(user).should include(request)
      end

      it "should return a request with steps owned by the given user's group" do
        user.groups = [group]
        user.save

        request.steps.create!(attributes_for(:step).merge(:owner => group, :request => nil))

        Request.participated_in_by(user).should include(request)
      end

      it "should return requests with steps containing steps owned by the given user's group" do
        user.groups = [group]
        user.save

        request.steps.create!(attributes_for(:step).merge(
                                  :owner => create(:group, :name => Time.now.to_s, :email => "#{Time.now}@example.com"), :request => nil))
        request.steps.first.steps.create!(attributes_for(:step).merge(:owner => group, :request => request))
        Request.participated_in_by(user).should include(request)
      end

      it "should return requests owned by the given user" do
        request = create(:request, deployment_coordinator_id: user.id)
        Request.participated_in_by(user).should include(request)
      end

      it "should return requests for which the given user is the requestor" do
        request = create(:request, requestor: user)
        Request.participated_in_by(user).should include(request)
      end

    end

    describe "#participated_in_directly_by" do
      it "should return a request with steps owned by the given user" do
        request.steps.create!(attributes_for(:step).merge(:owner => user, :request => nil))

        Request.participated_in_directly_by(user).should include(request)
      end

      it "should return a request containing a procedure with steps owned by the given user" do

        request.steps.create!(attributes_for(:step).merge(:owner => create(:user, :login => Time.now.to_s), :request => nil))
        request.steps.first.steps.create!(attributes_for(:step).merge(:owner => user, :request => request))

        Request.participated_in_directly_by(user).should include(request)
      end

      it "should NOT return a request with steps owned by the given user's group" do
        user.groups = [group]
        user.save

        request.steps.create!(attributes_for(:step).merge(:owner => group, :request => nil))

        Request.participated_in_directly_by(user).should_not include(request)
      end

      it "should NOT return requests with steps containing steps owned by the given user's group" do
        user.groups = [group]
        user.save

        request.steps.create!(attributes_for(:step).merge(:owner => create(:group, :name => Time.now.to_s, :email => "#{Time.now}@example.com"), :request => nil))
        request.steps.first.steps.create!(attributes_for(:step).merge(:owner => group, :request => request))

        Request.participated_in_directly_by(user).should_not include(request)
      end

      it "should return requests owned by the given user" do
        request = create(:request, deployment_coordinator_id: user.id)
        Request.participated_in_directly_by(user).should include(request)
      end

      it "should return requests for which the given user is the requestor" do
        request = create(:request, requestor: user)
        Request.participated_in_directly_by(user).should include(request)
      end
    end

    describe "#participated_in_by_group" do
      it "should return a request with steps owned by the given group" do
        request.steps.create!(attributes_for(:step).merge(:owner => group, :request => nil))
        Request.participated_in_by_group(group).should include(request)
      end

      it "should return a request containing a procedure with steps owned by the given group" do
        request.steps.create!(attributes_for(:step).merge(:owner => create(:user, :login => Time.now.to_s), :request => nil))
        request.steps.first.steps.create!(attributes_for(:step).merge(:owner => group, :request => request))
        Request.participated_in_by_group(group).should include(request)
      end

    end

    describe "#if part of a plan" do

      before(:each) do
        @request = create(:request)
        @request2 = create(:request)
        @plan_stage = create(:plan_stage)
        @plan = create(:plan, :plan_template => @plan_stage.plan_template)
        @plan2 = create(:plan, :plan_template => @plan_stage.plan_template)
        @plan_member = create(:plan_member, :request => @request, :stage => @plan_stage, :plan => @plan)
        @plan_member2 = create(:plan_member, :request => @request2, :stage => @plan_stage, :plan => @plan2)
      end

      it "should return requests belonging to a particular plan and stage" do
        results = Request.by_plan_id_and_plan_stage_id(@plan.id, @plan_stage.id)
        results.should include(@request)
      end

      it "should not return requests belonging to a different plan" do
        results = Request.by_plan_id_and_plan_stage_id(@plan.id, @plan_stage.id)
        results.should_not include(@request2)
      end

      Request::COLUMNS_FOR_NAMED_SCOPES.each do |id_column|
        model_name = id_column.gsub(/(\w+)_id/, '\1')
        describe "#with_#{id_column}" do
          before do
            Request.any_instance.stub(:check_if_able_to_create_request).and_return(true)
            @request_with_model = create(:request)
            if model_name == 'environment'
              @request_with_model.apps << [App.new(:name => Time.now.to_s)]
              @request_with_model.environment = @request_with_model.apps.first.environments.create!(attributes_for(:environment))
            else
              #@request_with_model.send("#{model_name}=", create(model_name.to_sym))
              @request_with_model.release=create(:release) if id_column == "release_id"
              #@request_with_model if id_column == "environment_id"
              @request_with_model.business_process=create(:business_process) if id_column == "business_process_id"
              @request_with_model.activity=create(:activity) if id_column == "activity_id"
              @request_with_model.owner=create(:user) if id_column == "owner_id"
              @request_with_model.requestor=create(:user) if id_column == "requestor_id"
            end
            @request_with_model.save!
            @request_without_model = create(:request)
          end

          it "should return the requests with the given #{id_column}" do
            pending "got not what expected"
            Request.send("with_#{id_column}", @request_with_model.send(id_column)).should == [@request_with_model]
          end
        end
      end

    end
  end


  describe "definitions" do
    context "user definitions" do
      let(:deployment_coordinator) { create(:user) }
      describe "#user" do
        it 'should return the deployment_coordinator' do
          request = create(:request, deployment_coordinator_id: deployment_coordinator.id)
          request.user.should == deployment_coordinator
        end
      end
      describe "#user=" do
        it "should return the deployment_coordinator" do
          request = create(:request, :user => deployment_coordinator)
          request.deployment_coordinator.should == deployment_coordinator
        end
      end
      describe "#user_id" do
        it "should return the deployment_coordinator_id" do
          request = create(:request, :deployment_coordinator => deployment_coordinator)
          request.deployment_coordinator_id = 13
          request.user_id.should == 13
        end
      end
      describe "#user_id=" do
        it "should return the deployment_coordinator_id" do
          request = create(:request, :user => deployment_coordinator)
          request.user_id = 13
          request.deployment_coordinator_id.should == 13
        end
      end
    end
    describe "when asking for the last successful deployment request for and application/environment combination" do
      before(:each) do
        Request.any_instance.stub(:check_if_able_to_create_request).and_return(true)
        @my_app = create(:app)
        @other_app = create(:app)
        @my_env = create(:environment)
        @other_env = create(:environment)
        @my_app.environments << @my_env
        @other_app.environments << @other_env
        @not_completed = create(:request, :apps => [@my_app], :environment => @my_env)
        @other_recent = create(:request, :apps => [@other_app], :environment => @other_env, :completed_at => Time.now)
        @my_most_recent = create(:request, :apps => [@my_app], :environment => @my_env, :completed_at => 3.days.ago)
      end

      it "should find the right stuff" do
        Request.last_successful_deploy_for_application_and_environment(@my_app.id, @my_env.id).should == @my_most_recent
      end
    end
    describe "#destroy" do
      before do
        @request = create(:request)
        ActivityLog.stub(:inscribe)
      end

      it "should destroy the request if it is created" do
        Request.all.should include(@request)
        @request.destroy
        Request.all.should_not include(@request)
      end

      it "should soft delete if the request is cancelled" do
        @request.aasm_state = 'cancelled'
        Request.all.should include(@request)
        @request.destroy
        Request.all.should include(@request)
        @request.deleted_at.should_not be_blank
        @request.should be_deleted
      end

      it "should soft delete if the request is completed" do
        @request.aasm_state = 'complete'
        Request.all.should include(@request)
        @request.destroy
        Request.all.should include(@request)
        @request.deleted_at.should_not be_blank
        @request.should be_deleted
      end
    end
    describe "deleting the request" do
      before do
        @request = create(:request)
        @request.aasm_state = 'cancelled'
        ActivityLog.stub(:inscribe)
      end

      it "should set deleted_at to now" do
        now = Time.now
        Time.stub(:now).and_return(now)
        @request.deleted_at.should be_nil
        @request.soft_delete!
        @request.reload
        @request.deleted_at.to_i.should == now.to_i
      end

      it "should be deleted" do
        @request.soft_delete!
        @request.should be_deleted
      end
    end

    describe "in_month - when asking for requests where created_at is set in a given month" do
      it "should not include a request that's outside this month by 1 second at the beginning" do
        barely_misses_it = create(:request, :created_at => Time.now.beginning_of_month - 1.second)
        #barely_misses_it.send(date_column).strftime('%H%M%S').should == '235959'
        Request.in_month.should_not include(barely_misses_it)
      end

      it "should not include a request that's outside the month by 1 second at the end" do
        barely_misses_it = create(:request, :created_at => Time.now.end_of_month + 1.second)
        #barely_misses_it.send(date_column).strftime('%H%M%S').should == '000000'
        Request.in_month.should_not include(barely_misses_it)
      end
    end

    %w(scheduled_at created_at).each do |date_column|
      describe "in_month - when asking for requests where #{date_column} is set in a given month" do
        describe "when no argument is passed" do
          it "should include a request that's in this month by 1 second at the end" do
            barely_makes_it = create(:request, date_column => Time.now.end_of_month)
            barely_makes_it.send(date_column).should_not be_nil
            #barely_makes_it.send(date_column).strftime('%H%M%S').should == '235959'
            Request.in_month.should include(barely_makes_it)
          end

          it "should include a request that's in this month by 1 second at the beginning" do
            barely_makes_it = create(:request, date_column => Time.now.beginning_of_month)
            #barely_makes_it.send(date_column).strftime('%H%M%S').should == '000000'
            Request.in_month.should include(barely_makes_it)
          end

        end

        describe "when giving a date" do
          before do
            @one_month_ago = create(:request, date_column => 1.month.ago)
            @this_month = create(:request, date_column => Time.now)
            @one_month_from_now = create(:request, date_column => 1.month.from_now)
          end

          it "should use the month of a date given" do
            Request.in_month(1.month.ago).should include(@one_month_ago)
            Request.in_month(1.month.ago).should_not include(@this_month)
            Request.in_month(1.month.ago).should_not include(@one_month_from_now)
          end

          it "should use the month of a date given" do
            Request.in_month(1.month.from_now).should_not include(@one_month_ago)
            Request.in_month(1.month.from_now).should_not include(@this_month)
            Request.in_month(1.month.from_now).should include(@one_month_from_now)
          end
        end
      end
    end

    describe ".find_by_number" do
      it "should delegate to find with the given number minus the base request number" do
        #GlobalSettings.stub(:[]).and_return(1000)
        #Request.should_receive(:find).with(20, {})
        Request.find_by_number(@request.number).should == @request
      end
    end
    #TODO may be reload is necessary before test
    describe "#add_log_comments" do
      it "should do nothing if given a blank comment string" do
        @request.log_comments.should be_blank
        @request.add_log_comments(:problem, '')
        @request.reload
        @request.log_comments.should be_blank
      end

      it "should include an upcased version of the given type in then formatted string" do
        @request.log_comments.should be_blank
        @request.add_log_comments(:problem, "it broke!")
        @request.log_comments.should include("PROBLEM")
      end

      it "should include the category name, if one exists" do
        @request.category = stub_model(Category, :name => "category")
        @request.log_comments.should be_blank
        @request.add_log_comments(:problem, "it broke!")
        @request.log_comments.should include("category")
      end

      it "should include the comments" do
        @request.log_comments.should be_blank
        @request.add_log_comments(:problem, "it broke!")
        @request.log_comments.should include("it broke!")
      end
    end
    describe '#to_param' do
      it "should return the request's number as a string" do
        @request.should_receive(:number).and_return(1111)
        @request.to_param.should == "1111"
      end
    end

    describe "#mailing_list" do
      let(:group_user){ create(:user, login: "group_user", email: "group_user@example.com") }
      let(:another_user){ create(:user, login: "another_user", email: "another_user@example.com") }

      it "should return all the email addresses of participants, email_recipients, and additional email addresses" do
        group.resources << group_user
        group.save!
        request.email_recipients << EmailRecipient.new(recipient: another_user)
        request.email_recipients << EmailRecipient.new(recipient: group)
        request.additional_email_addresses = "additional1@example.com, additional2@example.com"
        request.notify_on_request_participiant = true
        request.save!
        request.mailing_list.should include(group.email)
        request.mailing_list.should include(another_user.email)
        request.mailing_list.should include('additional1@example.com')
        request.mailing_list.should include('additional2@example.com')
      end

      it "should not contain duplicate email addresses" do
        request.email_recipients << EmailRecipient.new(recipient: user)
        request.additional_email_addresses = "user9@example.com, user9@example.com"
        request.steps << Step.new(owner: user)
        request.notify_on_request_participiant = true
        request.save!
        request.reload
        request.mailing_list.should include(user.email)
      end
    end

    describe "#email_recipient_ids_for" do
      describe "for users" do
        before do
          request.email_recipients << EmailRecipient.new(recipient: user)
          request.save!
        end

        it "should return all the user ids when passed any string, symbol or constant that can be easily converted to 'User'" do
          request.email_recipient_ids_for(:user).should == [user.id]
          request.email_recipient_ids_for('user').should == [user.id]
          request.email_recipient_ids_for('User').should == [user.id]
          request.email_recipient_ids_for(User).should == [user.id]
        end
      end

      describe "for groups" do
        before do
          request.email_recipients << EmailRecipient.new(recipient: group)
          request.save!
        end

        it "should return all the group ids when passed any string, symbol or constant that can be easily converted to 'Group'" do
          request.email_recipient_ids_for(:group).should == [group.id]
          request.email_recipient_ids_for('group').should == [group.id]
          request.email_recipient_ids_for('Group').should == [group.id]
          request.email_recipient_ids_for(Group).should == [group.id]
        end
      end
    end

    describe "#set_email_recipients" do
      before do
        @request = create(:request)
      end

      describe "for adding users" do
        before do
          @user = create(:user)
        end

        it "should create new email recipients for the given users" do
          @request.set_email_recipients(:user_ids => [@user.id.to_s])
          @request.email_recipients.first.recipient.should == @user
        end

        it "should not add duplicate users" do
          @request.set_email_recipients(:user_ids => [@user.id.to_s])
          @request.set_email_recipients(:user_ids => [@user.id.to_s])
          @request.email_recipients.count.should == 1
        end

        it "should remove users that are no longer used" do
          @request.email_recipients << EmailRecipient.new(:recipient => @user)
          @request.save!
          @request.email_recipients.should_not be_empty

          @request.set_email_recipients(:user_ids => [])
          @request.email_recipients(true).should be_empty
        end

        it "should not touch user recipients if nothing is passed for them" do
          @request.email_recipients << EmailRecipient.new(:recipient => @user)
          @request.save!
          @request.email_recipients.should_not be_empty

          @request.set_email_recipients(:group_ids => [])
          @request.email_recipients(true).should_not be_empty
        end
      end

      describe "for adding groups" do
        before do
          @group = create(:group)
        end

        it "should create new email recipients for the given groups" do
          @request.set_email_recipients(:group_ids => [@group.id.to_s])
          @request.email_recipients.first.recipient.should == @group
        end

        it "should not add duplicate groups" do
          @request.set_email_recipients(:group_ids => [@group.id.to_s])
          @request.set_email_recipients(:group_ids => [@group.id.to_s])
          @request.email_recipients.count.should == 1
        end

        it "should remove groups that are no longer used" do
          @request.email_recipients << EmailRecipient.new(:recipient => @group)
          @request.save!
          @request.email_recipients.should_not be_empty

          @request.set_email_recipients(:group_ids => [])
          @request.email_recipients(true).should be_empty
        end

        it "should not touch group recipients if nothing is passed for them" do
          @request.email_recipients << EmailRecipient.new(:recipient => @group)
          @request.save!
          @request.email_recipients.should_not be_empty

          @request.set_email_recipients(:user_ids => [])
          @request.email_recipients(true).should_not be_empty
        end
      end
    end
    describe "#current_phase_name" do
      before do
        @request = create(:request)
      end

      it "should return first currently running phase" do
        @request.stub(:in_process?).and_return(true)
        @request.steps = []
        create(:step, :request => @request, :aasm_state => :complete, :phase => create(:phase, :name => 'bad'))
        create(:step, :request => @request, :aasm_state => :in_process, :phase => create(:phase, :name => 'good'))
        @request.current_phase_name.should == 'good'
      end

      it "should return first currently running runtime phase when the step has one" do
        @request.stub(:in_process?).and_return(true)
        @request.steps = []
        create(:step, :request => @request, :aasm_state => :complete, :phase => create(:phase, :name => 'bad'))

        phase = Phase.create!(:name => 'good')
        runtime_phase = RuntimePhase.create!(:name => 'runtime', :phase => phase)
        create(:step, :request => @request, :aasm_state => :in_process, :phase => phase, :runtime_phase => runtime_phase)

        @request.current_phase_name.should == 'good:runtime'
      end

      it "should return N/A when request does not have a current step" do
        @request.steps = []
        create(:step, :request => @request, :aasm_state => :complete, :phase => create(:phase, :name => 'bad'))
        create(:step, :request => @request, :aasm_state => :complete, :phase => create(:phase, :name => 'also bad'))
        @request.current_phase_name.should == 'N/A'
      end

      it "should return None when the current step has no phase" do
        @request.steps = []
        create(:step, :request => @request, :aasm_state => :complete, :phase => create(:phase, :name => 'bad'))
        create(:step, :request => @request, :aasm_state => :in_process)
        @request.current_phase_name.should == 'None'
      end
    end
    describe "#email_recipients_for" do
      before do
        @request = create(:request)
        @user = create(:user)
        @group = create(:group)
        @request.email_recipients << EmailRecipient.new(:recipient => @user)
        @request.email_recipients << EmailRecipient.new(:recipient => @group)
      end

      it "should return all the participants when called with :all" do
        @request.email_recipients_for(:all).should include(@group)
        @request.email_recipients_for(:all).should include(@user)
      end

      it "should return all and only the user recipients when called with :user" do
        @request.email_recipients_for(:user).should == [@user]
      end

      it "should return all and only the group recipients when called with :group" do
        @request.email_recipients_for(:group).should == [@group]
      end
    end
    describe "#import_steps - paste_steps" do
      before do
        @request = create(:request)
        params = {"paste_data" => "assigned_to\tautomation\tBad Title\tEstimate\tName\tDescription\tComponent
        quire\tCapistrano Script\tCompleted\t0:10\t\"QA Sign off of release build (MR 84.0)\"\t\"MR Build: 2217738   \"\tcomponent name
        Group of Greatness\tCapistrano Script\t0.4375\t0:15\tPlain Name\t\tcomponent name
        DBA\tBadScript\t\t4:00\t\"Name with comma, properly imported\"\t\"\"\"Description with multiple lines and punctuation, maybe this will or wont work on LIVE MRDB, for any last minute updates.\"\"\"\tDoesn't match",
                  "commit" => "Create Steps", "id" => "1030"}
        @result = @request.import_steps(params["paste_data"])
      end
      it "should succeed in importing" do
        @result.should include("Success")
      end
      it "should import all the steps" do
        @request.steps.count.should equal 3
      end
      it "should ignore unrecognized components" do
        @request.steps.map(&:component_id).should include(nil)
      end
      it "should correctly trap commas and returns if quoted" do
        multi_line = "Description with multiple lines and punctuation, maybe this will or wont work on LIVE MRDB, for any last minute updates."
        comma_line = "Name with comma, properly imported"
        @request.steps.map(&:description).should include(multi_line)
        @request.steps.map(&:name).should include(comma_line)
      end
    end
    describe "#additional_email_addresses" do
      it "should split the string by commas, semicolons or whitespace and return an array" do
        @request.additional_email_addresses = "email1@example.com, email2@example.com, ;  ,,,, email3@example.com"
        @request.additional_email_addresses.should == %w(email1@example.com email2@example.com email3@example.com)
      end

      it "should return [] if the field is nil" do
        @request.additional_email_addresses = nil
        @request.additional_email_addresses.should == []
      end
    end
    describe "#package_content_tags" do
      it "uses the stored abbreviations" do
        contents = [
            stub_model(PackageContent, :abbreviation => "C"),
            stub_model(PackageContent, :abbreviation => "Con")
        ]
        @request.stub(:package_contents).and_return(contents)
        @request.package_content_tags.should == "C, Con"
      end
    end
    describe "when determining if a request is in process" do
      [:started, :hold, :problem].each do |in_process_state|
        it "should be in process when in the state #{in_process_state}" do
          @request.send(:aasm_state=, in_process_state.to_s)
          @request.should be_in_process
        end
      end
      [:complete, :pending].each do |not_in_process_state|
        it "should not be in process when in the state #{not_in_process_state}" do
          @request.send(:aasm_state=, not_in_process_state.to_s)
          @request.should_not be_in_process
        end
      end
    end
    describe "#template?" do
      it "should be true if the request has request template" do
        @request.request_template = RequestTemplate.new
        @request.should be_template
      end

      it "should be false if the request has no request template" do
        @request.request_template = nil
        @request.should_not be_template
      end
    end
    describe "when determining the total duration" do
      it "should return the differernce between completed_at and started_at in minutes as an integer" do
        start_time = Time.now
        @request.started_at = start_time
        @request.completed_at = start_time + 3.hours
        @request.total_duration.should == 180
      end
      it "should return 0 if completed_at is nil for started request" do
        start_time = Time.now
        @request.started_at = start_time
        @request.completed_at = nil
        @request.total_duration.should == 0
      end
      it "should return 0 if completed_at and started at is nil" do
        @request.started_at = nil
        @request.completed_at = nil
        @request.total_duration.should == 0
      end

    end
    describe "#calendar_time_source" do
      it "is :started_at when it has a value" do
        req = Request.new(:started_at => 1.hour.ago,
                          :scheduled_at => 1.hour.from_now,
                          :target_completion_at => 2.hours.from_now,
                          :created_at => 4.hours.ago)
        req.calendar_time_source.should == :started_at
      end
      it "is :scheduled_at when it has a value and started_at is nil" do
        req = Request.new(:started_at => nil,
                          :scheduled_at => 1.hour.from_now,
                          :target_completion_at => 2.hours.from_now,
                          :created_at => 4.hours.ago)
        req.calendar_time_source.should == :scheduled_at
      end
      it "is :target_completion_at when it has a value and started_at and scheduled_at are nil" do
        req = Request.new(:started_at => nil, :scheduled_at => nil,
                          :target_completion_at => 2.hours.from_now,
                          :created_at => 4.hours.ago)
        req.calendar_time_source.should == :target_completion_at
      end
      it "is nil otherwise" do
        req = Request.new(:started_at => nil, :scheduled_at => nil,
                          :target_completion_at => nil, :created_at => 4.hours.ago)
        req.calendar_time_source.should be_nil
      end
    end
    describe '#order_time' do
      before do
        @start_time = Time.now
        @schedule_time = 1.hour.ago
        @create_time = 2.hours.ago
      end

      it "should be the started_at column when it is not nil" do
        req = Request.new(:started_at => @start_time, :scheduled_at => @schedule_time, :created_at => @create_time)
        req.order_time.should == @start_time
      end

      it "should be the scheduled_at column when it is not nil but started_at is" do
        req = Request.new(:started_at => nil, :scheduled_at => @schedule_time, :created_at => @create_time)
        req.order_time.should == @schedule_time
      end

      it "should be the created_at column when started_at and scheduled_at are nil" do
        req = Request.new(:started_at => nil, :scheduled_at => nil, :created_at => @create_time)
        req.order_time.should == @create_time
      end
    end
    describe "#number" do
      it "should return the request's position plus the system's base request number" do
        GlobalSettings.stub(:[]).and_return(1000)
        @request.number.should == @request.id + 1000
      end
    end

    describe "#editable_by?" do
      it "should not be editable when the request is already started" do
        @request.stub(:already_started?).and_return(true)
        @request.should_not be_editable_by(@user)
      end

      it "should not be editable when the request is cancelled" do
        @request.aasm_state = 'cancelled'
        @request.should_not be_editable_by(@user)
      end
    end

    describe "deletable_by?" do
      before do
          @user = stub_model(User)
          @request.stub(:template?).and_return(false)
          @request.stub(:cancelled?).and_return(true)
      end

      it "should be false if the request is a template user can't destroy request" do
        @request.stub(:template?).and_return(true)
        @user.stub(:can?).and_return(false)
        @request.should_not be_deletable_by(@user)
      end

      it "should be true if the request is not a template user can destroy request" do
        @request.stub(:template?).and_return(false)
        @user.stub(:can?).and_return(true)
        @request.should be_deletable_by(@user)
      end

      it "should be false if the request is not a template and user can't destroy request" do
        @request.stub(:template?).and_return(false)
        @user.stub(:can?).and_return(false)
        @request.should_not be_deletable_by(@user)
      end

      it "should be false if user can destroy request and request is a template" do
        @request.stub(:template?).and_return(true)
        @user.stub(:can?).and_return(true)
        @request.should_not be_deletable_by(@user)
      end
    end

    describe ".create_consolidated_request" do
      it "should not blow up when passed in nil for request ids" do
        proc { Request.create_consolidated_request nil, nil }.should_not raise_error
      end
      context "when given valid ids" do
        before do
          Request.any_instance.stub(:check_if_able_to_create_request).and_return(true)
          Phase.destroy_all
          @phase1 = Phase.create! :name => "Phase 1"
          @phase2 = Phase.create! :name => "Phase 2"

          @user = create(:user)

          @activity = create(:activity)

          @request1 = create(:request_with_app, :activity => @activity)
          @r1_p1_step = @request1.steps.create! :owner => @user, :name => 'r1 p1'
          @r1_p1_step.phase = @phase1
          @r1_p1_step.save!
          @r1_p2_step = @request1.steps.create! :owner => @user, :name => 'r1 p2'
          @r1_p2_step.phase = @phase2
          @r1_p2_step.save!

          @request2 = create(:request, :activity => @activity)
          @r2_p1_step = @request2.steps.create! :owner => @user, :name => 'r2 p1'
          @r2_p1_step.phase = @phase1
          @r2_p1_step.save!

          @request_ids = [@request1.id, @request2.id]

          @consolidated_request = Request.create_consolidated_request(@request_ids, @user)
        end

        describe "the request" do
          it "should create a new request" do
            @consolidated_request.should be_a(Request)
          end

          it "should have the app and environment of the first request" do
            @consolidated_request.apps.first == @request1.apps.first
            @consolidated_request.environment.should == @request1.environment
          end

          it "should be named all the numbers of it's source requests" do
            @consolidated_request.name.should include "#{@request2.number}"
            @consolidated_request.name.should include "#{@request1.number}"
          end

          it "should be in the source requests' activity" do
            @consolidated_request.activity.should == @activity
          end

          it "should not be a new record" do
            @consolidated_request.should_not be_new_record
          end
        end
        describe "the request's steps" do
          before do
            @procedures = @consolidated_request.steps(true).select { |s| s.procedure? }
          end

          it "should have a procedure step for each of the phases on the given requests' steps" do
            @procedures.size.should == 2
          end

          it "should name the procedures after their respective phases" do
            @procedures.map { |p| p.name }.should include("Phase 1")
            @procedures.map { |p| p.name }.should include("Phase 2")
          end

          it "should add the steps to the procedure by phase" do
            get_name = proc { |s| s.name }

            phase1_procedure = @procedures.find { |p| p.name == "Phase 1" }
            phase1_procedure.steps.size.should == 2
            phase1_procedure.steps.map(&get_name).should include('r1 p1')
            phase1_procedure.steps.map(&get_name).should include('r2 p1')

            phase2_procedure = @procedures.find { |p| p.name == "Phase 2" }
            phase2_procedure.steps.map(&get_name).should include('r1 p2')
          end
        end
      end
    end
    describe ".status_filters_for_select" do
      it "should return an array of two-string-element arrays" do
        Request.status_filters_for_select.should be_all { |e| e.is_a?(Array) && e.size == 2 && e.all? { |ee| ee.is_a? String } }
      end

      it "should include ['Active', 'active']" do
        Request.status_filters_for_select.should include(%w(Active active))
      end

      it "should include pairs of [humanized state, state] for each aasm state" do
        Request.stub_chain(:aasm, :states).and_return([mock('state', :name => :initial), mock('state', :name => :later)])
        Request.status_filters_for_select.should include(%w(Initial initial))
        Request.status_filters_for_select.should include(%w(Later later))
      end
    end

    describe ".create_recurring_requests!" do
      let(:request_template) { create :request_template, recur_time: Time.now + 5.minutes }

      before do
        Request.any_instance.stub(:schedule_auto_start).and_return(true)
        RequestTemplate.stub(:recurring_at).and_return([request_template])
      end

      context "when it is the weekend" do
        before { Date.any_instance.stub(:weekday?).and_return(false) }

        it "should do nothing" do
          expect { Request.create_recurring_requests! }.not_to change { Request.count }
        end
      end

      context "when it is not the weekend" do
        before do
          Date.any_instance.stub(:weekday?).and_return(true)
          Request.any_instance.stub(:find_assigned_apps).and_return(build_stubbed(:app))
          Request.any_instance.stub(:is_visible?).and_return(true)
        end

        it "should create requests from templates set to recur in the current quarter hour" do
          expect { Request.create_recurring_requests! }.to change { Request.count }.by 1
        end

        it "should set auto_start to true" do
          Request.create_recurring_requests!

          expect(Request.last.auto_start).to be_truthy
        end

        it "should set the scheduled time to the templates recur time" do
          Request.create_recurring_requests!

          expect(Request.last.scheduled_at).to eq request_template.recur_time
        end

        it "should plan the request" do
          Request.create_recurring_requests!

          expect(Request.last).to be_planned
        end
      end
    end

    describe ".start_automatic_requests!" do
      pending 'This method does not in use' do
        before do
          @request = create(:request, :scheduled_at => 10.minutes.ago, :auto_start => true)
          create(:step, :request => @request)
          @request.stub(:finish!).and_return(true)
          @request.plan_it

          now = Time.parse('4:18')
          Time.stub(:now).and_return(now)
          Time.zone.stub(:now).and_return(now)
        end

        it "should start the automatic, planned requests that are scheduled within the current quarter hour" do
          @request.update_attribute(:scheduled_at, Time.parse('4:15'))
          Request.start_automatic_requests!
          @request.reload.should be_started
        end

        it "should start automatic, held requests that are scheduled within the current quarter hour" do
          @request.update_attributes(:scheduled_at => Time.parse('4:29'), :aasm_state => 'hold')
          Request.start_automatic_requests!
          @request.reload.should be_started
        end

        it "should not start automatic, planned requests scheduled before the current quarter hour" do
          @request.update_attribute(:scheduled_at, Time.parse('4:14'))
          Request.start_automatic_requests!
          @request.reload.should be_planned
        end

        it "should not start automatic, planned requests scheduled after the current quarter hour" do
          @request.update_attribute(:scheduled_at, Time.parse('4:30'))
          Request.start_automatic_requests!
          @request.reload.should be_planned
        end

        it "should not start if not planned or hold" do
          @request.update_attribute(:aasm_state, 'created')
          Request.start_automatic_requests!
          @request.reload.should be_created
        end

        it "should not start if not auto_start" do
          @request.update_attribute(:auto_start, false)
          Request.start_automatic_requests!
          @request.reload.should be_planned
        end
      end
    end
    describe "#start_request!" do
      before(:each) do
        @request = create(:request)
        @request.plan_it
        @request.steps << build(:step, :request => nil)
        @request.started_at = Time.now
        @request.scheduled_at = Time.now
        ActivityLog.stub(:inscribe)
      end

      it "should start the request" do
        @request.start_request!
        @request.should be_started
      end

      it "should set started_at if it isn't already set" do
        time = Time.now
        Time.stub(:now).and_return(time)
        @request.started_at = nil
        @request.scheduled_at = Time.now
        @request.start_request!
        @request.started_at.should == time
      end

      it "should prepare the steps for execution" do
        @request.should_receive(:prepare_steps_for_execution)
        @request.start_request!
      end

      it "should finish if all of its steps are complete" do
        @request.steps.first.update_attribute(:aasm_state, 'complete')
        @request.should_receive(:finish!)
        @request.start_request!
      end
    end

    describe "#steps_execution_time" do
      before(:each) do
        @request = create(:request)
        @activity_log = create(:activity_log, :request => @request)
        @step_1 = create(:step, :request => @request, :should_execute => true, :name => 'Step #1 (with special characters at name')
      end
      it "should call to steps_execution_time with-out exception" do
        expect { @request.steps_execution_time }.to_not raise_error
      end
    end

  end

  describe "state transition" do
    describe "planning the request" do
      before do
        @request = create(:request)
        @request.aasm_state = 'created'
        ActivityLog.stub(:inscribe)
      end

      it "should plan the request" do
        @request.plan_it!.should be_truthy
        @request.should be_planned
      end

      it "should set planned_at to the current time" do
        @request.plan_it!
        @request.planned_at.should_not be_blank
      end
    end
    describe "reopening the request" do
      before do
        user = create(:user)
        @request = create(:request,
                          :scheduled_at => 0.ago,
                          :started_at => 0.ago,
                          :target_completion_at => 1.hour.from_now,
                          :completed_at => 1.hour.from_now)
        create(:step, :request_id => @request.id)
        @request.plan_it!
        @request.start!
        ActivityLog.stub(:inscribe)
        @request.finish!
      end

      it "should set the request to planned" do
        @request.should be_complete
        @request.reopen!
        @request.should be_planned
      end

      it "should clear out the scheduled time" do
        @request.scheduled_at.should_not be_nil
        @request.reopen!
        @request.scheduled_at.should be_nil
      end

      it "should clear out the started time" do
        @request.started_at.should_not be_nil
        @request.reopen!
        @request.started_at.should be_nil
      end

      it "should clear out the target completion time" do
        @request.target_completion_at.should_not be_nil
        @request.reopen!
        @request.target_completion_at.should be_nil
      end

      it "should clear out the completed time" do
        @request.completed_at.should_not be_nil
        @request.reopen!
        @request.completed_at.should be_nil
      end
      describe "when determing if a request has already started" do
        [:created, :planned].each do |not_started_state|
          it "should be already started if it is not in the state #{not_started_state}" do
            @request.send(:aasm_state=, not_started_state.to_s)
            @request.should_not be_already_started
          end
        end
      end
    end
  end

  describe "code in file Step_Container" do
    describe "when iterating through each step phase of a request" do
      before(:each) do
        @request = create(:request)
        @step1 = create(:step, :request => @request, :different_level_from_previous => true)
        @step2 = create(:step, :request => @request, :different_level_from_previous => false)
        @step3 = create(:step, :request => @request, :different_level_from_previous => true)
      end

      it "should group steps into phases and yield phases to the block as an array of steps" do
        results = []
        @request.each_step_phase do |sp|
          results << sp
        end

        results.should == [[@step1, @step2], [@step3]]
      end
    end
  end

  describe '#nullify_child_relation' do
    it 'nullifies foreign key and association' do
      request = create(:request)
      self_referential_request = create(:request, parent_request_origin: request)
      request.destroy
      self_referential_request.reload
      expect(self_referential_request.parent_request_origin).to eq nil
      expect(self_referential_request.parent_request_id).to eq nil
      expect{ Request.find(request.id) }.to raise_error ActiveRecord::RecordNotFound
    end
  end

  describe '#check_deployment_window_event' do
    let(:request) { build :request }
    let(:policy)  { double 'policy'}

    it 'should call policy\'s #check_deployment_window_event' do
      RequestPolicy::DeploymentWindowValidator::Base.stub(:new).and_return policy
      policy.should_receive :check_deployment_window_event
      request.send :check_deployment_window_event
    end
  end

  describe '#start and #finish' do
    let(:scheduled_at) { Time.now }
    let(:request) { build :request, scheduled_at: scheduled_at, estimate: 5 * 60 }

    specify { request.start.should eq scheduled_at }
    specify { request.finish.should eq scheduled_at + 5.hours }
  end

  context 'notices' do
    describe '#notices' do
      let(:dwe)           { dws_prevent.events.first }
      let(:dws_prevent)   { create :deployment_window_series, environment_ids: [env_opened.id], behavior: 'prevent' }
      let(:env_opened)    { build :environment, deployment_policy: 'opened' }

      describe 'for request in non-started state with notices' do
        it 'return errors with dwe and related stuff on planning a request' do
          pending 'method works unexpected'
          request = build(:request)
          policy = double('RequestPolicy::DeploymentWindowValidator::Base', check_deployment_window_event: 'errors')
          RequestPolicy::DeploymentWindowValidator::Base.stub(:new).and_return(policy)
          expect(request.notices).to eq 'errors'
        end
      end
    end

    describe '#has_notices?' do
      it 'should return true in case any notices' do
        request.stub(:notices).and_return [mock('notices')]
        expect(request.has_notices?).to be_truthy
      end

      it 'should return false in case any notices' do
        expect(request.has_notices?).to be_falsey
      end
    end
  end

  describe '#on_closed_environment' do
    let(:env_closed)          { create :environment, :closed }
    let(:env_opened)          { create :environment, :opened }
    let(:request_on_opened)   { create(:request, environment: env_opened) }
    let(:requests_on_closed)  { create_list(:request, 3, environment: env_closed) }

    it 'should return only requests on closed env' do
      expect(requests_on_closed.count).to eq 3
      Request.on_closed_environment.should =~ requests_on_closed
    end

    it 'should not include request on opened env' do
      request_on_opened.environment.should be_opened
      expect(Request.on_closed_environment).not_to include request_on_opened
    end
  end

  describe '#with_auto_start_errors' do
    let(:request) { create :request, automatically_start_errors: 'Abra ca dabra' }

    it 'should return request with auto start errors' do
      expect(Request.with_auto_start_errors).to eq [request]
    end
  end

  describe '#is_visible?' do
    it 'returns true when user is root' do
      request = Request.new
      user = create :user, :root

      expect(request.is_visible?(user)).to be_truthy
    end

    it 'returns true when request have no apps' do
      request = Request.new
      user = create :user, :non_root

      expect(request.is_visible?(user)).to be_truthy
    end

    it 'returns true when request have user assigned apps' do
      pending 'the spec runs successfully when it runs alone'
      request = Request.new
      user = create :user, :non_root
      expect(request).to receive(:app_ids).
        and_return([1])

      expect(request).to receive(:user_apps_has_request_apps?).
                           with([]).
                           and_return([1])

      expect(request.is_visible?(user)).to be_truthy
    end

    it 'returns true when request is in state "created" and user has "view_created_requests_list" permission' do
      request = Request.new
      user = create :user, :non_root
      expect(request).to receive(:created?).
        and_return(true)

      expect(user).to receive(:can?).
        with(:view_created_requests_list, request).
        and_return(true)

      expect(request.is_visible?(user)).to be_truthy
    end

    it 'returns true when request is not in state "created" and user does not have "view_created_requests_list" permission' do
      request = Request.new
      user = create :user, :non_root
      expect(request).to receive(:created?).
        and_return(false)

      allow(user).to receive(:can?).
        with(:view_created_requests_list, request).
        and_return(false)

      expect(request.is_visible?(user)).to be_truthy
    end

    it 'returns false when request is in state "created" but user does not have "view_created_requests_list" permission' do
      request = Request.new
      user = create :user, :non_root
      expect(request).to receive(:created?).
        and_return(true)

      expect(user).to receive(:can?).
        with(:view_created_requests_list, request).
        and_return(false)

      expect(request.is_visible?(user)).to be_falsey
    end

  end

  describe '#granter_type' do
    it 'returns environment type if it is request' do
      request = create(:request)
      expect(request.granter_type).to eq :environment
    end

    it 'returns application type if it is request template' do
      request_template = create(:request_template)
      expect(request_template.request.granter_type).to eq :application
    end
  end

end
