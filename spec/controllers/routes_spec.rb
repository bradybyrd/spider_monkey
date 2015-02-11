require 'spec_helper'

describe RoutesController, :type => :controller do
  before(:each) do
    @app = create(:app)
    @route = create(:route, :app => @app)
  end

  context 'authorization' do
    context 'authorize fails' do
      after { expect(response).to redirect_to root_path }

      context '#index' do
        include_context 'mocked abilities', :cannot, :list, Route
        specify { get :index, app_id: @app.id }
      end

      context '#new' do
        include_context 'mocked abilities', :cannot, :create, Route
        specify { get :new, app_id: @app.id }
      end

      context '#create' do
        include_context 'mocked abilities', :cannot, :create, Route
        specify { post :create, app_id: @app.id }
      end

      context '#show' do
        include_context 'mocked abilities', :cannot, :inspect, Route
        specify { get :show, id: @route.id, app_id: @app.id }
      end

      context '#edit' do
        include_context 'mocked abilities', :cannot, :edit, Route
        specify { get :edit, id: @route.id, app_id: @app.id }
      end

      context '#update' do
        include_context 'mocked abilities', :cannot, :edit, Route
        specify { put :update, id: @route.id, app_id: @app.id }
      end

      context '#destroy' do
        include_context 'mocked abilities', :cannot, :destory, Route
        specify { delete :destroy, id: @route.id, app_id: @app.id }
      end
    end
  end

  it "#index" do
    Route.delete_all
    @unarchived_routes = 21.times.collect{create(:route, :app => @app)}
    @unarchived_routes.sort_by!{|el| el.name}
    @archived_routes = 21.times.collect{create(:route, :app => @app)}
    @archived_routes.sort_by!{|el| el.name}
    @archived_routes.each{|el| el.archive}
    get :index, {:app_id => @app.id,
                 :per_page => 20,
                 :page => 1}
    @unarchived_routes[0..19].each{|el| assigns(:routes).should include(el)}
    assigns(:routes).should_not include(@unarchived_routes[20])
    assigns(:routes).should_not include(@archived_routes)
    @archived_routes[0..19].each{|el| assigns(:archived_routes).should include(el)}
    assigns(:archived_routes).should_not include(@archived_routes[20])
    assigns(:archived_routes).should_not include(@unarchived_routes)
    response.should render_template("apps/edit")
  end

  it "#show" do
    get :show, {:app_id => @app.id, :id => @route.id}
    response.should render_template('show')
  end

  it "#new" do
    get :new, {:app_id => @app.id}
    response.should render_template('new')
  end

  context "#edit" do
    it "success" do
      get :edit, {:app_id => @app.id, :id => @route.id}
      response.should render_template('edit')
    end

    it "fails" do
      get :edit, {:app_id => @app.id, :id => '-1'}
      flash[:error].should include('does not exist')
      response.should redirect_to(app_routes_path(@app))
    end
  end

  context "#create" do
    it "redirects to route path" do
      post :create, {:app_id => @app.id,
                     :route => {:name => "route1",
                                :route_type => 'open',
                                :app_id => @app.id}}
      flash[:notice].should include('successfully')
      response.should redirect_to(app_route_path(@app, @app.routes.last))
    end

    it "renders action new" do
      App.stub(:find).and_return(@app)
      @app.routes.stub(:create).and_return(@route)
      @route.stub(:save).and_return(false)
      post :create, {:app_id => @app.id,
                     :route => {:name => "route1",
                                :route_type => 'open',
                                :app_id => @app.id}}
      response.should render_template('new')
    end
  end

  context "#update" do
    it "redirects to route path" do
      put :update, {:app_id => @app.id,
                    :id => @route.id,
                    :route => {:name => "route_changed"}}
      @route.reload
      @route.name.should eql("route_changed")
      flash[:notice].should include('successfully')
      response.should redirect_to(app_route_path(@app, @route))
    end

    it "renders action new" do
      App.stub(:find).and_return(@app)
      @app.routes.stub(:find).and_return(@route)
      @route.stub(:update_attributes).and_return(false)
      put :update, {:app_id => @app.id,
                    :id => @route.id,
                    :route => {:name => "route_changed"}}
      response.should render_template('edit')
    end
  end

  context "#destroy" do
    it "success" do
      @route.archive
      expect{delete :destroy, {:app_id => @app.id,
                               :id => @route.id}
            }.to change(Route, :count).by(-1)
      response.should redirect_to(app_routes_path(@app))
    end

    it "fails" do
      expect{delete :destroy, {:app_id => @app.id,
                               :id => @route.id}
            }.to change(Route, :count).by(0)
      response.should redirect_to(app_routes_path(@app))
    end
  end

  context "#add_environments" do
    context "success" do
      before(:each) do
        @env = create(:environment)
        @app_env = create(:application_environment, :app => @app, :environment => @env)
      end

      it "ajax redirects" do
        xhr :post, :add_environments, {:app_id => @app.id,
                                       :id => @route.id,
                                       :new_environment_ids => [@env.id]}
        @route.reload
        @route.environments.should include(@env)
        response.should render_template('misc/redirect')
      end

      it "html redirects" do
        post :add_environments, {:app_id => @app.id,
                                 :id => @route.id,
                                 :new_environment_ids => [@env.id]}
        @route.reload
        @route.environments.should include(@env)
        response.should redirect_to(app_route_path(@app, @route))
      end
    end

    it "fails" do
      @route.stub(:present?).and_return(false)
      post :add_environments, {:app_id => @app.id,
                               :id => @route.id,
                               :new_environment_ids => []}
      response.should redirect_to(app_route_path(@app, @route))
    end
  end
end