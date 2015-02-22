require 'spec_helper'

describe RoutesController, type: :controller do
  before(:each) do
    @app = create(:app)
    @route = create(:route, app: @app)
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

  it '#index' do
    Route.delete_all
    unarchived_routes = 21.times.collect{create(:route, :app => @app)}
    unarchived_routes.sort_by!{|el| el.name}
    archived_routes = 21.times.collect{create(:route, :app => @app)}
    archived_routes.sort_by!{|el| el.name}
    archived_routes.each{|el| el.archive}

    get :index, { app_id: @app.id, per_page: 20, page: 1 }

    expected_routes = assigns(:routes)
    unarchived_routes[0..19].each{|el| expect(expected_routes).to include(el)}
    expect(expected_routes).to_not include(unarchived_routes[20])
    expect(expected_routes).to_not include(archived_routes)

    expected_arch_routes = assigns(:archived_routes)
    archived_routes[0..19].each{|el| expect(expected_arch_routes).to include(el)}
    expect(expected_arch_routes).to_not include(archived_routes[20])
    expect(expected_arch_routes).to_not include(unarchived_routes)

    expect(response).to render_template('apps/edit')
  end

  it '#show' do
    get :show, { app_id: @app.id, id: @route.id }

    expect(response).to render_template('show')
  end

  it '#new' do
    get :new, app_id: @app.id

    expect(response).to render_template('new')
  end

  context '#edit' do
    it 'success' do
      get :edit, { app_id: @app.id, id: @route.id }

      expect(response).to render_template('edit')
    end

    it 'fails' do
      get :edit, { app_id: @app.id, id: '-1' }

      expect(flash[:error]).to include('does not exist')
      expect(response).to redirect_to(app_routes_path(@app))
    end
  end

  context '#create' do
    it 'redirects to route path' do
      post :create, { app_id: @app.id,
                      route: { name: 'route1',
                               route_type: 'open',
                               app_id: @app.id }}

      expect(flash[:notice]).to include('successfully')
      expect(response).to redirect_to(app_route_path(@app, @app.routes.last))
    end

    it "renders action new" do
      App.stub(:find).and_return(@app)
      @app.routes.stub(:create).and_return(@route)
      @route.stub(:save).and_return(false)

      post :create, { app_id: @app.id,
                      route: { name: 'route1',
                               route_type: 'open',
                               app_id: @app.id }}

      expect(response).to render_template('new')
    end
  end

  context '#update' do
    it 'redirects to route path' do
      put :update, { app_id: @app.id,
                     id: @route.id,
                     route: { name: 'route_changed' }}
      @route.reload
      expect(@route.name).to eq 'route_changed'
      expect(flash[:notice]).to include('successfully')
      expect(response).to redirect_to(app_route_path(@app, @route))
    end

    it 'renders action new' do
      App.stub(:find).and_return(@app)
      @app.routes.stub(:find).and_return(@route)
      @route.stub(:update_attributes).and_return(false)

      put :update, { app_id: @app.id,
                     id: @route.id,
                     route: { name: 'route_changed'}}

      expect(response).to render_template('edit')
    end
  end

  context '#destroy' do
    it 'success' do
      @route.archive

      expect{
        delete :destroy, { app_id: @app.id, id: @route.id }
      }.to change(Route, :count).by(-1)
      expect(response).to redirect_to(app_routes_path(@app))
    end

    it 'fails' do
      expect{
        delete :destroy, { app_id: @app.id, id: @route.id }
      }.to change(Route, :count).by(0)
      expect(response).to redirect_to(app_routes_path(@app))
    end
  end

  context '#add_environments' do
    context 'success' do
      before(:each) do
        @env = create(:environment)
        create(:application_environment, app: @app, environment: @env)
      end

      it 'ajax redirects' do
        xhr :post, :add_environments, { app_id: @app.id,
                                        id: @route.id,
                                        new_environment_ids: [@env.id] }
        @route.reload
        expect(@route.environments).to include(@env)
        expect(response).to render_template('misc/redirect')
      end

      it 'html redirects' do
        post :add_environments, { app_id: @app.id,
                                  id: @route.id,
                                  new_environment_ids: [@env.id] }
        @route.reload
        expect(@route.environments).to include(@env)
        expect(response).to redirect_to(app_route_path(@app, @route))
      end
    end

    it 'fails' do
      @route.stub(:present?).and_return(false)

      post :add_environments, { app_id: @app.id,
                                id: @route.id,
                                new_environment_ids: [] }

      expect(response).to redirect_to(app_route_path(@app, @route))
    end
  end
end