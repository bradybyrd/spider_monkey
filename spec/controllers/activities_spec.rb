require 'spec_helper'

describe ActivitiesController, type: :controller do
  before(:each) do
    @activity_category = create(:activity_category)
    @activity = create(:activity, activity_category: @activity_category)
  end

  context 'authorization' do
    context 'authorize fails' do
      after { expect(response).to redirect_to root_path }

      context '#request_projects' do
        include_context 'mocked abilities', :cannot, :list, Activity
        specify { get :request_projects }
      end

      context '#new' do
        include_context 'mocked abilities', :cannot, :create, Activity
        specify { get :new, activity_category_id: @activity_category }
      end

      context '#create' do
        include_context 'mocked abilities', :cannot, :create, Activity
        specify { post :create }
      end

      context '#edit' do
        describe 'General tab' do
          let!(:activity_tab) { create(:activity_tab, name: 'General', activity_category: @activity_category) }
          include_context 'mocked abilities', :cannot, :edit_general, Activity
          specify { get :edit, id: @activity, activity_tab_id: activity_tab }
        end

        describe 'Requests tab' do
          let!(:activity_tab) { create(:activity_tab, name: 'Requests', activity_category: @activity_category) }
          include_context 'mocked abilities', :cannot, :edit_requests, Activity
          specify { get :edit, id: @activity, activity_tab_id: activity_tab }
        end

        describe 'Notes tab' do
          let!(:activity_tab) { create(:activity_tab, name: 'Notes', activity_category: @activity_category) }
          include_context 'mocked abilities', :cannot, :edit_notes, Activity
          specify { get :edit, id: @activity, activity_tab_id: activity_tab }
        end
      end

      context '#update' do
        include_context 'mocked abilities', :cannot, :edit, Activity
        specify { put :update, id: @activity }
      end

      context '#destroy' do
        include_context 'mocked abilities', :cannot, :delete, Activity
        specify { delete :destroy, id: @activity }
      end
    end
  end

  it 'index' do
    get :index
    expect(response).to redirect_to(request_projects_path)
  end

  context '#request_projects' do
    it 'render action' do
      Activity.delete_all
      activities = 26.times.collect{create(:activity)}
      get :request_projects
      activities[0..24].each{|el| expect(assigns(:activities)).to include(el)}
      expect(assigns(:activities)).to_not include(activities[25])
      expect(response).to render_template('request_projects')
    end

    it 'render partial' do
      xhr :get, :request_projects
      expect(response).to render_template(partial: 'activities/_request_projects')
    end
  end

  it '#new' do
    get :new, { activity_category_id: @activity_category.id }
    expect(response).to render_template('new')
  end

  it '#edit' do
    activity_tab = create(:activity_tab, activity_category: @activity_category)
    get :edit, id: @activity.id, activity_category_id: activity_tab
    expect(response).to render_template('edit')
  end

  context '#create' do
    it 'success, returns flash and redirect' do
      post :create, { activity: { activity_category_id: @activity_category.id,
                                  name: 'Project_name',
                                  health: '' }}
      expect(flash[:success]).to include('successfully')
      expect(response).to redirect_to(activity_category_path(@activity.activity_category))
    end

    it 'fails and render action new' do
      @activity = Activity.new
      Activity.stub(:new).and_return(@activity)
      @activity.stub(:save).and_return(false)
      post :create, { activity: { activity_category_id: @activity_category.id,
                                 health: '' }}
      expect(response).to render_template(controller: 'activities', action: :new)
    end
  end

  it '#show' do
    get :show, { id: @activity.id }
    expect(response).to redirect_to(action: 'edit')
  end

  it '#show_read_only' do
    get :show_read_only, { id: @activity.id }
    expect(response).to render_template('activities/edit')
  end

  context '#update' do
    before(:each) do
      @activity_tab = create(:activity_tab, activity_category: @activity_category)
    end

    it 'success and redirect to activity edit path' do
      @activity_tab.name = 'Notes'
      @activity_category.activity_tabs << @activity_tab
      put :update, { id: @activity.id,
                     activity_tab_id: @activity_tab.id,
                     activity: { name: 'Name_changed' }}
      @activity.reload
      @activity.name.should eql('Name_changed')
      expect(response).to redirect_to(edit_activity_path(@activity, activity_tab_id: @activity_tab.id))
    end

    it 'redirect to activities path and returns flash' do
      @activity_tab.name = 'Tab1'
      @activity_category.activity_tabs << @activity_tab
      put :update, { id: @activity.id,
                     activity_tab_id: @activity_tab.id }
      expect(flash[:success]).to include('successfully')
      expect(response).to redirect_to(activities_path)
    end

    it 'render action edit' do
      Activity.stub(:find).and_return(@activity)
      @activity.stub(:update_attributes).and_return(false)
      put :update, { id: @activity.id,
                     activity_tab_id: '' }
      expect(response).to render_template('edit')
    end
  end

  it '#destroy' do
    expect{ delete :destroy, { id: @activity.id }
          }.to change(Activity, :count).by(-1)
    expect(response).to redirect_to(activities_path)
  end

  it '#creation_attributes' do
    get :creation_attributes, {activity_category_id: @activity_category.id}
    expect(response).to render_template(partial: '_creation_attributes')
  end

  context 'deliverable' do
    before(:each) do
      @activity_phase = create(:activity_phase, activity_category: @activity_category)
      @activity_category.activity_phases << @activity_phase
      @activity.activity_category = @activity_category
      @deliverable = create(:activity_deliverable, activity: @activity)
    end

    it 'create' do
      pending 'ActiveModel::MassAssignmentSecurity::Error Can not mass-assign protected attributes: activity_phase'
      get :modify_deliverable, { id: @activity.id, phase_id: @activity_phase.id }
      expect(response).to render_template('activities/widgets/deliverables/modify_deliverable')
    end

    it 'modify' do
      get :modify_deliverable, { id: @activity.id,
                                 deliverable_id: @deliverable.id }
      expect(response).to render_template('activities/widgets/deliverables/modify_deliverable')
    end

    context 'save' do
      it 'success' do
        pending 'ActiveModel::MassAssignmentSecurity::Error'
        post :save_deliverable, { id: @activity.id,
                                  deliverable_id: @deliverable.id,
                                  activity_deliverable: { projected_delivery_on: '11/17/2013',
                                                          delivered_on: '11/17/2013' }}
        @deliverable.reload
        @deliverable.projected_delivery_date.should eql('11/17/2013')
        expect(response).to render_template('activities/widgets/deliverables/save_deliverable')
      end

      it 'returns errors' do
        pending 'ActiveModel::MassAssignmentSecurity::Error'
        ActivityDeliverable.stub(:find).and_return(@deliverable)
        @deliverable.stub(:errors).and_return('Errors')
        post :save_deliverable, { id: @activity.id,
                                  deliverable_id: @deliverable.id,
                                  activity_deliverable: { projected_delivery_on: '11/17/2013',
                                                          delivered_on: '11/17/2013' }}
        expect(response).to render_template('activities/widgets/deliverables/invalid_deliverable')
      end
    end

    it 'destroy' do
      expect{delete :destroy_deliverable, { id: @activity.id,
                                            deliverable_id: @deliverable.id }
            }.to change(ActivityDeliverable, :count).by(-1)
      expect(response).to render_template('activities/widgets/deliverables/save_deliverable')
    end
  end

  it '#load_requests' do
    get :load_requests, {id: @activity.id}
    expect(response).to render_template( partial: 'plans/release_calendar/_requests' )
  end
end
