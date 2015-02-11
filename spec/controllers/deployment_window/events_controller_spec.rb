require 'spec_helper'

describe DeploymentWindow::EventsController do
  let(:environments) { create_list(:environment, 5) }
  let(:env_ids) { environments.map(&:id) }
  let(:series) { create(:recurrent_deployment_window_series) }
  let(:occurrence) { create(:deployment_window_occurrence, environment_ids: env_ids, series_id: series.id) }
  let(:event) { occurrence.events.first }
  let(:request) { Request.new( deployment_window_event_id: event.id) }

  let(:start_date) { Time.zone.now + 1.days + 2.minute }
  let(:finish_date) { Time.zone.now + 3.days - 3.hours - 20.minute }

  def request_params
    {
      "popup_type"=>"request",
      "action"=>"popup",
      "controller"=>"deployment_window/events",
      "id"=>"#{event.id}"
    }
  end

  def multiparameters
    {
      "state"=>"moved",
      "start_at"=>start_date.to_date.strftime(GlobalSettings['default_date_format'].split(' ')[0]),
      "start_at(4i)"=>start_date.hour.to_s,
      "start_at(5i)"=>start_date.min.to_s,
      "finish_at"=>finish_date.to_date.strftime(GlobalSettings['default_date_format'].split(' ')[0]),
      "finish_at(4i)"=>finish_date.hour.to_s,
      "finish_at(5i)"=>finish_date.min.to_s,
      "reason"=>"Some Reason for Moving"
    }
  end

  def expect_assigns_request_plan_data
    [:available_plans_for_select, :available_plan_stages_for_select, :stages_requestor_can_not_select].each do |var|
      expect(assigns(var)).to eq @request_plan_data.send(var)
    end
  end

  before do
    Group.stub(:first).and_return(build(:group))
    ApplicationController.any_instance.stub(:first_time_login_or_password_reset)
  end

  before :each do
    @user = create(:user)
    sign_in @user
    @request_plan_data = RequestPlanData.new(request, request_params, @user)
  end

  describe "GET 'popup'"  do
    it "assigns right data to variables and renders suspend template" do
      xhr :get, :popup, { id: event.to_param, popup_type: 'suspend', format: 'js' }
      expect(assigns(:deployment_window_event)).to eq event
      expect(assigns(:deployment_window_event).reason).to be_nil
      expect(response).to render_template('suspend')
    end

    it "assigns right data to variables and renders move template" do
      xhr :get, :popup, { id: event.to_param, popup_type: 'move', format: 'js' }
      expect(assigns(:deployment_window_event)).to eq event
      expect(response).to render_template('move')
    end

    it "assigns right data to variables and renders request template" do
      xhr :get, :popup, { id: event.to_param, popup_type: 'request' }

      expect(assigns(:request)).to be_a_new(Request)
      expect(assigns(:request).deployment_window_event_id).to eq event.id
      expect(assigns(:plan_member)).to be_a_new(PlanMember)
      expect_assigns_request_plan_data
      expect(assigns(:deployment_window_event)).to eq event
      expect(response).to render_template('request')
    end

    it "includes warning for Events in PENDING state" do
      series.update_attributes(aasm_state: 'pending')
      xhr :get, :popup, id: event.to_param, popup_type: 'request'
      expect(flash[:warning]).to include("PENDING state")
    end

    it "includes warning for Events in RETIRED state" do
      series.update_attributes(aasm_state: 'retired')
      xhr :get, :popup, id: event.to_param, popup_type: 'request'
      expect(flash[:warning]).to include("RETIRED state")
    end

    it "includes no warning for Events in RELEASED state" do
      xhr :get, :popup, id: event.to_param, popup_type: 'request'
      expect(flash[:warning]).to be_nil
    end


    it_behaves_like 'authorizable', controller_action: :popup,
                                    ability_action: :create,
                                    subject: Request do
                                      let(:params) { { id: event.to_param, popup_type: 'request' } }
                                    end
  end

  describe "GET 'edit_series'" do
    it 'returns json with sesies path' do
      get :edit_series, {  id: event.to_param, format: 'json'}
      parsed_body = JSON.parse(response.body)
      parsed_body.should ==  {"url"=>"/environment/metadata/deployment_window/series/#{series.id}/edit"}
    end
  end

  describe "PUT 'move'" do
    it "calls update_attributes render 'errors_notification' if invalid params" do
      DeploymentWindow::Event.any_instance.should_receive(:update_attributes)#.with(multiparameters)
      put 'move', { id: event.to_param, deployment_window_event: {}, format: 'js' }
      expect(event.state).to eq DeploymentWindow::Event::CREATED
      expect(event.reason).to be_nil
      expect(response).to render_template('errors_notification')
    end

    it "calls update_attributes and render 'refresh_location' if valid params" do
      put 'move', { id: event.to_param, deployment_window_event: multiparameters, format: 'js' }
      event.reload
      expect((event.start_at..event.start_at+1.minute).cover?(start_date)).to be_truthy
      expect((event.finish_at..event.finish_at+1.minute).cover?(finish_date)).to be_truthy
      expect(event.reason).to eq 'Some Reason for Moving'
      expect(event.state).to eq DeploymentWindow::Event::MOVED
      expect(response).to render_template('refresh_location')
    end
  end

  describe "PUT 'suspend'" do
    it "calls update_attributes render 'errors_notification' if invalid params" do
      DeploymentWindow::Event.any_instance.should_receive(:update_attributes)#.with(multiparameters)
      put 'suspend', { id: event.to_param, deployment_window_event: {}, format: 'js' }
      expect(event.reason).to be_nil
      expect(response).to render_template('errors_notification')
    end

    it "calls update_attributes and render 'refresh_location' if valid params" do
      put 'suspend', { id: event.to_param, deployment_window_event: { state: 'suspended', reason: 'Suspend Reason' }, format: 'js' }
      event.reload
      expect(event.state).to eq DeploymentWindow::Event::SUSPENDED
      expect(event.reason).to eq 'Suspend Reason'
      expect(response).to render_template('refresh_location')
    end

    it 'updates state to "resumed" if previous was "suspended"' do
      put 'suspend', { id: event.to_param, deployment_window_event: { state: 'resumed', reason: 'Resume Reason' }, format: 'js' }
      event.reload
      expect(event.state).to eq DeploymentWindow::Event::RESUMED
    end
  end

end
