require 'spec_helper'

describe RouteGatesController, :type => :controller do
  before(:each) do
    @app = create(:app)
    @route = create(:route, :app => @app)
    @route_gate = create(:route_gate, :route => @route)
  end

  context 'authorization' do
    context 'authorize fails' do
      after { expect(response).to redirect_to root_path }

      context '#update' do
        include_context 'mocked abilities', :cannot, :configure_gates, Route
        specify { put :update, id: @route_gate, route_id: @route.id, app_id: @app.id }
      end

      context '#destroy' do
        include_context 'mocked abilities', :cannot, :configure_gates, Route
        specify { delete :destroy, id: @route_gate, route_id: @route.id, app_id: @app.id }
      end
    end
  end

  it "#update" do
    put :update, {:id => @route_gate.id,
                  :route_gate => {:position => 2},
                  :app_id => @app.id,
                  :route_id => @route.id}
    @route_gate.reload
    @route_gate.position.should eql(2)
    response.should render_template(:partial => 'routes/_for_reorder')
  end

  it "#destroy" do
    expect{delete :destroy, {:id => @route_gate.id,
                             :app_id => @app.id,
                             :route_id => @route.id}
          }.to change(RouteGate, :count).by(-1)
    response.should redirect_to app_route_path(@app, @route)
  end
end