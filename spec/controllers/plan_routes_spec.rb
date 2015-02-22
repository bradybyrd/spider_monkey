require 'spec_helper'

describe PlanRoutesController, type: :controller do
  before(:each) { @plan = create(:plan) }

  it '#index' do
    PlanRoute.delete_all
    26.times.collect{create(:plan_route, plan: @plan)}
    plan_routes = PlanRoute.where(plan_id: @plan.id).in_app_name_order

    get :index, {:plan_id => @plan.id}

    routes = assigns(:plan_routes)
    plan_routes[0..24].each{|el| expect(routes).to include(el)}
    expect(routes).to_not include(plan_routes[25])
    expect(response).to render_template('plans/show')
  end

  it '#show' do
    plan_route = create(:plan_route, plan: @plan)
    plan_stage = create(:plan_stage)
    plan_stage_instance = create(:plan_stage_instance, plan: @plan, plan_stage: plan_stage)
    get :show, { plan_id: @plan.id,
                 id: plan_route.id}
    expect(assigns(:plan_stage_instances)).to include(plan_stage_instance)
  end

  context '#new' do
    context 'success' do
      it 'xhr' do
        xhr :get, :new, { plan_id: @plan.id }
        expect(response).to render_template('new')
      end

      it 'render action' do
        get :new, { plan_id: @plan.id }
        expect(response).to render_template('new')
      end
    end

    it 'fails' do
      Plan.stub(:find_by_id).and_return(@plan)
      @plan.stub(:blank?).and_return(true)

      get :new, { plan_id: @plan.id }

      expect(response).to redirect_to(plan_plan_routes_path(@plan))
    end
  end

  context '#create' do
    before(:each) do
      @app = create(:app)
      @route = create(:route)
    end

    context 'success' do
      it 'ajax redirects' do
        xhr :post, :create, { plan_id: @plan.id,
                              plan_route: { route_app_id: @app.id,
                                            route_id: @route.id }}
        expect(response).to render_template('misc/redirect')
      end

      it 'redirects to plan_route path' do
        post :create, { plan_id: @plan.id,
                        plan_route: { route_app_id: @app.id,
                                      route_id: @route.id  }}
        expect(response.code).to eq '302'
      end
    end

    context 'fails' do
      before(:each) do
        @plan_route = mock_model(PlanRoute)
        Plan.stub(:find_by_id).and_return(@plan)
        @plan.plan_routes.stub(:build).and_return(@plan_route)
        @plan_route.stub(:save).and_return(false)
      end

      it 'ajax redirects' do
        xhr :post, :create, { plan_id: @plan.id,
                              plan_route: { route_app_id: @app.id,
                                            route_id: @route.id}}
        expect(response).to render_template('misc/error_messages_for')
      end

      it 'redirects to plan_route path' do
        post :create, { plan_id: @plan.id,
                        plan_route: { route_app_id: @app.id,
                                      route_id: @route.id }}
        expect(response).to render_template('new')
      end

      it 'returns errors' do
        post :create, { plan_id: @plan.id,
                        plan_route: {route_id: @route.id} }
        expect(assigns(:plan_route).errors[:app]).to include('can\'t be blank')
      end
    end
  end

  it '#destroy' do
    plan_route = create(:plan_route, :plan => @plan)
    expect{ delete :destroy, { plan_id: @plan.id,
                               id: plan_route.id }
          }.to change(PlanRoute, :count).by(-1)
    expect(response).to redirect_to( plan_plan_routes_url(@plan))
  end
end