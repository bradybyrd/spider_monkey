require 'spec_helper'

describe ConstraintsController, type: :controller do
  before(:each) do
    @app = create(:app)
    @env = create(:environment)
    @env_type = create(:environment_type)
    @app_env = create(:application_environment, app: @app, environment: @env)
    @component = create(:component)
    @app_component = create(:application_component, app: @app, component: @component)
    @installed_component = create(:installed_component, application_component: @app_component,
                                                        application_environment: @app_env)
    @route = create(:route)
    @route_gate = create(:route_gate, route: @route, environment: @env)
    @plan_template = create(:plan_template)
    @plan_stage = create(:plan_stage, plan_template: @plan_template)
    @plan = create(:plan, plan_template: @plan_template)
    @plan_route = create(:plan_route, plan: @plan, route: @route)
    @constraint = create(:constraint, governable: @plan_route,
                                      constrainable: @route_gate)
  end

  describe 'authorization', custom_roles: true do
    context 'authorization fails' do
      after { should redirect_to root_path }

      describe '#create' do
        include_context 'mocked abilities', :cannot, :configure, Constraint
        specify { post :create, plan_route_id: @plan_route.id }
      end

      describe '#destroy' do
        include_context 'mocked abilities', :cannot, :configure, Constraint
        specify { delete :destroy, id: @constraint }
      end
    end
  end

  context '#create' do
    before(:each) do
      Constraint.delete_all
      @params = { plan_route_id: @plan_route.id,
                  constraint: { governable_id: @plan_stage,
                                governable_type: 'PlanStageInstance',
                                constrainable_id: @route_gate.id,
                                constrainable_type: 'RouteGate' }}
    end

    context 'success' do
      it 'ajax redirect' do
        xhr :post, :create, @params
        expect(response).to render_template('misc/redirect')
      end

      it 'redirects to plan route path' do
        post :create, @params
        expect(response).to redirect_to(plan_plan_route_path(@plan_route.plan, @plan_route))
      end
    end

    context 'fails' do
      before(:each) do
        Constraint.stub(:new).and_return(@constraint)
        @constraint.stub(:save).and_return(false)
        @params = { plan_route_id: @plan_route.id,
                    constraint: { governable_id: @plan_stage.id,
                                  constrainable_id: @route_gate.id }}
      end

      it 'shows validation errors' do
        xhr :post, :create, @params
        expect(response).to render_template('error_messages_for')
      end

      it 'renders action new' do
        pending 'missing template. No constrain folder'
        post :create, @params
        expect(response).to render_template('new')
      end
    end
  end

  it '#update' do
    @constraint.constrainable_type = 'Route'
    @constraint.save

    put :update, { id: @constraint.id, category: { constrainable_type: 'RouteGate' }}

    @constraint.reload
    expect(@constraint.constrainable_type).to eq 'RouteGate'
    expect(response).to redirect_to(root_path)
  end

  it '#destroy' do
    expect{ delete :destroy, { id: @constraint.id }
           }.to change(Constraint, :count).by(-1)
    expect(response).to redirect_to(plan_plan_route_path(@plan_route.plan_id, @plan_route))
  end
end
