require 'spec_helper'

describe VersionTagsController, :type => :controller do
  #### common values
  model = VersionTag
  factory_model = :version_tag
  can_archive = true
  #### values for index
  models_name = 'version_tags'
  model_index_path = 'index'
  be_sort = true
  per_page = 20
  index_flash = ""
  #### values for edit
  model_edit_path = '/environment/metadata/version_tags'
  edit_flash = 'does not exist'
  http_refer = nil
  #### values for destroy
  model_delete_path = '/environment/metadata/version_tags'

  it_should_behave_like("CRUD GET index", model, models_name, factory_model, model_index_path, can_archive, be_sort, per_page, index_flash)
  it_should_behave_like("CRUD GET new")
  it_should_behave_like("CRUD GET edit", factory_model, model_edit_path, edit_flash, http_refer)
  it_should_behave_like("CRUD DELETE destroy", model, factory_model, model_delete_path, can_archive)

  before(:each) { @version_tag = create(:version_tag) }

  context "#index" do
    before(:each) do
      VersionTag.delete_all
      @version_tag1 = create(:version_tag, :name => "Dev1")
      @version_tag2 = create(:version_tag, :name => "CC")
      @version_tag3 = create(:version_tag, :name => "Dev2")
      @version_tag4 = create(:version_tag, :name => "CC")
      @version_tag3.archive
      @version_tag4.archive
    end

    it "renders partial ajax_search_section" do
      xhr :get, :index
      response.should render_template(:partial => '_ajax_search_section')
    end

    it "returns ordered version tags" do
      @version_tags = []
      @version_tags << @version_tag2
      @version_tags << @version_tag1
      @archived_version_tags = []
      @archived_version_tags << @version_tag4
      @archived_version_tags << @version_tag3
      get :index, {:order => {"0" => [:name, 'ASC']}}
      assigns(:version_tags).should == @version_tags
      assigns(:archived_version_tags).should == @archived_version_tags
    end

    it "returns valid data with keyword" do
      get :index, {:key => "Dev"}
      assigns(:version_tags).should include(@version_tag1)
      assigns(:version_tags).should_not include(@version_tag2)
      assigns(:archived_version_tags).should include(@version_tag3)
      assigns(:archived_version_tags).should_not include(@version_tag4)
    end
  end

  context "#details" do
    it "returns archived version tags" do
      VersionTag.delete_all
      @version_tag = create(:version_tag)
      @archived_version_tags = 21.times.collect{create(:version_tag, :name => 'Dev')}
      @archived_version_tags.each{|el| el.archive}
      @archived_version_tags.sort_by!{ |el| el.name}
      get :details, {:id => @version_tag.id, :key => 'Dev',
                     :order => {"0" => [:id, 'ASC']}}
      @archived_version_tags[0..19].each{|el| assigns(:version_tags).should include(el)}
      assigns(:version_tags).should_not include(@archived_version_tags[20])
      response.should render_template(:partial => 'version_tags/_details')
    end

    it "returns unarchived version tags" do
      VersionTag.delete_all
      @version_tags = 21.times.collect{create(:version_tag)}
      @version_tags.sort_by!{ |el| el.name}
      get :details, {:id => @version_tags[0].id,
                     :position => 'unarchived',
                     :order => {"0" => [:name, 'ASC']}}
      @version_tags[0..19].each{|el| assigns(:version_tags).should include(el)}
      assigns(:version_tags).should_not include(@version_tags[20])
      response.should render_template(:partial => 'version_tags/_details')
    end
  end

  context "#create" do
    before(:each) do
      create_installed_component
      @params = {:app_id => @app.id,
                 :app_env_id => @app_env.id,
                 :installed_component_id => @installed_component.id,
                 :version_tag => {:name => "VT1"}}
    end

    it "redirects to version_tags_path" do
      post :create, @params
      flash[:notice].should include('successfully')
      response.should redirect_to(version_tags_path)
    end

    it "render action new" do
      VersionTag.stub(:new).and_return(@version_tag)
      @version_tag.stub(:save).and_return(false)
      post :create, @params
      response.should render_template('new')
    end
  end

  context "#bulk_create" do
    it "renders form" do
      get :bulk_create
      response.should render_template("bulk_create")
    end

    it "returns errors" do
      post :bulk_create
      assigns(:errors).should include("Name cannot be blank.")
      response.should render_template("bulk_create")
    end

    it "successfully creates version tags" do
      create_installed_component
      post :bulk_create, {:name => "VT1",
                          :app_id => @app.id,
                          :component_id => @component.id,
                          :environment_ids => [@env.id],
                          :artifact_url => "/index"}
      flash[:success].should include("Created 1 version tags")
      response.should redirect_to(version_tags_path)
    end

    it "successfully updates version tags" do
      create_installed_component
      @version_tag = create(:version_tag,
                            :name => "VT1",
                            :installed_component_id => @installed_component.id)
      post :bulk_create, {:name => "VT1",
                          :app_id => @app.id,
                          :component_id => @component.id,
                          :environment_ids => [@env.id],
                          :artifact_url => "/index"}
      flash[:success].should include("Updated 1 version tags")
      response.should redirect_to(version_tags_path)
    end

    it "returns error 'Could not create'" do
      create_installed_component
      VersionTag.stub(:new).and_return(@version_tag)
      @version_tag.stub(:update_attributes).and_return(false)
      xhr :post, :bulk_create, {:name => "VT1",
                               :app_id => @app.id,
                               :component_id => @component.id,
                               :environment_ids => [@env.id],
                               :artifact_url => "/index"}
      flash[:error].should include("Could not create/update")
      response.should render_template("misc/redirect")
    end

    it "returns validation errors" do
      create_installed_component
      VersionTag.stub(:new).and_return(@version_tag)
      @version_tag.stub(:update_attributes).and_return(false)
      @version_tag.errors.stub(:size).and_return(2)
      xhr :post, :bulk_create, {:name => "VT1",
                                :app_id => @app.id,
                                :component_id => @component.id,
                                :environment_ids => [@env.id],
                                :artifact_url => "/index"}
      response.should render_template("misc/error_messages_for")
    end
  end

  context "#update" do
    before(:each) do
      create_installed_component
      @params = {:id => @version_tag.id,
                 :app_id => @app.id,
                 :app_env_id => @app_env.id,
                 :installed_component_id => @installed_component.id,
                 :version_tag => {:name => "Changed_name"}}
    end

    it "success" do
      put :update, @params
      flash[:notice].should include('successfully')
      response.should redirect_to(version_tags_path)
    end

    it "fails" do
      VersionTag.stub(:find).and_return(@version_tag)
      @version_tag.stub(:update_attributes).and_return(false)
      put :update, @params
      response.should render_template('edit')
    end
  end

  it "#artifact_url" do
    xhr :get, :artifact_url, {:id => @version_tag.id}
    response.should render_template(:text => @version_tag.artifact_url)
  end

  context "#app_component_remote_options" do
    it "returns app component" do
      create_installed_component
      get :app_component_remote_options, {:app_id => @app.id}
      response.body.should include(@app_component.name)
    end

    it "returns nothing" do
      get :app_component_remote_options
      response.should render_template(:text => "")
    end
  end

  context "#app_env_pick_list" do
    it "returns app environment and renders partial" do
      create_installed_component
      get :app_env_pick_list, {:app_id => @app.id}
      assigns(@environments)["environments"].should include(@env)
      response.should render_template(:partial => "_app_env_pick_list")
    end

    it "returns app installed component" do
      create_installed_component
      get :app_env_pick_list, {:app_id => @app.id,
                               :component_id => @component}
      assigns(@environments)["environments"].should include(@env)
    end

    it "returns text" do
      get :app_env_pick_list
      response.should render_template(:text => "Please select an Application")
    end
  end

  context "#app_env_remote_options" do
    it "returns app environments" do
      create_installed_component
      get :app_env_remote_options, {:id => @version_tag.id,
                                    :app_id => @app.id}
      response.body.should include(@app_env.name)
    end

    it "returns nothing" do
      get :app_env_remote_options
      response.should render_template(:text => "")
    end

    it "returns new version_tag" do
      create_installed_component
      get :app_env_remote_options, {:app_id => @app.id}
      response.body.should include(@app_env.name)
    end
  end

  context "#installed_component_remote_options" do
    it "returns app installed components" do
      create_installed_component
      get :installed_component_remote_options, {:id => @version_tag.id,
                                                :app_env_id => @app_env.id}
      response.body.should include(@installed_component.name)
    end

    it "returns nothing" do
      get :installed_component_remote_options
      response.should render_template(:text => "")
    end
  end


  context "#archive" do
    it "success" do
      put :archive, {:id => @version_tag.id}
      @version_tag.reload
      @version_tag.archive.should be_truthy
      response.should redirect_to(:action => 'index')
    end

    it "fails" do
      VersionTag.stub(:find).and_return(@version_tag)
      @version_tag.stub(:archive).and_return(false)
      put :archive, {:id => @version_tag.id}
      @version_tag.reload
      @version_tag.archive.should_not be_truthy
      flash[:error].should include('was a problem')
      response.should redirect_to(:action => 'index')
    end
  end

  context "#unarchive" do
    it "success" do
      @version_tag.archive
      put :unarchive, {:id => @version_tag.id}
      @version_tag.reload
      @version_tag.unarchive.should be_truthy
      response.should redirect_to(:action => 'index')
    end

    it "fails" do
      VersionTag.stub(:find).and_return(@version_tag)
      @version_tag.stub(:unarchive).and_return(false)
      put :unarchive, {:id => @version_tag.id}
      @version_tag.reload
      @version_tag.unarchive.should_not be_truthy
      flash[:error].should include('was a problem')
      response.should redirect_to(:action => 'index')
    end
  end

  def create_installed_component
    @app = create(:app)
    @env = create(:environment)
    @app_env =  create(:application_environment,
                       :app => @app,
                       :environment => @env)
    @component = create(:component)
    @app_component = create(:application_component,
                            :app => @app,
                            :component => @component)
    @installed_component = create(:installed_component,
                                  :application_environment => @app_env,
                                  :application_component => @app_component)
  end
end
