require 'spec_helper'

describe BusinessProcessesController, :type => :controller do
  #### common values
  model = BusinessProcess
  factory_model = :business_process
  can_archive = true
  #### values for index
  models_name = 'business_processes'
  model_index_path = 'index'
  be_sort = true
  per_page = 20
  index_flash = "No Business Processes"
  #### values for edit
  model_edit_path = '/environment/metadata/processes'
  edit_flash = 'does not exist'
  http_refer = nil
  #### values for destroy
  model_delete_path = '/environment/metadata/processes'

  it_should_behave_like("CRUD GET index", model, models_name, factory_model, model_index_path, can_archive, be_sort, per_page, index_flash)
  it_should_behave_like("CRUD GET new")
  it_should_behave_like("CRUD GET edit", factory_model, model_edit_path, edit_flash, http_refer)
  it_should_behave_like("CRUD DELETE destroy", model, factory_model, model_delete_path, can_archive)

  context "#create" do
    it "success" do
      @app = create(:app)
      post :create, {:business_process => {:name => "BP1",
                                           :label_color => '#7FFF00',
                                           :app_ids => [@app.id]}}
      flash[:notice].should include('successfully')
      response.should redirect_to(processes_path)
    end

    it "fails" do
      @business_process = BusinessProcess.new
      BusinessProcess.stub(:new).and_return(@business_process)
      @business_process.stub(:save).and_return(false)
      post :create, {:business_process => {:name => "BP1",
                                           :label_color => '#7FFF00'}}
      response.should render_template('new')
    end

    it_behaves_like 'authorizable', controller_action: :create,
                                    http_method: :post
  end

  context "#update" do
    before (:each) { @business_process = create(:business_process) }

    it "success" do
      @app = create(:app)
      put :update, {:id => @business_process.id,
                    :business_process => {:app_ids => [@app.id]}}
      @business_process.reload
      @business_process.app_ids.should include(@app.id)
      flash[:notice].should include('successfully')
      response.should redirect_to(processes_path)
    end

    it "doesn`t update app" do
      @app1 = create(:app)
      @app2 = create(:app)
      @business_process = create(:business_process, :app_ids =>[@app1.id])
      @env = create(:environment)
      @app1.environments << @env
      AssignedEnvironment.create!(:environment_id => @env.id, :assigned_app_id => @app1.assigned_apps.first.id, :role => @user.roles.first)
      @req = create(:request, :business_process => @business_process,
                              :environment_id => @env.id,
                              :apps => [@app1],
                              :owner => @user)
      put :update, {:id => @business_process.id,
                    :business_process => {:name => 'Changed',
                                          :app_ids => [@app2.id]}}
      flash[:error].should include('request uses an app')
      response.should render_template('edit')
    end

    it "fails and renders action edit" do
      BusinessProcess.stub(:find).and_return(@business_process)
      @business_process.stub(:validate_updated_apps).and_return(true)
      @business_process.stub(:update_attributes).and_return(false)
      put :update, {:id => @business_process.id,
                    :business_process => {:name => 'Changed'}}
      response.should render_template('edit')
    end

    it_behaves_like 'authorizable', controller_action: :update,
                                    http_method: :put do
      let(:params) { { id: create(:business_process).id } }
    end
  end

  describe '#index' do
    it_behaves_like 'authorizable', controller_action: :index
  end

  describe '#new' do
    it_behaves_like 'authorizable', controller_action: :new
  end

  describe '#edit' do
    it_behaves_like 'authorizable', controller_action: :edit do
      let(:params) { { id: create(:business_process).id } }
    end
  end

  describe '#destroy' do
    it_behaves_like 'authorizable', controller_action: :destroy,
                                    http_method: :delete do
      let(:params) { { id: create(:business_process).id } }
    end
  end

  describe '#archive' do
    it_behaves_like 'authorizable', controller_action: :archive,
                                    http_method: :put do
      let(:params) { { id: create(:business_process).id } }
    end
  end

  describe '#unarchive' do
    it_behaves_like 'authorizable', controller_action: :unarchive,
                                    http_method: :put do
      let(:params) { { id: create(:business_process).id } }
    end
  end
end
