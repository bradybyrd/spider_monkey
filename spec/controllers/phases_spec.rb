require 'spec_helper'

describe PhasesController, :type => :controller do
  before (:each) { @phase = create(:phase) }

  #### common values
  model = Phase
  factory_model = :phase
  can_archive = true
  #### values for index
  models_name = 'phases'
  model_index_path = 'index'
  be_sort = false
  per_page = 20
  index_flash = "No Phase"
  #### values for edit
  model_edit_path = '/index'
  edit_flash = 'not found'
  http_refer = '/index'
  #### values for create
  model_create_path = '/environment/metadata/phases'
  create_params =  {:phase => {:name => 'phase_name'}}
  #### values for update
  update_params = {:name => 'name_ch'}
  #### values for destroy
  model_delete_path = '/environment/metadata/phases'

  it_should_behave_like("CRUD GET index", model, models_name, factory_model, model_index_path, can_archive, be_sort, per_page, index_flash)
  it_should_behave_like("CRUD GET new")
  it_should_behave_like("CRUD GET edit", factory_model, model_edit_path, edit_flash, http_refer)
  it_should_behave_like("CRUD POST create", model, factory_model, model_create_path, create_params)
  it_should_behave_like("CRUD PUT update", model, factory_model, update_params)
  it_should_behave_like("CRUD DELETE destroy", model, factory_model, model_delete_path, can_archive)

  context "#show" do
    it "success" do
      get :show, {:id => @phase.id}
      response.should render_template('edit')
    end

    it "fails" do
      get :show, {:id => "-1"}
      flash[:error].should include("not found")
      response.should redirect_to(phases_path)
    end
  end

  it "#destroy_runtime_phase" do
    @rt_phase = create(:runtime_phase, :phase => @phase)
    expect{delete :destroy_runtime_phase, {:id => @phase,
                                           :runtime_phase_id => @rt_phase}
          }.to change(@phase.reload.runtime_phases, :count).by(-1)
    response.should be_truthy
  end

  context "#reorder" do
    specify "without row_type" do
      put :reorder, {:id => @phase.id,
                     :phase => {:insertion_point => 2}}
      @phase.reload
      @phase.insertion_point.should eql(2)
      response.should render_template(:partial => 'phases/_phase')
    end

    specify "with row_type" do
      @rt_phase = create(:runtime_phase,
                         :phase => @phase,
                         :insertion_point => 1)
      params = {:id => @rt_phase.id,
                :runtime_phase => {:insertion_point => 5},
                :row_type => "runtime_phase"}
      put :reorder, params
      @rt_phase.reload
      @rt_phase.insertion_point.should eql(5)
      response.should render_template(:partial => 'phases/_runtime')
    end
  end

  describe '#index' do
    it_behaves_like 'authorizable', controller_action: :index
  end

  describe '#new' do
    it_behaves_like 'authorizable', controller_action: :new
  end

  describe '#create' do
    it_behaves_like 'authorizable', controller_action: :create,
                                    http_method: :post
  end

  describe '#edit' do
    it_behaves_like 'authorizable', controller_action: :edit do
      let(:params) { { id: create(:phase).id } }
    end
  end

  describe '#update' do
    it_behaves_like 'authorizable', controller_action: :update,
                                    http_method: :put do
      let(:params) { { id: create(:phase).id } }
    end
  end

  describe '#destroy' do
    it_behaves_like 'authorizable', controller_action: :destroy,
                                    http_method: :delete do
      let(:params) { { id: create(:phase).id } }
    end
  end

  describe '#archive' do
    it_behaves_like 'authorizable', controller_action: :archive,
                                    http_method: :put do
      let(:params) { { id: create(:phase).id } }
    end
  end

  describe '#unarchive' do
    it_behaves_like 'authorizable', controller_action: :unarchive,
                                    http_method: :put do
      let(:params) { { id: create(:phase).id } }
    end
  end
end
