class DeploymentWindow::EventsController < ApplicationController
  before_filter :fetch_deployment_window_event, only: [:popup, :suspend, :move, :edit_series]
  before_filter :modify_params, only: :move

  def popup
    if params[:popup_type] == 'request'
      authorize! :create, Request.new
      prepare_popup_for_request
    end
    @deployment_window_event.reason = nil if @deployment_window_event.is_a? DeploymentWindow::Event
    render params[:popup_type], layout: false
  end

  def suspend
    authorize! :suspend_resume, @deployment_window_event.series

    if @deployment_window_event.update_attributes params[:deployment_window_event]
      render 'refresh_location'
    else
     render 'errors_notification'
    end
  end

  def move
    authorize! :move, @deployment_window_event.series

    if @deployment_window_event.update_attributes @modified_params[:deployment_window_event]
      render 'refresh_location'
    else
      render 'errors_notification'
    end
  end

  def edit_series
    series = @deployment_window_event.series
    authorize! :edit, series
    render json: {url: edit_deployment_window_series_path(series)}
  end

  private

    def fetch_deployment_window_event
      @deployment_window_event = if params[:popup_type] == 'edit_series'
        DeploymentWindow::Series.find params[:id]
      else
       DeploymentWindow::Event.find params[:id]
     end
    rescue ActiveRecord::RecordNotFound
      flash[:error] = 'Deployment Window Series not found.'
      redirect_to :back
    end

    def modify_params
      @modified_params = params.dup.deep_symbolize_keys
      @modified_params = MappedParams::Multiparameters.(@modified_params, DeploymentWindow::Event)
    end

    def prepare_popup_for_request
      @request = Request.new({
        deployment_window_event_id: @deployment_window_event.id,
        scheduled_at: @deployment_window_event.start_at
      })
      request_plan_data = RequestPlanData.new(@request, params, current_user)
      if @deployment_window_event.series.warning_state?
        flash[:warning] = @deployment_window_event.series.warning_state
      end
      @plan_member = request_plan_data.plan_member
      @available_plans_for_select = request_plan_data.available_plans_for_select
      @available_plan_stages_for_select = request_plan_data.available_plan_stages_for_select
      @stages_requestor_can_not_select = request_plan_data.stages_requestor_can_not_select
    end
end
