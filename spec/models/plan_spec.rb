################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2015
# All Rights Reserved.
################################################################################
require 'spec_helper'

describe Plan do
  after(:all) { cleanup_models }

  describe 'validations' do

    before(:each) do
      @plan = build(:plan)
    end

    it 'should create a new instance given valid attributes' do
      @plan.should be_valid
    end

    it { @plan.should validate_presence_of(:name) }
    it { @plan.should validate_presence_of(:plan_template) }
    it { @plan.should ensure_length_of(:name).is_at_most(255) }

    describe 'attribute normalizations' do
      it { should normalize_attribute(:name).from('  Hello  ').to('Hello') }
      it { should normalize_attribute(:description).from('  Hello  ').to('Hello') }
    end

    describe 'associations' do
      it 'should have many' do
        @plan.should have_many(:plan_routes)
        @plan.should have_many(:routes)
        @plan.should have_many(:plan_teams)
        @plan.should have_many(:linked_items)
        @plan.should have_many(:members)
        @plan.should have_many(:requests)
        @plan.should have_many(:runs)
        @plan.should have_many(:stage_dates)
        @plan.should have_many(:teams)
        @plan.should have_many(:tickets)
        @plan.should have_many(:plan_env_app_dates)
        @plan.should have_many(:queries)
        @plan.should have_many(:plan_stage_instances)
        @plan.should have_many(:constraints)
      end
      it 'should belong to' do
        @plan.should belong_to(:plan_template)
        @plan.should belong_to(:release)
        @plan.should belong_to(:release_manager)
        @plan.should belong_to(:project_server)
      end

      describe 'should validate existance of project server' do
        before(:each)do
          @persisted_project_server = create :project_server
          @message = 'does not exist'
        end

        it 'should be valid for persisted project server' do
          @plan.project_server = @persisted_project_server
          expect(@plan.valid?).to be_truthy
        end

        it 'should not be valid for not exists project server' do
          fake_project_server = build :project_server
          fake_project_server.id = @persisted_project_server.id + 1
          @plan.project_server = fake_project_server

          expect(@plan.valid?).to be_falsey
          expect(@plan.errors.messages[:project_server_id]).not_to be_empty
          expect(@plan.errors.messages[:project_server_id].first).to eq @message
        end

        it 'should be valid for nil project server' do
          @plan.project_server = nil
          expect(@plan.valid?).to be_truthy
        end
      end

      describe 'should validate existance of release manager' do
        before(:each)do
          @persisted_release_manager = create :user
          @message = 'does not exist'
        end

        it 'should be valid for release manager' do
          @plan.project_server = @persisted_project_server
          expect(@plan.valid?).to be_truthy
        end

        it 'should not be valid for not exists release manager' do
          fake_release_manager = build :user
          fake_release_manager.id = @persisted_release_manager.id + 1
          @plan.release_manager = fake_release_manager

          expect(@plan.valid?).to be_falsey
          expect(@plan.errors.messages[:release_manager_id]).not_to be_empty
          expect(@plan.errors.messages[:release_manager_id].first).to eq @message
        end

        it 'should be valid for nil release manager' do
          @plan.release_manager = nil
          expect(@plan.valid?).to be_truthy
        end
      end
    end
  end

  describe 'association handlers' do

    before(:each) do
      @plan = create(:plan)
    end

    describe 'accepts nested attributes for associated objects:' do
      describe 'release creation' do
        it { expect { create(:plan, :release_attributes => attributes_for(:release)) }.to change(Release, :count).by(1) }
        it { expect { create(:plan, :release_attributes => attributes_for(:release, :name => '')) }.to_not change(Release, :count) }
      end
    end

    # we have an after_update hook that looks for forms that have been cleared by the
    # user and, because they are empty, might not trigger the proper clearing action
    it 'should present current value of team_ids or look it up from associated teams' do
      @team = create(:team, :name => 'DEV')
      @team2 = create(:team, :name => 'QA')
      @plan.teams << [@team, @team2]
      @plan.teams.count.should == 2
      @plan.team_ids.length.should == 2
      @plan.team_ids.should include(@team.id)
      @plan.team_ids.should include(@team2.id)
    end

    # we often nest team_ids in forms for plans, and we want to be able to set them
    # with a simple form property rather than a more complex nested attribute
    it 'should save related teams if passed ids to team_id' do
      @team = create(:team, :name => 'DEV')
      @team2 = create(:team, :name => 'QA')
      @plan.team_ids = [@team.id, @team2.id]
      @plan.teams.count.should == 2
      @plan.team_ids.should include(@team.id)
      @plan.team_ids.should include(@team2.id)
    end

    # we have an attribute team_ids used by forms (instead of nested objects) that we
    # want to clear teams when it is blank
    it 'should clear related objects if passed empty array for ids after update' do
      @team = create(:team, :name => 'QA')
      @plan.teams << @team
      @plan.teams.count.should == 1
      @plan.update_attributes(:team_ids => '')
      @plan.teams.count.should == 0
    end

  end

  describe 'convenience setters for rest' do

    before(:each) do
      @plan = create(:plan)
    end

    # rest interface convenience property for passing a plan_template_name
    it 'should find and associate a plan template if given a template name' do
      # create a new one and assign its name to the accessor for handling name lookups
      @template = create(:plan_template, :name => 'Deploy Template for Lookup')
      @plan.update_attributes(:name => 'Lookup Test', :plan_template_name => 'Deploy Template for Lookup')
      @plan.should be_valid
      @plan.plan_template.should == @template
    end

    # rest interface convenience property for passing a plan_template_name error message handling
    it 'should give a proper error message when it fails to find and associate a plan template if given a template name' do
      # create a new one and assign its name to the accessor for handling name lookups
      @template = create(:plan_template, name: 'Deploy Template for Lookup')
      @plan.update_attributes(name: 'Lookup Test', plan_template_name: 'NOT TO BE FOUND')
      expect(@plan).to_not be_valid
      expect(@plan.plan_template).to_not eq(@template)
      expect(@plan.errors[:plan_template].size).to eq(1)
      expect(@plan.errors[:plan_template_name].size).to eq(1)
    end

    # rest interface convenience property for passing a plan_template_name
    it 'should find and associate a release if given a release name' do
      # create a new one and assign its name to the accessor for handling name lookups
      @release = create(:release, :name => 'Release for Lookup')
      @plan.update_attributes(:name => 'Lookup Test',
                              :plan_template => create(:plan_template),
                              :release_name => 'Release for Lookup')
      @plan.should be_valid
      @plan.release.should == @release
    end

    # rest interface convenience property for passing a plan_template_name error message handling
    it 'should give a proper error message when it fails to find and associate a release if given a release name' do
      # create a new one and assign its name to the accessor for handling name lookups
      @release = create(:release, name: 'Release for Lookup')
      @plan.update_attributes(name: 'Lookup Test',
                              plan_template: create(:plan_template),
                              release_name: 'BAD NAME NOT FOUND')
      expect(@plan).to_not be_valid
      expect(@plan.release).to_not eq(@release)
      expect(@plan.errors[:release_name].size).to eq(1)
    end
  end

  describe 'creation variations: ' do
    describe 'from a template with no stages' do
      before(:each) do
        @plan_template = create(:plan_template)
        @plan = create(:plan, :plan_template => @plan_template)
      end
      it 'should be valid with no stages' do
        @plan.should be_valid
        @plan.stages.should == []
      end
    end
    describe 'from a template with stages' do
      before(:each) do
        @plan_template = create(:plan_template)
        @plan_stage1 = create(:plan_stage, :plan_template => @plan_template)
        @plan_stage2 = create(:plan_stage, :plan_template => @plan_template)
        @plan = create(:plan, :plan_template => @plan_template)
      end
      it 'should be valid with the right number of stages' do
        @plan.should be_valid
        @plan.stages.should include(@plan_stage1)
        @plan.stages.should include(@plan_stage2)
      end
    end

  end

  # FIXME: Should be moved to cucumber or some other less dependent medium -- to many
  # classes to depend on for a unit test -- consider mocks too
  # this touches a lot of classes and might be better refactored with mocks
  # if it proves fragile or hard to keep running so that just the cycling through stages
  # is tested and the calling of this one function
  # describe "from a template with stages and related request templates" do
  #
  # before(:each) do
  #
  # @user = create(:user)
  # User.stub(:current_user).and_return(@user)
  #
  # @request_template_1 = create(:request_template)
  # @request_template_2 = create(:request_template)
  # @request_template_3 = create(:request_template)
  # @request_template_4 = create(:request_template)
  #
  # @plan_template = create(:plan_template)
  # @plan_stage_1 = create(:plan_stage, :plan_template => @plan_template)
  # @plan_stage_2 = create(:plan_stage, :plan_template => @plan_template)
  #
  # @plan_stage_1.request_templates << [@request_template_1, @request_template_2]
  # @plan_stage_2.request_templates << [@request_template_3, @request_template_4]
  #
  # @plan = create(:plan, :plan_template => @plan_template)
  #
  # end
  #
  # it "should be valid with the right number of requests created" do
  # @plan.should be_valid
  # @plan.stages.count.should == 2
  # @plan.requests.count.should == 4
  # end
  #
  # end

  # turned off until 2.6 state machine review
  # describe "from an autostart template with stages and related request templates" do
  # before(:each) do
  #
  # @user = create(:user)
  # User.stub(:current_user).and_return(@user)
  # @environment1 = create(:environment)
  #
  # @request1 = create(:request, :environment => @environment1)
  # @request2 = create(:request, :environment => @environment1)
  # @request3 = create(:request, :environment => @environment1)
  #
  # @step1 = create(:step, :request => @request1, :owner => @user)
  # @step2 = create(:step, :request => @request2, :owner => @user)
  # @step3 = create(:step, :request => @request3, :owner => @user)
  #
  # @request_template_1 = create(:request_template, :request => @request1)
  # @request_template_2 = create(:request_template, :request => @request2)
  # @request_template_3 = create(:request_template, :request => @request3)
  #
  # @plan_template = create(:plan_template, :is_automatic => true)
  # @plan_stage_1 = create(:plan_stage, :plan_template => @plan_template, :auto_start => true)
  # @plan_stage_2 = create(:plan_stage, :plan_template => @plan_template, :auto_start => true)
  #
  # @plan_stage_1.request_templates << [@request_template_1, @request_template_2]
  # @plan_stage_2.request_templates << @request_template_3
  #
  # @plan = create(:plan, :plan_template => @plan_template)
  #
  # end
  # it "should be valid with the right number of requests created" do
  # @plan.should be_valid
  # @plan.stages.count.should == 2
  # @plan.requests.count.should == 3
  # @plan.stages.first.requests.first.aasm_state.should == 'started'
  # @plan.stages.first.requests.last.aasm_state.should == 'started'
  # end
  # end
  #
  # describe "from an non-autostart template with stages marked auto_start and related request templates" do
  # before(:each) do
  #
  # @user = create(:user)
  # User.stub(:current_user).and_return(@user)
  # @environment1 = create(:environment)
  #
  # @request1 = create(:request, :environment => @environment1)
  # @request2 = create(:request, :environment => @environment1)
  # @request3 = create(:request, :environment => @environment1)
  #
  # @step1 = create(:step, :request => @request1, :owner => @user)
  # @step2 = create(:step, :request => @request2, :owner => @user)
  # @step3 = create(:step, :request => @request3, :owner => @user)
  #
  # @request_template_1 = create(:request_template, :request => @request1)
  # @request_template_2 = create(:request_template, :request => @request2)
  # @request_template_3 = create(:request_template, :request => @request3)
  #
  # @plan_template = create(:plan_template, :is_automatic => false)
  # @plan_stage_1 = create(:plan_stage, :plan_template => @plan_template, :auto_start => true)
  # @plan_stage_2 = create(:plan_stage, :plan_template => @plan_template, :auto_start => true)
  #
  # @plan_stage_1.request_templates << [@request_template_1, @request_template_2]
  # @plan_stage_2.request_templates << @request_template_3
  #
  # @plan = create(:plan, :plan_template => @plan_template)
  #
  # end
  # it "should be valid with the right number of requests created" do
  # @plan.should be_valid
  # @plan.stages.count.should == 2
  # @plan.requests.count.should == 3
  # @plan.stages.first.requests.first.aasm_state.should == 'created'
  # @plan.stages.first.requests.last.aasm_state.should == 'created'
  # end
  # end
  #end

  describe 'named scopes' do
    before(:each) do
      Plan.destroy_all
    end

    describe '#deleted' do
      it 'should return all plans in a deleted state' do
        plan = create(:plan, aasm_state: 'cancelled')
        plan.delete!
        Plan.deleted.should include(plan)
      end
      it 'should not return plans in a created state' do
        plan = create(:plan, aasm_state: 'created')
        Plan.deleted.should_not include(plan)
      end
    end

    describe '#not_deleted' do
      it 'should return all plans in a not deleted state' do
        plan1 = create(:plan, aasm_state: 'created')
        plan2 = create(:plan, aasm_state: 'archived')
        Plan.not_deleted.should match_array([plan1,plan2])
      end
      it 'should not return plans in a deleted state' do
        plan = create(:plan, aasm_state: 'cancelled')
        plan.delete!
        Plan.not_deleted.should_not include(plan)
      end
    end

    describe '#archived' do
      it 'should return all plans in a archived state' do
        plan = create(:plan, aasm_state: 'archived')
        Plan.archived.should include(plan)
      end
      it 'should not return plans in a created state' do
        plan = create(:plan, aasm_state: 'created')
        Plan.archived.should_not include(plan)
      end
    end

    describe '#functional' do
      it 'should return all plans in a functional (not archived or deleted) state' do
        plan = create(:plan, :aasm_state => 'created')
        Plan.functional.should include(plan)
      end
      it 'should not return plans in a deleted or archived state' do
        plan = create(:plan, :aasm_state => 'cancelled')
        plan.delete!
        plan2 = create(:plan, :aasm_state => 'archived')
        Plan.functional.should_not include(plan)
        Plan.functional.should_not include(plan2)
      end
    end

    describe '#having_release_date' do
      it 'should return all plans that have a release date' do
        plan = create(:plan, :release_date => Time.now)
        Plan.having_release_date.should include(plan)
      end
      it 'should not return plans that do not have a release date' do
        plan = create(:plan, :release_date => nil)
        Plan.having_release_date.should_not include(plan)
      end
    end

    describe '#by_plan_template_type' do
      it 'should return all plans that belong to the specified template type' do
        plan_template1 = create(:plan_template, :template_type => 'continuous_integration')
        plan1 = create(:plan, :plan_template => plan_template1, :release_date => nil)
        plan_template2 = create(:plan_template, :template_type => 'deploy')
        plan2 = create(:plan, :plan_template => plan_template2, :release_date => nil)
        results = Plan.by_plan_template_type('continuous_integration')
        results.should include(plan1)
        results.should_not include(plan2)
        # test the filtered method too
        results = Plan.filtered({:plan_type => ['deploy']})
        results.should include(plan2)
        results.should_not include(plan1)
      end
    end

    describe '#not_including_id' do
      it 'should return all plans not including a passed id' do
        plan = create(:plan)
        plan2 = create(:plan)
        id_to_exclude = plan2.id
        Plan.not_including_id(id_to_exclude).last.id.should_not == id_to_exclude
      end
    end

    describe '#by_uppercase_name' do
      it 'should return all plans with a case insensitive name match' do
        plan = create(:plan, :name => 'Test Camel Case Name')
        Plan.by_uppercase_name('test camel case name').first.name == 'Test Camel Case Name'
      end
    end

    describe '#by_aasm_state' do
      it 'should return all plans included in a set of aasm states' do
        plan1 = create(:plan, :aasm_state => 'created')
        plan2 = create(:plan, :aasm_state => 'archived')
        results = Plan.by_aasm_state('created')
        results.should include(plan1)
        results.should_not include(plan2)
        results.count.should == 1
        # test the filtered method too
        results = Plan.filtered({:aasm_state => ['archived']})
        results.should include(plan2)
        results.should_not include(plan1)
      end
    end

    describe '#by_release' do
      it 'should return all plans linked to a particular release manager' do
        release1 = create(:release)
        release2 = create(:release)
        plan1 = create(:plan, :release => release1)
        plan2 = create(:plan, :release => release2)
        results = Plan.by_release([release1.id])
        results.should include(plan1)
        results.should_not include(plan2)
        results.count.should == 1
        results = Plan.by_release([release1.id, release2.id])
        results.count.should == 2
        # test the filtered method too
        results = Plan.filtered({:release_id => [release1.id]})
        results.should include(plan1)
        results.should_not include(plan2)
      end
    end

    describe '#by_release_manager' do
      it 'should return all plans linked to a particular set of releases' do
        release_manager1 = create(:user)
        release_manager2 = create(:user)
        plan1 = create(:plan, :release_manager => release_manager1)
        plan2 = create(:plan, :release_manager => release_manager2)
        results = Plan.by_release_manager([release_manager1.id])
        results.should include(plan1)
        results.should_not include(plan2)
        results.count.should == 1
        results = Plan.by_release_manager([release_manager1.id, release_manager2.id])
        results.count.should == 2
        # test the filtered method too
        results = Plan.filtered({:release_manager_id => [release_manager1.id]})
        results.should include(plan1)
        results.should_not include(plan2)
      end
    end

    describe '#by_stage' do
      it 'should return plans with a particular stage' do
        plan_template1 = create(:plan_template, :template_type => 'continuous_integration')
        plan_stage1 = create(:plan_stage, :plan_template => plan_template1)
        plan_stage2 = create(:plan_stage, :plan_template => plan_template1)
        plan1 = create(:plan, :plan_template => plan_template1, :aasm_state => 'created')
        plan2 = create(:plan, :plan_template => plan_template1, :aasm_state => 'created')
        plan_template2 = create(:plan_template, :template_type => 'continuous_integration')
        plan_stage3 = create(:plan_stage, :plan_template => plan_template2)
        plan_stage4 = create(:plan_stage, :plan_template => plan_template2)
        plan3 = create(:plan, :plan_template => plan_template2, :aasm_state => 'created')
        plan4 = create(:plan, :plan_template => plan_template2, :aasm_state => 'created')
        results = Plan.by_stage([plan_stage1.id])
        results.count.should == 2
        results.should include(plan1)
        results.should include(plan2)
        results.should_not include(plan3)
        results.should_not include(plan4)
        results = Plan.by_stage([plan_stage1.id, plan_stage2.id])
        results.should include(plan1)
        results.should_not include(plan4)
        results.all.size.should == 4
        results = Plan.by_stage([plan_stage1.id, plan_stage3.id])
        results.all.size.should == 4
        # test the filtered method too
        results = Plan.filtered({:stage_id => [plan_stage1.id]})
        results.should include(plan1)
        results.should_not include(plan3)
      end
    end

    describe '#by_team' do
      it 'should return all plans linked to a particular team' do
        team1 = create(:team)
        team2 = create(:team)
        plan1 = create(:plan)
        plan2 = create(:plan)
        plan1.teams << team1
        plan1.teams << team2
        plan2.teams << team2
        results = Plan.by_team([team1.id])
        results.should include(plan1)
        results.should_not include(plan2)
        results.all.size.should == 1
        results = Plan.by_team([team1.id, team2.id])
        results.should include(plan1)
        results.should include(plan2)
        results.all.size.should == 3
        # test the filtered method too
        results = Plan.filtered({:team_id => [team1.id]})
        results.should include(plan1)
        results.should_not include(plan2)
      end
    end

    describe '#by_application' do
      it 'should return all plans linked to a particular application' do
        user = create(:user)
        User.stub(:current_user).and_return(user)
        request1 = create(:request_with_app)
        request3 = create(:request_with_app)
        application1 = request1.apps.first
        application2 = request3.apps.first
        application2.environments << request1.environment
        request2 = create(:request, apps: [application1, application2], environment_id: request1.environment.id)
        plan_template = create(:plan_template)
        stage = create(:plan_stage, :plan_template => plan_template)
        plan1 = create(:plan, :name => 'My Save Test 1', :plan_template => plan_template)
        plan_member1 = create(:plan_member, :plan => plan1, :stage => stage)
        plan2 = create(:plan, :name => 'My Save Test 2', :plan_template => plan_template)
        plan_member2 = create(:plan_member, :plan => plan2, :stage => stage)
        plan3 = create(:plan, :name => 'My Save Test 3', :plan_template => plan_template)
        plan_member3 = create(:plan_member, :plan => plan3, :stage => stage)
        plan_member1.request = request1
        plan_member2.request = request2
        plan_member3.request = request3
        results = Plan.by_application([application1.id])
        results.should include(plan1)
        results.should include(plan2)
        results.should_not include(plan3)
        results.all.size.should == 2
        results = Plan.by_application([application1.id, application2.id])
        results.all.size.should == 4
        # test the filtered method too
        results = Plan.filtered({:app_id => [application1.id]})
        results.should include(plan1)
        results.should_not include(plan3)
      end
    end

    describe '#by_environment' do
      it 'should return all plans linked to a particular environment' do
        user = create(:user)
        User.stub(:current_user).and_return(user)
        environment1 = create(:environment)
        environment2 = create(:environment)
        request1 = create(:request, :environment => environment1)
        request2 = create(:request, :environment => environment2)
        plan_template = create(:plan_template)
        stage = create(:plan_stage, :plan_template => plan_template)
        plan1 = create(:plan, :name => 'My Save Test 1', :plan_template => plan_template)
        plan_member1 = create(:plan_member, :plan => plan1, :stage => stage)
        plan2 = create(:plan, :name => 'My Save Test 2', :plan_template => plan_template)
        plan_member2 = create(:plan_member, :plan => plan2, :stage => stage)
        plan_member1.request = request1
        plan_member2.request = request2
        results = Plan.by_environment([environment1.id.to_s])
        results.should include(plan1)
        results.should_not include(plan2)
        results.all.size.should == 1
        results = Plan.by_environment([environment1.id, environment2.id])
        results.all.size.should == 2
        # test the filtered method too
        results = Plan.filtered({:environment_id => [environment1.id]})
        results.should include(plan1)
        results.should_not include(plan2)
      end
    end

    # I want to exercise this code to be sure it remains in place, but I am
    # not entirely sure if it needs to be tested in any deeper way as this
    # scope is just an include
    describe '#preloaded_with_associations' do
      it 'should return a plan with related associations joined for efficient display' do
        team1 = create(:team)
        plan1 = create(:plan)
        plan1.teams << team1
        result = Plan.preloaded_with_associations.find(plan1.id)
        result.should == plan1
        result.teams.first.try(:name).should == team1.name
      end
    end

    describe '#by_plan_template' do
      it 'should return plans with a particular plan template' do
        plan_template1 = create(:plan_template, :template_type => 'continuous_integration')
        plan_stage1 = create(:plan_stage, :plan_template => plan_template1)
        plan_stage2 = create(:plan_stage, :plan_template => plan_template1)
        plan1 = create(:plan, :plan_template => plan_template1, :aasm_state => 'created')
        plan2 = create(:plan, :plan_template => plan_template1, :aasm_state => 'created')
        plan_template2 = create(:plan_template, :template_type => 'continuous_integration')
        plan_stage3 = create(:plan_stage, :plan_template => plan_template2)
        plan_stage4 = create(:plan_stage, :plan_template => plan_template2)
        plan3 = create(:plan, :plan_template => plan_template2, :aasm_state => 'created')
        plan4 = create(:plan, :plan_template => plan_template2, :aasm_state => 'created')
        results = Plan.by_plan_template([plan_template1.id])
        results.count.should == 2
        results.should include(plan1)
        results.should include(plan2)
        results.should_not include(plan3)
        results.should_not include(plan4)
        results = Plan.by_plan_template([plan_template1.id, plan_template2.id])
        results.should include(plan1)
        results.should include(plan4)
        results.all.size.should == 4
        # test the filtered method too
        results = Plan.filtered({:plan_template_id => [plan_template1.id]})
        results.should include(plan1)
        results.should include(plan2)
        results.should_not include(plan3)
        results.should_not include(plan4)
      end
    end

  end

  # because there is so much state needed for some of these named scopes to work
  # I wove most of the correct params cases into the named scoped tests above,
  # but here are some nil, etc. edge cases that should exercise the whole function
  describe 'filter method edge cases' do
    before(:each) do
      @plan1 = create(:plan, :aasm_state => 'created')
      @plan2 = create(:plan, :aasm_state => 'archived')
    end

    it 'should return all functional plans when sent nothing' do
      results = Plan.filtered
      results.should include(@plan1)
      results.should_not include(@plan2)
    end

    it 'should return all functional plans when sent an empty object' do
      results = Plan.filtered({})
      results.should include(@plan1)
      results.should_not include(@plan2)
    end

    it 'should return all functional plans when sent a filter object with irrelevant fields' do
      results = Plan.filtered({:random_sample_field => '[3,3,4,5]'})
      results.should include(@plan1)
      results.should_not include(@plan2)
    end

    it 'should return an empty array, not an error, when sent a filter object with unfindable data' do
      results = Plan.filtered({:aasm_state => ['complete']})
      results.should be_empty
    end
  end
  describe 'delegations' do
    subject { @plan = create(:plan) }
    it { should respond_to :template_type }
    it { should respond_to :stages }
  end

  describe 'transitions' do
    before do
      @plan = create(:plan)
    end

    describe '#plan_it!' do
      it 'should transition the plan from its default created state to planned' do
        @plan.plan_it!
        @plan.should be_planned
      end
      it 'should transition the plan from cancelled to planned' do
        @plan.update_attribute(:aasm_state, 'cancelled')
        @plan.plan_it!
        @plan.should be_planned
      end
      it 'should transition the plan from cancelled to planned using a restful attribute update' do
        @plan.update_attributes(:aasm_event => 'plan_it')
        @plan.should be_planned
      end
    end

    describe '#start!' do
      it 'should transition the plan from planned to started' do
        @plan.update_attribute(:aasm_state, 'planned')
        @plan.start!
        @plan.should be_started
      end
      it 'should transition the plan from planned to started using a restful attribute update' do
        @plan.update_attribute(:aasm_state, 'planned')
        @plan.update_attributes(:aasm_event => 'start')
        @plan.should be_started
      end
      it 'should transition the plan from hold to started' do
        @plan.update_attribute(:aasm_state, 'hold')
        @plan.start!
        @plan.should be_started
      end
      it 'should transition the plan from hold to started using a restful attribute update' do
        @plan.update_attribute(:aasm_state, 'hold')
        @plan.update_attributes(:aasm_event => 'start')
        @plan.should be_started
      end
      it 'should transition the plan from locked to started' do
        @plan.update_attribute(:aasm_state, 'plan_locked')
        @plan.start!
        @plan.should be_started
      end
      it 'should transition the plan from locked to started using a restful attribute update' do
        @plan.update_attribute(:aasm_state, 'plan_locked')
        @plan.update_attributes(:aasm_event => 'start')
        @plan.should be_started
      end
    end

    describe '#lock!' do
      it 'should transition the plan from planned to locked' do
        @plan.update_attribute(:aasm_state, 'planned')
        @plan.lock!
        @plan.should be_plan_locked
      end
      it 'should transition the plan from planned to locked using a restful attribute update' do
        @plan.update_attribute(:aasm_state, 'planned')
        @plan.update_attributes(:aasm_event => 'lock')
        @plan.should be_plan_locked
      end
      it 'should transition the plan from started to locked' do
        @plan.update_attribute(:aasm_state, 'started')
        @plan.lock!
        @plan.should be_plan_locked
      end
      it 'should transition the plan from started to locked using a restful attribute update' do
        @plan.update_attribute(:aasm_state, 'started')
        @plan.update_attributes(:aasm_event => 'lock')
        @plan.should be_plan_locked
      end
    end

    describe '#finish!' do
      it 'should transition the plan from started to finished' do
        @plan.update_attribute(:aasm_state, 'started')
        @plan.finish!
        @plan.should be_complete
      end
      it 'should transition the plan from started to finished using a restful attribute update' do
        @plan.update_attribute(:aasm_state, 'started')
        @plan.update_attributes(:aasm_event => 'finish')
        @plan.should be_complete
      end
    end

    describe '#archive!' do
      it 'should transition the plan from complete to archived' do
        @plan.update_attribute(:aasm_state, 'complete')
        @plan.archive!
        @plan.should be_archived
      end
      it 'should transition the plan from complete to archived using a restful attribute update' do
        @plan.update_attribute(:aasm_state, 'complete')
        @plan.update_attributes(:aasm_event => 'archive')
        @plan.should be_archived
      end
    end

    describe '#put_on_hold!' do
      it 'should transition the plan from started to hold' do
        @plan.update_attribute(:aasm_state, 'started')
        @plan.put_on_hold!
        @plan.should be_hold
      end
      it 'should transition the plan from started to hold using a restful attribute update' do
        @plan.update_attribute(:aasm_state, 'started')
        @plan.update_attributes(:aasm_event => 'put_on_hold')
        @plan.should be_hold
      end
      it 'should transition the plan from locked to hold' do
        @plan.update_attribute(:aasm_state, 'plan_locked')
        @plan.put_on_hold!
        @plan.should be_hold
      end
      it 'should transition the plan from locked to hold using a restful attribute update' do
        @plan.update_attribute(:aasm_state, 'plan_locked')
        @plan.update_attributes(:aasm_event => 'put_on_hold')
        @plan.should be_hold
      end
    end

    describe '#cancel!' do
      it 'should transition the plan from created to cancelled' do
        @plan.update_attribute(:aasm_state, 'created')
        @plan.cancel!
        @plan.should be_cancelled
      end
      it 'should transition the plan from created to cancelled using a restful attribute update' do
        @plan.update_attribute(:aasm_state, 'created')
        @plan.update_attributes(:aasm_event => 'cancel')
        @plan.should be_cancelled
      end
      it 'should transition the plan from planned to cancelled' do
        @plan.update_attribute(:aasm_state, 'planned')
        @plan.cancel!
        @plan.should be_cancelled
      end
      it 'should transition the plan from planned to cancelled using a restful attribute update' do
        @plan.update_attribute(:aasm_state, 'planned')
        @plan.update_attributes(:aasm_event => 'cancel')
        @plan.should be_cancelled
      end
      it 'should transition the plan from hold to cancelled' do
        @plan.update_attribute(:aasm_state, 'hold')
        @plan.cancel!
        @plan.should be_cancelled
      end
      it 'should transition the plan from hold to cancelled using a restful attribute update' do
        @plan.update_attribute(:aasm_state, 'hold')
        @plan.update_attributes(:aasm_event => 'cancel')
        @plan.should be_cancelled
      end
      it 'should transition the plan from started to cancelled' do
        @plan.update_attribute(:aasm_state, 'started')
        @plan.cancel!
        @plan.should be_cancelled
      end
      it 'should transition the plan from started to cancelled using a restful attribute update' do
        @plan.update_attribute(:aasm_state, 'started')
        @plan.update_attributes(:aasm_event => 'cancel')
        @plan.should be_cancelled
      end
    end

    describe '#delete!' do
      it 'should transition the plan from cancelled to deleted' do
        @plan.update_attribute(:aasm_state, 'cancelled')
        @plan.delete!
        @plan.should be_deleted
      end
      it 'should transition the plan from created to deleted' do
        @plan.update_attribute(:aasm_state, 'created')
        @plan.delete!
        @plan.should be_deleted
      end
      it 'should transition the plan from archived to deleted' do
        @plan.update_attribute(:aasm_state, 'archived')
        @plan.delete!
        @plan.should be_deleted
      end
      it 'should transition the plan from archived to deleted and rename name' do
        @original_name = @plan.name
        @plan.update_attribute(:aasm_state, 'created')
        @plan.delete!
        @plan.should be_deleted
        @plan.name.should_not == @original_name
      end
    end

    describe 'restful attribute method should give good error messages' do
      it 'should invalidate the model when an unsupported event is submitted' do
        @plan.update_attribute(:aasm_state, 'created')
        @plan.update_attributes(:aasm_event => 'INVALID')
        @plan.should be_created
        @plan.should_not be_valid
        @plan.errors[:aasm_event].should == ['was not included in supported events: plan_it, start, lock, finish, archive, put_on_hold, cancel, and reopen.']
      end
      it 'should invalidate the model when a invalid transition is submitted' do
        @plan.update_attribute(:aasm_state, 'planned')
        @plan.update_attributes(:aasm_event => 'put_on_hold')
        @plan.should be_planned
        @plan.should_not be_valid
        @plan.errors[:aasm_event].should == ['was not a valid transition for current state: planned.']
      end
    end

    describe 'select list of status fields' do
      it 'should provide a select list' do
        Plan.status_filters_for_select.should == [['Created', 'created'], ['Planned', 'planned'], ['Started', 'started'], ['Plan locked', 'plan_locked'], ['Complete', 'complete'], ['Reopen', 'reopen'], ['Archived', 'archived'], ['Hold', 'hold'], ['Cancelled', 'cancelled']]
      end
    end
  end

  describe 'attribute accessors' do
    subject { @plan = create(:plan) }
    it { should respond_to :plan_template_type }
    it { should respond_to :stage_date }
  end

  describe 'reporting' do
    before do
      @plan = create(:plan)
    end

    describe 'applications through requests' do
      before do
        application = mock_model(App)
        application.stub(:id).and_return(1)
        application.stub(:name).and_return('My application')
        App.should_receive(:for_plan).and_return([application])
      end
      it 'should return applications' do
        @plan.applications.count.should == 1
      end
      it 'should respond true when asked if it has an included application' do
        @plan.has_app(1).should be_truthy
      end
      it 'should respond false when asked if it has a not included application' do
        @plan.has_app(2).should be_falsey
      end
      it 'should return name labels for applications' do
        @plan.application_name_labels.should == 'My application'
      end
    end

    describe 'routed app ids through plan_routes' do

      before(:each) do
        @plan_route = create(:plan_route, :plan => @plan)
        @route_gate = create(:route_gate, :route => @plan_route.route)
      end
      it 'should return routed app ids' do
        @plan.routed_app_ids.should include(@plan_route.route_app_id)
      end
      it 'should return routed apps' do
        @plan.routed_apps.should include(@plan_route.route_app)
      end
    end

    describe 'environments through requests' do
      before do
        environment = mock_model(Environment)
        Environment.should_receive(:for_plan).and_return([environment])
      end
      it 'should return environments' do
        @plan.environments.count.should == 1
      end
    end

    describe 'application_environments through requests' do
      before do
        application_environment = mock_model(ApplicationEnvironment)
        ApplicationEnvironment.should_receive(:for_plan).and_return([application_environment])
      end
      it 'should return application environments' do
        @plan.application_environments.count.should == 1
      end
    end

    describe 'environments for a specific application' do
      before do
        application_environment = mock_model(ApplicationEnvironment)
        application_environment.stub(:app_id).and_return(1)
        application_environment.stub(:environment_id).and_return(1)
        ApplicationEnvironment.should_receive(:for_plan).and_return([application_environment])
        environment = mock_model(Environment)
        environment.stub(:id).and_return(1)
        Environment.should_receive(:for_plan).and_return([environment])
      end
      it 'should return application environments' do
        @plan.environments_for_app(1).count.should == 1
      end
    end

    describe 'release label' do
      before(:each) do
        @release = create(:release)
        @release_manager = create(:user)
        @release_date = Date.today
      end
      it 'should return complete with all fields filled out' do
        @plan.update_attributes(:release => @release,
                                :release_date => @release_date,
                                :release_manager => @release_manager)
        @plan.release_label.should == "Rel: #{@release.name} / Mgr: #{@release_manager.short_name} / Date: #{@release_date}"
      end
      it 'should return date and manager with release missing' do
        @plan.update_attributes(:release => nil,
                                :release_date => @release_date,
                                :release_manager => @release_manager)
        @plan.release_label.should == "Mgr: #{@release_manager.short_name} / Date: #{@release_date}"
      end
      it 'should return date with release and manager missing' do
        @plan.update_attributes(:release => nil,
                                :release_date => @release_date,
                                :release_manager => nil)
        @plan.release_label.should == "Date: #{@release_date}"
      end
      it 'should return release and date with manager missing' do
        @plan.update_attributes(:release => @release,
                                :release_date => @release_date,
                                :release_manager => nil)
        @plan.release_label.should == "Rel: #{@release.name} / Date: #{@release_date}"
      end
      it 'should return release and manager with release date missing' do
        @plan.update_attributes(:release => @release,
                                :release_date => nil,
                                :release_manager => @release_manager)
        @plan.release_label.should == "Rel: #{@release.name} / Mgr: #{@release_manager.short_name}"
      end
      it 'should return release with manager and release date missing' do
        @plan.update_attributes(:release => @release,
                                :release_date => nil,
                                :release_manager => nil)
        @plan.release_label.should == "Rel: #{@release.name}"
      end
      it 'should return manager with release and date missing' do
        @plan.update_attributes(:release => nil,
                                :release_date => nil,
                                :release_manager => @release_manager)
        @plan.release_label.should == "Mgr: #{@release_manager.short_name}"
      end
      it 'should return nothing with all release, release manager, and release date missing' do
        @plan.update_attributes(:release => nil,
                                :release_date => nil,
                                :release_manager => nil)
        @plan.release_label.should == ''
      end
    end
  end

  describe 'after save hook: set stage dates from form hash' do
    before do
      @plan_template = create(:plan_template)
      @stage = create(:plan_stage, :plan_template => @plan_template)
      @plan = create(:plan, :name => 'My Save Test', :plan_template => @plan_template)
      @plan_member = create(:plan_member, :plan => @plan, :stage => @stage)
      @start_date = Date.today
      @end_date = Date.today + 1.day
    end

    it 'should set stage dates if given an array of stage dates' do
      @plan.stage_date = {@stage.id.to_s => {'start_date' => @start_date, 'end_date' => @end_date}}
      @plan.save
      plan_stage_dates = @plan.stage_dates.where(plan_id: @plan.id, plan_stage_id: @stage.id).first
      expect(plan_stage_dates.start_date).to eq(@start_date)
      expect(plan_stage_dates.end_date).to eq(@end_date)
    end
  end

  describe 'after save hook: set release for requests' do
    before do
      @user = create(:user)
      User.stub(:current_user) { @user }
      @release = create(:release)
      @plan_template = create(:plan_template)
      @stage = create(:plan_stage, :plan_template => @plan_template)
      @plan = create(:plan, :name => 'My Save Test', :plan_template => @plan_template)
      @plan_member = create(:plan_member, :plan => @plan, :stage => @stage)
      @user = create(:user)
      @initial_request = create(:request, :requestor => @user, :deployment_coordinator => @user)
      @request_template = create(:request_template, :request => @initial_request)
      @request = create(:request, :request_template => @request_template, :requestor => @user, :deployment_coordinator => @user, :plan_member => @plan_member)
    end

    it 'should overwrite the release setting on subordinate requests' do
      expect(@plan.requests.where(id: @request.id).first.release).to_not eq(@release)
      @plan.release = @release
      @plan.save
      expect(@plan.requests.where(id: @request.id).first.release).to eq(@release)
    end
  end

  describe 'after save hook: create plan stage instances' do

    before(:each) do
      @plan_template = create(:plan_template)
      @stage = create(:plan_stage, :plan_template => @plan_template)
      @plan = create(:plan, :name => 'My Save Test', :plan_template => @plan_template)
    end

    it 'finds or creates plan stage instances for each plan stage' do
      instances = @plan.plan_stage_instances.map { |psi| psi.plan_stage_id }.sort
      stages = @plan.stages.map { |ps| ps.id }.sort
      instances.should == stages
    end

  end

  describe '#filtered' do

    before(:all) do
      Plan.delete_all

      @date = Date.today

#      @user = create(:user)
      @user = create(:old_user)
      User.current_user = @user

      @team = create(:team, :name => 'Dev')
      @app = create(:app)
      @env = create(:environment)

      #template_type: 'continuous_integration', 'deploy', 'release_plan'
      @plan_template = create(:plan_template, :template_type => 'deploy')
      @plan_stage = create(:plan_stage, :plan_template => @plan_template)

      @ps = create(:project_server)
      @release = create(:release, :name => 'NEW Release')

      @plan_1 = create_plan(:name => 'Default plan',
                            :aasm_state => 'started',
                            :plan_template => @plan_template)
      @plan_member = create(:plan_member, :plan => @plan_1, :stage => @plan_stage)

      AssignedEnvironment.create!(:environment_id => @env.id, :assigned_app_id => @app.assigned_apps.first.id, :role => @user.roles.first)
      @app.environments << @env
      @req = create(:request, :apps => [@app], :environment_id => @env.id, :plan_member => @plan_member)
#      @req = create(:request, :apps => [@app], :environment => @env, :plan_member => @plan_member)

      #aasm: 'created', 'planned', 'started', 'locked', 'complete', 'reopen',  'archived', 'hold', 'cancelled'
      @plan_2 = create_plan(:name => 'Plan #1',
                            :aasm_state => 'started',
                            :release => @release,
                            :release_date => @date,
                            :release_manager => @user)

      @plan_3 = create_plan(:name => 'Plan #2',
                            :aasm_state => 'complete',
                            :foreign_id => 'Some foreign ID',
                            :project_server => @ps,
                            :teams => [@team])
    end

    after(:all) do
      Plan.delete_all
      Request.delete([@req])
      PlanMember.delete([@plan_member])
      Release.delete([@release])
      ProjectServer.delete([@ps])
      PlanStage.delete([@plan_stage])
      PlanTemplate.delete([@plan_template])
      Environment.delete([@env])
      App.delete([@app])
      Team.delete([@team])
      User.delete([@user])
    end

    describe 'filter by default' do
      subject { described_class.filtered }
      it { should match_array([@plan_1, @plan_2, @plan_3]) }
    end

    describe 'filter by name, aasm_state, release_date, release_id, release_manager_id' do
      subject { described_class.filtered(:name => 'Plan #1', :aasm_state => 'started', :release_date => @date,
                                         :release_id => @release.id, :release_manager_id => @user.id) }
      it { should match_array([@plan_2]) }
    end

    describe 'filter by foreign_id, project_server_id, team_id' do
      subject { described_class.filtered(:foreign_id => 'Some foreign ID', :project_server_id => @ps.id,
                                         :team_id => @team.id) }
      it { should match_array([@plan_3]) }
    end

    describe 'filter by plan_template_id, plan_type, stage_id' do
      subject { described_class.filtered(:plan_template_id => @plan_template.id, :plan_type => 'deploy',
                                         :stage_id => @plan_stage.id) }
      it { should match_array([@plan_1]) }
    end

    describe 'filter by app_id, environment_id' do
      subject { described_class.filtered(:app_id => @app.id, :environment_id => @env.id) }
      it { should match_array([@plan_1]) }
    end

    describe 'filter by entitled_plans' do
      subject do
        plan_by_aasm_state = described_class.filtered(:aasm_state => 'started')
        described_class.filtered({:name => 'Plan #1'}, plan_by_aasm_state)
      end
      it { should match_array([@plan_2]) }
    end
  end

  protected

  def create_plan(options = nil)
    create(:plan, options)
  end

end
