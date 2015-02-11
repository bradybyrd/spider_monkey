require 'spec_helper'

describe IntegrationProjectsController, :type => :controller do
  before(:each) do
    @project_server = create(:project_server)
    @integration_project = @project_server.projects.new(:name => 'IP_name')
    @integration_project.save
  end

  describe 'authorization', custom_roles: true do
    context 'fails' do
      describe '#index' do
        include_context 'mocked abilities', :cannot, [:create, :edit, :make_active_inactive], IntegrationProject

        it 'redirects to root path' do
          get :index, project_server_id: @project_server.id
          is_expected.to redirect_to root_path
        end
      end
    end

    context 'successful' do
      describe '#index' do
        include_context 'mocked abilities', :can, :make_active_inactive, IntegrationProject

        it 'renders index' do
          get :index, project_server_id: @project_server.id
          is_expected.to render_template :index
        end
      end
    end
  end

  it "#index" do
    @project_server.projects.delete_all
    @integration_projects = 31.times.collect{@project_server.projects.new(:name => "IP_name")}
    @integration_projects.each {|el| el.save}
    @integration_projects.reverse!
    @inactive_project = @project_server.projects.new(:name => "IP_name_inactive")
    @inactive_project.active = false
    @inactive_project.save
    get :index, {:project_server_id => @project_server.id}
    @integration_projects[0..29].each {|el| assigns(:active_projects).should include(el)}
    assigns(:active_projects).should_not include(@integration_projects[30])
    assigns(:inactive_projects).should include(@inactive_project)
  end

  it "#new" do
    get :new, {:project_server_id => @project_server.id}
    response.should render_template('new')
  end

  context "#create" do
    it "success" do
      expect{post :create, {:project_server_id => @project_server.id,
                            :integration_project => {:name => "New_project"}}
            }.to change(@project_server.projects, :count).by(1)
      flash[:notice].should include('successfully')
      response.should redirect_to(project_server_integration_projects_url(@project_server))
    end

    it "fails" do
      ProjectServer.stub(:find).and_return(@project_server)
      @project_server.projects.stub(:new).and_return(@integration_project)
      @integration_project.stub(:save).and_return(false)
      post :create, {:project_server_id => @project_server.id,
                     :integration_project => {:name => "New_project"}}
      response.should render_template('new')
    end
  end

  it "#edit" do
    get :edit, {:project_server_id => @project_server.id,
                :id => @integration_project.id}
    response.should render_template('edit')
  end

  context "#update" do
    it "success" do
      put :update, {:project_server_id => @project_server.id,
                    :id => @integration_project.id,
                    :integration_project => {:name => "Name_changed"}}
      flash[:notice].should include('successfully')
      assigns(:integration_project).name.should eql("Name_changed")
      response.should redirect_to(project_server_integration_projects_url(@project_server))
    end

    it "fails" do
      ProjectServer.stub(:find).and_return(@project_server)
      @project_server.projects.stub(:find).and_return(@integration_project)
      @integration_project.stub(:update_attributes).and_return(false)
      put :update, {:project_server_id => @project_server.id,
                    :id => @integration_project.id,
                    :integration_project => {:name => "New_project"}}
      response.should render_template('edit')
    end
  end

  it "#destroy" do
    expect{delete :destroy, {:project_server_id => @project_server.id,
                             :id => @integration_project.id}
          }.to change(@project_server.projects, :count).by(-1)
    flash[:notice].should include('successfully')
    response.should redirect_to(project_server_integration_projects_url(@project_server))
  end

  it "#get_releases" do
    pending "No route"
    @release = create(:release)
    get :get_releases, {:id => @integration_project.id}
    response.body.should include(@release.name)
  end
end
