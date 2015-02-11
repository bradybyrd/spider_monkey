require 'spec_helper'

describe ServerLevelsController, :type => :controller do
  before (:each) { @server_level = create(:server_level) }

  describe 'authorization', custom_roles: true do
    context 'fails' do
      after { should redirect_to root_path }

      describe '#show' do
        include_context 'mocked abilities', :cannot, :inspect, ServerLevel
        specify { get :show, id: @server_level }
      end

      describe '#new' do
        include_context 'mocked abilities', :cannot, :create, ServerLevel
        specify { get :new }
      end

      describe '#create' do
        include_context 'mocked abilities', :cannot, :create, ServerLevel
        specify { post :create }
      end

      describe '#edit' do
        include_context 'mocked abilities', :cannot, :edit, ServerLevel
        specify { get :edit, id: @server_level }
      end

      describe '#update' do
        include_context 'mocked abilities', :cannot, :edit, ServerLevel
        specify { put :update, id: @server_level }
      end
    end
  end

  it "#new" do
    get :new
    response.should render_template(:partial => '_form')
  end

  context "#create" do
    it "success" do
      post :create, {:server_level => {:name => 'SL1'},
                     :format => 'js'}
      flash[:success].should include('successfully')
      lambda {should change(ServerLevel, :count).by(1)}
    end

    it "fails" do
      ServerLevel.stub(:new).and_return(@server_level)
      @server_level.stub(:save).and_return(false)
      post :create, :format => 'js'
      flash[:error].should include('problem')
    end
  end

  context "#show" do
    it "return flash 'No servers aspects'" do
      @server = create(:server, :active => true)
      @server_aspect = create(:server_aspect,
                              :server_level_id => @server_level.id,
                              :parent => @server)
      @server_level2 = create(:server_level)
      @server_group = create(:server_group, :active => true)
      get :show, {:id => @server_level2.id}
      assigns(:server_aspect).parent.should eql(@server_aspect)
      flash[:error].should include('No  Instances')
    end

    it "render partial" do
      get :show, {:id => @server_level.id, :render_no_rjs => true}
      response.should render_template(:partial => "_server_level_show")
    end

    it "return aspects servers" do
      @server = create(:server)
      @servers_aspect = 31.times.collect{|x| create(:server_aspect,
                                                    :name => "Dev#{x}",
                                                    :server_level => @server_level,
                                                    :parent => @server)}
      @servers_aspect.sort_by!{|el| el.name}
      get :show, {:id => @server_level.id,
                  :key => 'Dev'}
      @servers_aspect[0..29].each {|el| assigns(:server_level_server_aspect).should include(el)}
      assigns(:server_level_server_aspect).should_not include(@servers_aspect[30])
      response.should render_template('show')
    end
  end

  it "#edit" do
    get :edit, {:id => @server_level.id, :format => 'js'}
    assigns(:server_level).should eql(@server_level)
    response.should render_template('edit')
  end

  it "#update" do
    put :update, {:id => @server_level.id,
                  :server_level => {:name => 'SLch'},
                  :format => 'js'}
    @server_level.reload
    @server_level.name.should eql('SLch')
    response.should be_success
  end

  context "#search" do
    specify "with keyword" do
      pending "undefined method `server_level_id_equals'"
      @server = create(:server)
      @server_aspect = create(:server_aspect, :server_level => @server_level, :parent => @server, :name => 'Dev1')
      get :search, {:id => @server_level.id,
                    :key => "Dev"}
      response.should render_template('show')
      assigns(:server_level_server_aspect).should include(@server_aspect)
    end

    specify "without keyword" do
      get :search, {:id => @server_level.id}
      response.should redirect_to(server_level_path(@server_level.id))
    end
  end
end
