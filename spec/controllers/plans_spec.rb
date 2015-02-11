require 'spec_helper'

describe PlansController, :type => :controller do
  before(:each) { @plan = create(:plan, :plan_template => create(:plan_template)) }

  describe 'authorization', custom_roles: true do
    context 'fails' do
      after { should redirect_to root_path }

      describe '#index' do
        include_context 'mocked abilities', :cannot, :view, :plans_tab
        specify { get :index }
      end

      describe '#new' do
        include_context 'mocked abilities', :cannot, :create, Plan
        specify { get :new }
      end

      describe '#create' do
        include_context 'mocked abilities', :cannot, :create, Plan
        specify { post :create, plan: { name: 'plan name' } }
      end

      describe '#show' do
        include_context 'mocked abilities', :cannot, :inspect, Plan
        specify { get :show, id: @plan }
      end

      describe '#edit' do
        include_context 'mocked abilities', :cannot, :edit, Plan
        specify { get :edit, id: @plan }
      end

      describe '#update' do
        include_context 'mocked abilities', :cannot, :edit, Plan
        specify { put :update, id: @plan }
      end

      describe '#update_state' do
        context 'cancel state' do
          include_context 'mocked abilities', :cannot, :cancel, Plan
          specify { get :update_state, id: @plan, state: 'cancel' }
        end

        context 'plan_it state' do
          include_context 'mocked abilities', :cannot, :plan, Plan
          specify { get :update_state, id: @plan, state: 'plan_it' }
        end

        context 'start state' do
          include_context 'mocked abilities', :cannot, :start, Plan
          specify { get :update_state, id: @plan, state: 'start' }
        end

        context 'lock state' do
          include_context 'mocked abilities', :cannot, :lock, Plan
          specify { get :update_state, id: @plan, state: 'lock' }
        end

        context 'unlock state' do
          include_context 'mocked abilities', :cannot, :start, Plan
          specify { get :update_state, id: @plan, state: 'unlock' }
        end

        context 'hold state' do
          include_context 'mocked abilities', :cannot, :hold, Plan
          specify { get :update_state, id: @plan, state: 'hold' }
        end

        context 'finish state' do
          include_context 'mocked abilities', :cannot, :complete, Plan
          specify { get :update_state, id: @plan, state: 'finish' }
        end

        context 'archived state' do
          include_context 'mocked abilities', :cannot, :archive, Plan
          specify { get :update_state, id: @plan, state: 'archived' }
        end

        context 'archived state' do
          include_context 'mocked abilities', :cannot, :archive, Plan
          specify { get :update_state, id: @plan, state: 'archived' }
        end

        context 'delete state' do
          include_context 'mocked abilities', :cannot, :delete, Plan
          specify { get :update_state, id: @plan, state: 'delete' }
        end

        context 'reopen state' do
          include_context 'mocked abilities', :cannot, :reopen, Plan
          specify { get :update_state, id: @plan, state: 'reopen' }
        end
      end
    end

    context 'successful' do
      describe '#move_requests' do
        include_context 'mocked abilities', :can, :move_requests, Plan

        it 'allows user to move requests' do
          get :move_requests, id: @plan, request_ids: [create(:request).id]

          is_expected.to render_template(:move_requests)
        end
      end
    end

  end

  context "index" do
    it "returns paginated plans without filters" do
      Plan.delete_all
      @plans = 26.times.collect{create(:plan)}
      @plans.sort_by!{|el| el.name}
      get :index
      @plans[0..24].each{|el| assigns(:plans).should include(el)}
      assigns(:plans).should_not include(@plans[25])
      response.should render_template('index')
    end

    it "returns plans with keyword" do
      @plan1 = create(:plan, :name => "Dev1")
      xhr :get, :index, {:key => "Dev",
                         :clear_filter => '1'}
      assigns(:plans).should include(@plan1)
      assigns(:plans).should_not include(@plan)
      response.should render_template(:partial => "plans/_automated_plan")
    end

    it "returns filtered plans" do
      @plan1 = create(:plan, :name => "Dev1", :aasm_state => 'complete')
      get :index, {:filters => {:aasm_state => 'complete'},
                   :clear_filter => '0'}
      assigns(:plans).should include(@plan1)
      assigns(:plans).should_not include(@plan)
    end

    it "returns flash error" do
      Plan.stub(:filtered).and_return(@plans = mock_model(Plan))
      @plans.stub(:all).and_return(@plans)
      @plans.stub(:uniq).and_return(@plans)
      @plans.stub(:paginate).and_return(nil)
      get :index
      assigns(:plans).blank?.should be_truthy
      flash.now[:error].should include("No Plan Found")
      response.should render_template('index')
    end

    describe 'authorization' do
      it_behaves_like 'main tabs authorizable', controller_action: :index,
                                                ability_object:    :plans_tab
    end
  end

  it "#filter" do
    get :filter
    response.should render_template("index")
  end

  it_should_behave_like("CRUD GET new")

  context "#show" do
    it "returns flash plan is deleted" do
      @plan1 = create(:plan, :name => "Dev1", :aasm_state => 'deleted')
      xhr :get, :show, {:id => @plan1.id,
                        :format =>"js"}
      flash[:notice].should include("is deleted")
      response.body.should include('window.location.pathname')
    end

    it "redirect to root path" do
      @plan1 = create(:plan, :name => "Dev1", :aasm_state => 'deleted')
      get :show, {:id => @plan1.id}
      response.should redirect_to(root_path)
    end

    it "renders show" do
      get :show, {:id => @plan.id}
      response.should render_template("show")
    end

    it "returns flash 'Run not found'" do
      get :show, {:id => @plan.id,
                  :run_id => '1'}
      flash.now[:error].should include("Run not found")
    end

    it "returns flash 'could not update state'" do
      @run = create(:run, :plan => @plan)
      Plan.stub(:find).and_return(@plan)
      @plan.runs.stub(:find).and_return(@run)
      @run.stub(:update_attributes).and_return(false)
      get :show, {:id => @plan.id,
                  :run_id => @run.id,
                  :aasm_event => "event"}
      flash.now[:error].should include("could not update state")
    end

    it "updates state of run" do
      pending "check method in controller"
      @run = create(:run, :plan => @plan)
      @run.plan_it!
      Run.any_instance.stub(:finish!).and_return(true)
      get :show, {:id => @plan.id,
                  :run_id => @run.id,
                  :aasm_event => 'start'}
      @run.reload
      @run.aasm_state.should eql('started')
    end

    it "renders partial stages" do
      xhr :get, :show, {:id => @plan.id}
      response.should render_template(:partial => "plans/_stages")
    end
  end

  context "edit" do
    it "success" do
      get :edit, {:id => @plan.id}
      response.should render_template('edit')
    end

    it "returns flash 'Access Denied'" do
      @plan.plan_it!
      @plan.start!
      @plan.finish!
      @plan.archive!
      get :edit, {:id => @plan.id}
      expect(flash[:error]).to eq(I18n.t(:'activerecord.notices.no_permissions', action: 'access', model: 'the page you requested.'))
      response.should redirect_to(@plan)
    end
  end

  context "#create" do
    it "success" do
      @plan_template = create(:plan_template)
      post :create, {:plan => {:name => "Plan_name",
                               :description => 'a sample plan',
                               :release_date => Time.now,
                               :plan_template_id => @plan_template.id}}
      flash[:notice].should include('successfully')
      response.code.should eql('302')
    end

    it "fails" do
      Plan.stub(:new).and_return(@plan)
      @plan.stub(:save).and_return(false)
      post :create, {:plan => {:name => "Plan_name"}}
      response.should render_template('new')
    end
  end

  context "#update" do
    it "success xhr" do
      xhr :put, :update, {:id => @plan.id,
                          :plan => {:name => "name_changed"}}
      @plan.reload
      @plan.name.should eql("name_changed")
      response.should render_template('misc/redirect')
    end

    it "updates env_app_date and redirects" do
      @app = create(:app)
      @env = create(:environment)
      @plan_env_app_date  = PlanEnvAppDate.create(:app_id => @app.id,
                                                  :environment_id => @env.id,
                                                  :plan_id => @plan.id,
                                                  :plan_template_id => @plan.plan_template.id,
                                                  :created_at => Time.now,
                                                  :created_by => @user.id)
      put :update, {"start_ead_#{@plan_env_app_date.id}" => DateTime.now.to_date + 1.days,
                    "end_ead_#{@plan_env_app_date.id}" => DateTime.now.to_date + 2.days,
                    :plan => {:name => "name_changed"},
                    :id => @plan.id,
                    :tab => "stages"}
      flash[:notice].should include('successfully')
      response.should redirect_to(plan_path(@plan))
      @plan_env_app_date.reload
      @plan_env_app_date.planned_start.to_datetime.to_date.should eql(DateTime.now.to_date + 1.days)
    end

    it "redirects to calendar month path" do
      put :update, {:id => @plan.id,
                    :plan => {:name => "name_changed"},
                    :tab => "calendar"}
      response.should redirect_to(calendar_months_path(:plan_id => @plan.id))
    end

    it "redirects to version report plan path" do
      put :update, {:id => @plan.id,
                    :plan => {:name => "name_changed"},
                    :tab => "versions"}
      response.should redirect_to(version_report_plan_path(@plan.id))
    end

    it "fails xhr" do
      @plans = [@plan]
      Plan.stub(:preloaded_with_associations).and_return(@plans)
      @plans.stub(:find).and_return(@plan)
      @plan.stub(:update_attributes).and_return(false)
      xhr :put, :update, {:id => @plan.id,
                          :plan => {:name => "name_changed"}}
      response.should render_template('misc/error_messages_for')
    end

    it "render action edit" do
      @plans = [@plan]
      Plan.stub(:preloaded_with_associations).and_return(@plans)
      @plans.stub(:find).and_return(@plan)
      @plan.stub(:update_attributes).and_return(false)
      put :update, {:id => @plan.id,
                    :plan => {:name => "name_changed"}}
      response.should render_template('edit')
    end
  end

  it "#destroy" do
    expect{delete :destroy, {:id => @plan.id}
          }.to change(Plan, :count).by(-1)
    response.should redirect_to(plans_path)
  end

  context "members" do
    before(:each) do
      @plan_stage = create(:plan_stage, :plan_template => @plan.plan_template)
      @plan_member1 = create(:plan_member, :plan => @plan,
                                           :stage => @plan_stage)
    end

    it "selects" do
      pending "controller method code is broken"
      get :select_members, {:id => @plan.id}
      assigns(:available_members).should include(@plan_member1)
      response.should render_template('select_members')
    end

    it "enrolls" do
      put :enroll_members, {:id => @plan.id}
      response.should redirect_to(@plan)
    end

    it "promotes" do
      post :promote_members, {:id => @plan.id,
                              :member_ids => [@plan_member1.id]}
      response.should redirect_to(@plan)
    end

    it "demotes" do
      post :demote_members, {:id => @plan.id,
                             :member_ids => [@plan_member1.id]}
      response.should redirect_to(@plan)
    end

    it "updates members statuses" do
      post :update_members_statuses, {:id => @plan.id,
                                      :member_ids => [@plan_member1.id],
                                      :status_id => 'completed'}
      response.should redirect_to(@plan)
    end
  end

  it "#update_plan_templates_list" do
    pending "missing template"
    @plan_template = create(:plan_template)
    post :update_plan_templates_list, {:template_type => 'deploy'}
    assigns(:plan_templates).should include(@plan_template)
  end

  context "#create_activity" do
    it "create new activity" do
      pending "Can't mass-assign protected attributes: user"
      post :create_activity, {:id => @plan.id,
                              :activity => {:name => 'project 1',
                                            :activity_category_id => 1,
                                            :health => ''}}
      response.should redirect_to(@plan)
    end

    it "find activity" do
      @activity = create(:activity)
      post :create_activity, {:id => @plan.id,
                              :activity_id => @activity.id}
      response.should redirect_to(@plan)
    end
  end

  it "#update_state" do
    get :update_state, {:id => @plan.id,
                        :state => :plan_it}
    @plan.reload
    @plan.aasm_state.should eql('planned')
    get :update_state, {:id => @plan.id,
                        :state => :cancel}
    @plan.reload
    @plan.aasm_state.should eql('cancelled')

    @plan.plan_it!
    get :update_state, {:id => @plan.id,
                        :state => :start}
    @plan.reload
    @plan.aasm_state.should eql('started')

    get :update_state, {:id => @plan.id,
                        :state => :lock}
    @plan.reload
    @plan.aasm_state.should eql('plan_locked')

    get :update_state, {:id => @plan.id,
                        :state => :unlock}
    @plan.reload
    @plan.aasm_state.should eql('started')

    get :update_state, {:id => @plan.id,
                        :state => :hold}
    @plan.reload
    @plan.aasm_state.should eql('hold')

    @plan.start!
    get :update_state, {:id => @plan.id,
                        :state => :finish}
    @plan.reload
    @plan.aasm_state.should eql('complete')

    get :update_state, {:id => @plan.id,
                        :state => :reopen}
    @plan.reload
    @plan.aasm_state.should eql('planned')

    @plan.start!
    @plan.finish!
    get :update_state, {:id => @plan.id,
                        :state => :archived}
    @plan.reload
    @plan.aasm_state.should eql('archived')
    response.should redirect_to(plan_path(@plan))

    get :update_state, {:id => @plan.id,
                        :state => :delete}
    @plan.reload
    @plan.aasm_state.should eql('deleted')
    response.should redirect_to(plans_path)
  end

  it "#start_request" do
    @request1 = create(:request_with_app)
    @request1.plan_it!
    Request.any_instance.stub(:finish!).and_return(true)
    get :start_request, {:id => @request1.id + GlobalSettings[:base_request_number]}
    @request1.reload
    @request1.aasm_state.should eql('started')
    response.should render_template(:nothing => true)
  end

  context "plan_stage_options" do
    it "renders nothing" do
      get :plan_stage_options
      response.should render_template(:nothing => true)
    end

    it "renders text 'invalid plan'" do
      get :plan_stage_options, {:plan_id => "-1"}
      response.body.should include('<option>Invalid plan.</option>')
    end

    it "renders stage options" do
      @plan_stage = create(:plan_stage,
                           :plan_template => @plan.plan_template)
      @plan_member = create(:plan_member,
                            :plan => @plan,
                            :stage => @plan_stage)
      get :plan_stage_options, {:plan_id => @plan.id}
      response.body.should include("<option value='0'>Unassigned</option>")
    end
  end

  it "#applications" do
    @request1 = create(:request_with_app)
    @application1 = @request1.apps.first
    @stage = create(:plan_stage, :plan_template => create(:plan_template))
    @plan_member1 = create(:plan_member, :plan => @plan, :stage => @stage)
    @plan_member1.request = @request1
    get :applications, {:id => @plan}
    response.body.should include(@application1.name)
  end

  context "#move_requests" do
    it "returns text 'Plan is archived'" do
      @plan.plan_it!
      @plan.start!
      @plan.finish!
      @plan.archive!
      post :move_requests, {:id => @plan.id}
      flash[:notice].should include("No stage selected")
      response.body.should include('Plan is archived')
    end

    it "returns flash 'No stage selected'" do
      post :move_requests, {:id => @plan.id}
      flash[:notice].should include("No stage selected")
      response.should redirect_to(plan_path(@plan))
    end

    it "adds requests to stage" do
      @request1 = create(:request)
      @stage = create(:plan_stage, :plan_template => @plan.plan_template)
      @stage2 = create(:plan_stage, :plan_template => @plan.plan_template)
      @plan_member1 = create(:plan_member, :plan => @plan, :stage => @stage)
      @plan_member2 = create(:plan_member, :plan => @plan, :stage => @stage2)
      @plan_member2.request = @request1
      post :move_requests, {:id => @plan.id,
                            :request_ids => [@request1.id],
                            :stage_id => @stage.id}
      @plan_member2.reload
      @plan_member2.plan_stage_id.should eql(@stage.id)
      response.should redirect_to(plan_path(@plan))
    end

    it "render action" do
      @request1 = create(:request)
      get :move_requests, {:id => @plan.id,
                           :request_ids => [@request1.id]}
      response.should render_template("move_requests")
    end

    it_behaves_like 'authorizable', controller_action: :move_requests,
                                    ability_action: :move_requests,
                                    http_method: :post,
                                    subject: Plan do
                                      let(:params) { { id: @plan.id } }
                                    end
  end

  context "#reorder" do
    it "returns flash 'Invalid plan member' and renders partial" do
      @run = create(:run)
      get :reorder, {:id => @plan.id,
                     :run_id => @run.id}
      flash[:notice].should include('Invalid plan member')
      assigns(:run).should eql(@run)
      response.should render_template(:partial => "plans/_stages")
    end

    it "return flash 'cannot be dragged out of stage'" do
      @plan_member = create(:plan_member, :run => create(:run))
      get :reorder, {:id => @plan.id,
                     :member_to_insert_id => @plan_member.id}
      flash[:notice].should include('cannot be dragged out of stage')
    end

    it "return flash 'Request moved to unassigned stage'" do
      @plan_member = create(:plan_member)
      get :reorder, {:id => @plan.id,
                     :member_to_insert_id => @plan_member.id}
      flash[:notice].should include('Request moved')
    end

    it "returns flash 'Reorder of requests failed'" do
      @plan_member = create(:plan_member)
      PlanMember.stub(:find).and_return(@plan_member)
      @plan_member.stub(:move_to_member_or_stage).and_return(false)
      get :reorder, {:id => @plan.id,
                     :member_to_insert_id => @plan_member.id,
                     :member_to_target_id => @plan_member.id}
      flash[:notice].should include('failed')
    end
  end

  it "#unassigned_reorder" do
    @request1 = create(:request)
    @stage = create(:plan_stage, :plan_template => @plan.plan_template)
    @plan_member = create(:plan_member, :plan => @plan, :stage => @stage)
    put :unassigned_reorder, {:id => @plan,
                              :stage_id => @stage.id,
                              :request_id => @request1.id}
    response.should render_template(:partial => "plans/members/_list")
  end

  it "#release_calendar" do
    pending "undefined method `with_plan_template'"
    @app = create(:app)
    xhr :get, :release_calendar, {:period => '081013,151013',
                                  :app_id => @app.id}
    response.should render_template(:partial => "plans/release_calendar/_releases_by_month")
  end

  it "#version_report" do
    xhr :get, :version_report, {:id => @plan.id}
    response.should render_template(:partial => "plans/_version_report")
  end

  it "#environments_calendar" do
    get :environments_calendar
    response.should render_template('environments_calendar')
  end

  it "#ticket_summary_report_csv" do
    @app = create(:app)
    @ticket = create(:ticket, :app => @app)
    @plan.tickets << @ticket
    get :ticket_summary_report_csv, {:id => @plan.id,
                                     :app_id => @app.id}
    response.body.should include("#{@app.name}")
    response.body.should include("#{@ticket.name}")
  end

  it "#delete_env_date" do
    @app = create(:app)
    @env = create(:environment)
    @env_app_date = PlanEnvAppDate.create(:app_id => @app.id,
                                          :environment_id => @env.id,
                                          :plan_id => @plan.id,
                                          :plan_template_id => @plan.plan_template.id,
                                          :created_at => Time.now,
                                          :created_by => @user.id)
    expect{delete :delete_env_date, {:id => @plan.id,
                                     :plan_app_env_id => @env_app_date.id,
                                     :format => 'js'}
          }.to change(PlanEnvAppDate, :count).by(-1)
    response.should render_template('delete_env_dat')
  end

  it "#constraints" do
    @stage = create(:plan_stage, :plan_template => @plan.plan_template)
    @plan_stage_instance = create(:plan_stage_instance, :plan_stage => @stage)
    get :constraints, {:id => @plan.id,
                       :plan_stage_instance_id => @plan_stage_instance.id}
    response.should render_template('constraints')
  end
end
