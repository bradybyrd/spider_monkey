require 'spec_helper'

describe PlansController, type: :controller do
  before(:each) { @plan = create(:plan, plan_template: create(:plan_template)) }

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

  context 'index' do
    it 'returns paginated plans without filters' do
      Plan.delete_all
      plans = 26.times.collect{create(:plan)}
      plans.sort_by!{|el| el.name}

      get :index

      paginated_plans = assigns(:plans)
      plans[0..24].each{|el| expect(paginated_plans).to include(el) }
      expect(paginated_plans).to_not include(plans[25])
      expect(response).to render_template('index')
    end

    it 'returns plans with keyword' do
      test_plan = create(:plan, name: 'Dev1')

      xhr :get, :index, { key: 'Dev', clear_filter: '1' }

      expect(assigns(:plans)).to include(test_plan)
      expect(assigns(:plans)).to_not include(@plan)
      expect(response).to render_template( partial: 'plans/_automated_plan' )
    end

    it 'returns filtered plans' do
      test_plan = create(:plan, name: 'Dev1', aasm_state: 'complete')

      get :index, { filters: { aasm_state: 'complete' },
                    clear_filter: '0' }

      expect(assigns(:plans)).to include(test_plan)
      expect(assigns(:plans)).to_not include(@plan)
    end

    it 'returns flash error' do
      Plan.stub(:filtered).and_return(plans = mock_model(Plan))
      plans.stub(:all).and_return(plans)
      plans.stub(:uniq).and_return(plans)
      plans.stub(:paginate).and_return(nil)

      get :index

      expect(assigns(:plans).blank?).to be_truthy
      expect(flash.now[:error]).to include('No Plan Found')
      expect(response).to render_template('index')
    end

    describe 'authorization' do
      it_behaves_like 'main tabs authorizable', controller_action: :index,
                                                ability_object:    :plans_tab
    end
  end

  it '#filter' do
    get :filter
    expect(response).to render_template('index')
  end

  it_should_behave_like('CRUD GET new')

  context '#show' do
    it 'returns flash plan is deleted' do
      test_plan = create(:plan, name: 'Dev1', aasm_state: 'deleted')

      xhr :get, :show, { id: test_plan.id,
                         format: 'js' }

      expect(flash[:notice]).to include('is deleted')
      expect(response.body).to include('window.location.pathname')
    end

    it 'redirect to root path' do
      test_plan = create(:plan, name: 'Dev1', aasm_state: 'deleted')

      get :show, { id: test_plan.id }

      expect(response).to redirect_to(root_path)
    end

    it 'renders show' do
      get :show, { id: @plan.id }
      expect(response).to render_template('show')
    end

    it "returns flash 'Run not found'" do
      get :show, { id: @plan.id, run_id: '1' }
      expect(flash.now[:error]).to include('Run not found')
    end

    it "returns flash 'could not update state'" do
      run = create(:run, plan: @plan)
      Plan.stub(:find).and_return(@plan)
      @plan.runs.stub(:find).and_return(run)
      run.stub(:update_attributes).and_return(false)

      get :show, { id: @plan.id, run_id: run.id, aasm_event: 'event'}

      expect(flash.now[:error]).to include('could not update state')
    end

    it 'updates state of run' do
      run = create(:run, plan: @plan)
      run.plan_it!

      get :show, { id: @plan.id,
                   run_id: run.id,
                   aasm_event: 'start' }

      #State of Run without requests changes immediately from started to completed
      run.reload
      expect(run.aasm_state).to eq 'completed'
    end

    it 'renders partial stages' do
      xhr :get, :show, { id: @plan.id }
      expect(response).to render_template(partial: 'plans/_stages')
    end
  end

  context 'edit' do
    it 'success' do
      get :edit, id: @plan.id
      expect(response).to render_template('edit')
    end

    it "returns flash 'Access Denied'" do
      @plan.plan_it!
      @plan.start!
      @plan.finish!
      @plan.archive!

      get :edit, id: @plan.id

      expect(flash[:error]).to eq(I18n.t(:'activerecord.notices.no_permissions', action: 'access', model: 'the page you requested.'))
      expect(response).to redirect_to(@plan)
    end
  end

  context '#create' do
    it 'success' do
      plan_template = create(:plan_template)

      post :create, { plan: { name: 'Plan_name',
                              description: 'a sample plan',
                              release_date: Time.now,
                              plan_template_id: plan_template.id }}

      expect(flash[:notice]).to include('successfully')
      expect(response.code).to eq '302'
    end

    it 'fails' do
      Plan.stub(:new).and_return(@plan)
      @plan.stub(:save).and_return(false)

      post :create, { plan: { name: 'Plan_name' }}

      expect(response).to render_template('new')
    end
  end

  context '#update' do
    it 'success xhr' do
      xhr :put, :update, { id: @plan.id,
                           plan: { name: 'name_changed'}}
      @plan.reload
      expect(@plan.name).to eq 'name_changed'
      expect(response).to render_template('misc/redirect')
    end

    it 'updates env_app_date and redirects' do
      app = create(:app)
      env = create(:environment)
      plan_env_app_date  =
          PlanEnvAppDate.create( app_id: app.id,
                                 environment_id: env.id,
                                 plan_id: @plan.id,
                                 plan_template_id: @plan.plan_template.id,
                                 created_at: Time.now,
                                 created_by: @user.id )
      start_date = DateTime.now.to_date + 1.days

      put :update, { id: @plan.id,
                     tab: 'stages',
                     plan: { name: 'name_changed' },
                     "start_ead_#{plan_env_app_date.id}" => start_date,
                     "end_ead_#{plan_env_app_date.id}" => DateTime.now.to_date + 2.days }

      expect(flash[:notice]).to include('successfully')
      expect(response).to redirect_to(plan_path(@plan))
      plan_env_app_date.reload
      planed_start = plan_env_app_date.planned_start.to_datetime.to_date
      expect(planed_start).to eq start_date
    end

    it 'redirects to calendar month path' do
      put :update, { id: @plan.id,
                     plan: { name: 'name_changed'},
                     tab: 'calendar' }

      expect(response).to redirect_to(calendar_months_path(plan_id: @plan.id))
    end

    it 'redirects to version report plan path' do
      put :update, { id: @plan.id,
                     plan: { name: 'name_changed' },
                     tab: 'versions' }
      expect(response).to redirect_to(version_report_plan_path(@plan.id))
    end

    it 'fails xhr' do
      plans = [@plan]
      Plan.stub(:preloaded_with_associations).and_return(plans)
      plans.stub(:find).and_return(@plan)
      @plan.stub(:update_attributes).and_return(false)

      xhr :put, :update, { id: @plan.id,
                           plan: { name: 'name_changed' }}

      expect(response).to render_template('misc/error_messages_for')
    end

    it 'render action edit' do
      plans = [@plan]
      Plan.stub(:preloaded_with_associations).and_return(plans)
      plans.stub(:find).and_return(@plan)
      @plan.stub(:update_attributes).and_return(false)

      put :update, { id: @plan.id,
                     plan: { name: 'name_changed'}}

      expect(response).to render_template('edit')
    end
  end

  it '#destroy' do
    expect{ delete :destroy, id: @plan.id
          }.to change(Plan, :count).by(-1)
    expect(response).to redirect_to(plans_path)
  end

  context 'members' do
    before(:each) do
      plan_stage = create(:plan_stage, plan_template: @plan.plan_template)
      @plan_member = create(:plan_member, plan: @plan, stage: plan_stage)
    end

    it 'selects' do
      get :select_members, id: @plan.id

      expect(assigns(:available_members)).to include(@plan_member)
      expect(response).to render_template('select_members')
    end

    it 'enrolls' do
      put :enroll_members, id: @plan.id

      expect(response).to redirect_to(@plan)
    end

    it 'promotes' do
      post :promote_members, { id: @plan.id, member_ids: [@plan_member.id] }

      expect(response).to redirect_to(@plan)
    end

    it 'demotes' do
      post :demote_members, { id: @plan.id, member_ids: [@plan_member.id] }

      expect(response).to redirect_to(@plan)
    end

    it 'updates members statuses' do
      post :update_members_statuses, { id: @plan.id,
                                       member_ids: [@plan_member.id],
                                       status_id: 'completed' }
      expect(response).to redirect_to(@plan)
    end
  end

  it '#update_plan_templates_list' do
    pending 'missing template'
    plan_template = create(:plan_template)

    post :update_plan_templates_list, {template_type: 'deploy'}

    expect(assigns(:plan_templates)).to include(plan_template)
  end

  context '#create_activity' do
    it 'create new activity' do
      pending "Can't mass-assign protected attributes: user"
      post :create_activity, { id: @plan.id,
                               activity: { name: 'project 1',
                                           activity_category_id: 1,
                                           health: '' }}
      expect(response).to redirect_to(@plan)
    end

    it 'find activity' do
      activity = create(:activity)

      post :create_activity, { id: @plan.id, activity_id: activity.id }

      expect(response).to redirect_to(@plan)
    end
  end

  it '#update_state' do
    get :update_state, { id: @plan.id, state: :plan_it }
    @plan.reload
    expect(@plan.aasm_state).to eq 'planned'

    get :update_state, { id: @plan.id, state: :cancel }
    @plan.reload
    expect(@plan.aasm_state).to eq 'cancelled'

    @plan.plan_it!
    get :update_state, { id: @plan.id, state: :start }
    @plan.reload
    expect(@plan.aasm_state).to eq 'started'

    get :update_state, { id: @plan.id, state: :lock }
    @plan.reload
    expect(@plan.aasm_state).to eq 'plan_locked'

    get :update_state, { id: @plan.id, state: :unlock }
    @plan.reload
    expect(@plan.aasm_state).to eq 'started'

    get :update_state, { id: @plan.id, state: :hold }
    @plan.reload
    expect(@plan.aasm_state).to eq 'hold'

    @plan.start!
    get :update_state, { id: @plan.id, state: :finish }
    @plan.reload
    expect(@plan.aasm_state).to eq 'complete'

    get :update_state, { id: @plan.id, state: :reopen }
    @plan.reload
    expect(@plan.aasm_state).to eq 'planned'

    @plan.start!
    @plan.finish!
    get :update_state, { id: @plan.id, state: :archived }
    @plan.reload
    expect(@plan.aasm_state).to eq 'archived'
    expect(response).to redirect_to(plan_path(@plan))

    get :update_state, { id: @plan.id, state: :delete }
    @plan.reload
    expect(@plan.aasm_state).to eq 'deleted'
    expect(response).to redirect_to(plans_path)
  end

  it '#start_request' do
    test_request = create(:request_with_app)
    test_request.plan_it!
    Request.any_instance.stub(:finish!).and_return(true)

    get :start_request, id: test_request.number

    test_request.reload
    test_request.aasm_state.should eql('started')
    expect(response).to render_template(nothing: true)
  end

  context 'plan_stage_options' do
    it 'renders nothing' do
      get :plan_stage_options
      expect(response).to render_template(nothing: true)
    end

    it "renders text 'invalid plan'" do
      get :plan_stage_options, plan_id: '-1'

      expect(response.body).to include('<option>Invalid plan.</option>')
    end

    it 'renders stage options' do
      create(:plan_member,
              plan: @plan,
              stage: create(:plan_stage, plan_template: @plan.plan_template))

      get :plan_stage_options, { plan_id: @plan.id }

      expect(response.body).to include("<option value='0'>Unassigned</option>")
    end
  end

  it '#applications' do
    test_request = create(:request_with_app)
    app = test_request.apps.first
    stage = create(:plan_stage, plan_template: create(:plan_template))
    plan_member = create(:plan_member, plan: @plan, stage: stage)
    plan_member.request = test_request

    get :applications, id: @plan

    expect(response.body).to include(app.name)
  end

  context '#move_requests' do
    it "returns text 'Plan is archived'" do
      @plan.plan_it!
      @plan.start!
      @plan.finish!
      @plan.archive!

      post :move_requests, id: @plan.id

      expect(flash[:notice]).to include('No stage selected')
      expect(response.body).to include('Plan is archived')
    end

    it "returns flash 'No stage selected'" do
      post :move_requests, id: @plan.id

      expect(flash[:notice]).to include('No stage selected')
      expect(response).to redirect_to(plan_path(@plan))
    end

    it 'adds requests to stage' do
      test_request = create(:request)
      stage = create(:plan_stage, plan_template: @plan.plan_template)
      create(:plan_member, plan: @plan, stage: stage)
      stage2 = create(:plan_stage, plan_template: @plan.plan_template)
      plan_member = create(:plan_member, plan: @plan, stage: stage2)
      plan_member.request = test_request

      post :move_requests, { id: @plan.id,
                             request_ids: [test_request.id],
                             stage_id: stage.id }
      plan_member.reload
      expect(plan_member.plan_stage_id).to eq stage.id
      expect(response).to redirect_to(plan_path(@plan))
    end

    it 'render action' do
      get :move_requests, { id: @plan.id, request_ids: [create(:request).id] }

      expect(response).to render_template('move_requests')
    end

    it_behaves_like 'authorizable', controller_action: :move_requests,
                                    ability_action: :move_requests,
                                    http_method: :post,
                                    subject: Plan do
                                      let(:params) { { id: @plan.id } }
                                    end
  end

  context '#reorder' do
    it "returns flash 'Invalid plan member' and renders partial" do
      run = create(:run)

      get :reorder, { id: @plan.id, run_id: run.id }

      expect(flash[:notice]).to include('Invalid plan member')
      expect(assigns(:run)).to eq run
      expect(response).to render_template(partial: 'plans/_stages')
    end

    it "return flash 'cannot be dragged out of stage'" do
      plan_member = create(:plan_member, run: create(:run))

      get :reorder, { id: @plan.id, member_to_insert_id: plan_member.id }

      expect(flash[:notice]).to include('cannot be dragged out of stage')
    end

    it "return flash 'Request moved to unassigned stage'" do
      plan_member = create(:plan_member)

      get :reorder, { id: @plan.id, member_to_insert_id: plan_member.id }

      expect(flash[:notice]).to include('Request moved')
    end

    it "returns flash 'Reorder of requests failed'" do
      plan_member = create(:plan_member)
      PlanMember.stub(:find).and_return(plan_member)
      plan_member.stub(:move_to_member_or_stage).and_return(false)

      get :reorder, { id: @plan.id,
                      member_to_insert_id: plan_member.id,
                      member_to_target_id: plan_member.id }

      expect(flash[:notice]).to include('failed')
    end
  end

  it '#unassigned_reorder' do
    stage = create(:plan_stage, plan_template: @plan.plan_template)
    create(:plan_member, plan: @plan, stage: stage)

    put :unassigned_reorder, { id: @plan,
                               stage_id: stage.id,
                               request_id: create(:request).id }

    expect(response).to render_template(partial: 'plans/members/_list')
  end

  it '#release_calendar' do
    pending "undefined method `with_plan_template'"
    xhr :get, :release_calendar, { period: '081013,151013',
                                   app_id: create(:app).id }
    expect(response).to render_template(partial: 'plans/release_calendar/_releases_by_month')
  end

  it '#version_report' do
    xhr :get, :version_report, id: @plan.id

    expect(response).to render_template(partial: 'plans/_version_report')
  end

  it '#environments_calendar' do
    get :environments_calendar
    expect(response).to render_template('environments_calendar')
  end

  it '#ticket_summary_report_csv' do
    app = create(:app)
    ticket = create(:ticket, app: app)
    @plan.tickets << ticket

    get :ticket_summary_report_csv, { id: @plan.id, app_id: app.id }

    expect(response.body).to include(app.name.to_s)
    expect(response.body).to include(ticket.name.to_s)
  end

  it '#delete_env_date' do
    app = create(:app)
    env = create(:environment)
    env_app_date =
        PlanEnvAppDate.create( app_id: app.id,
                               environment_id: env.id,
                               plan_id: @plan.id,
                               plan_template_id: @plan.plan_template.id,
                               created_at: Time.now,
                               created_by: @user.id )

    expect{delete :delete_env_date, { id: @plan.id,
                                      format: 'js',
                                      plan_app_env_id: env_app_date.id}
          }.to change(PlanEnvAppDate, :count).by(-1)
    expect(response).to render_template('delete_env_dat')
  end

  it '#constraints' do
    stage = create(:plan_stage, plan_template: @plan.plan_template)
    ps_instance = create(:plan_stage_instance, plan_stage: stage)

    get :constraints, { id: @plan.id, plan_stage_instance_id: ps_instance.id }

    expect(response).to render_template('constraints')
  end
end
