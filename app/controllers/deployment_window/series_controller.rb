class DeploymentWindow::SeriesController < ApplicationController
  before_filter :fetch_deployment_window_series, only: [:edit, :update, :destroy]
  before_filter :prepare_for_search, only: [:index]
  before_filter :prepeare_virtual_attributes, only: :edit

  include ArchivableController
  include MultiplePicker
  include ObjectStateController

  def index
    authorize! :view, :environment_tab
    authorize! :list, DeploymentWindow::Series.new

    @deployment_window_series = DeploymentWindow::Series.fetch_depends_on_user(current_user)
                                                        .visible_in_index
                                                        .filter(@modified_params[:filters])
                                                        .search(@modified_params[:q])

    respond_to do |format|
      format.html {
        if request.xhr?
          if @deployment_window_series.present?
            params[:scope].present? ? render(partial: 'list', locals: {scope: params[:scope].to_sym}) : render(partial: 'lists')
          else
            render partial: 'shared/blank_data_message', locals: { message: 'There are no deployment windows series at this time.'}
          end
        end
      }
      format.json { render json: @deployment_window_series }
    end
  end

  def new
    @deployment_window_series = DeploymentWindow::Series.new(behavior: params[:behavior])
    authorize! :create, @deployment_window_series

    respond_to do |format|
      format.html
      format.json { render json: @deployment_window_series }
    end
  end


  def create
    prepared_params = DeploymentWindow::SeriesConstructHelper.prepare_params(params)
    prepared_params[:deployment_window_series][:check_permissions] = true
    deployment_window_series_construct = DeploymentWindow::SeriesConstruct.new(prepared_params)
    @deployment_window_series = deployment_window_series_construct.series
    # No authorize!(:create, @deployment_window_series) here, because authorization during create takes place inside validation
    respond_to do |format|
      if deployment_window_series_construct.create
        notice = I18n.t 'deployment_window.series_created'
        notice = notice.concat I18n.t('deployment_window.occurrence_will_be_generated') if @deployment_window_series.recurrent?

        format.html { redirect_to deployment_window_series_index_path, notice: notice }
        format.json { render json: @deployment_window_series, status: :created, location: @deployment_window_series }
      else
        format.html { render action: 'new' }
        format.json { render json: @deployment_window_series.errors, status: :unprocessable_entity }
      end
    end
  end

  def edit
    authorize! :edit, @deployment_window_series
  end

  def update
    prepared_params = DeploymentWindow::SeriesConstructHelper.prepare_params(params)
    prepared_params[:deployment_window_series][:check_permissions] = true
    deployment_window_series_construct = DeploymentWindow::SeriesConstruct.new(prepared_params, @deployment_window_series)
    @deployment_window_series = deployment_window_series_construct.series
    # No authorize!(:edit, @deployment_window_series) here, because authorization during update takes place inside validation
    respond_to do |format|
      if deployment_window_series_construct.update
        redirect_link = params[:return_to] ? deployment_windows_calendar_reports_path : deployment_window_series_index_path
        notice = I18n.t 'deployment_window.series_updated'
        notice = notice.concat I18n.t('deployment_window.occurrence_will_be_generated') if @deployment_window_series.recurrent?

        format.html { redirect_to redirect_link, notice: notice }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @deployment_window_series.errors, status: :unprocessable_entity }
      end
    end
  end

  def show ; end

  def destroy
    authorize! :delete, @deployment_window_series
    if @deployment_window_series.check_if_destroyable
      @deployment_window_series.quick_delete
    end

    respond_to do |format|
      format.html { redirect_to deployment_window_series_index_path, notice: t('activerecord.notices.deleted', model: 'Deployment window') }
      format.json { head :no_content }
    end
  end

  private

  def prepare_for_search
    if params[:clear_filters].present?
      params.delete :clear_filters
      params[:filters] = {}
      params[:page] = 1
    end

    @modified_params = [MappedParams::Filter, MappedParams::Search].inject(params.dup.deep_symbolize_keys) do |params, mod|
      mod.(session_scope, params, DeploymentWindow::Series.scoped)
    end
    @filter_params = session_scope[:collection_manipulations]

    prepare_scoped_params
  end

  def prepare_scoped_params
    @scope_params = {}
    scopes = params[:scope].present? ? [params[:scope].to_sym] : [:archived, :unarchived]

    scopes.each do |scope|
      @scope_params[scope] = [MappedParams::Order, MappedParams::Page].inject(@modified_params.dup) do |params, mod|
        mod.(session_scope(scope), params, DeploymentWindow::Series.scoped)
      end
      @filter_params[scope] = session_scope(scope)[:collection_manipulations]
    end
  end

  def prepeare_virtual_attributes
    @deployment_window_series.frequency = @deployment_window_series.schedule_rule
    @deployment_window_series.environment_ids = @deployment_window_series.environments.map(&:id)
  end

  def fetch_deployment_window_series
    @deployment_window_series = DeploymentWindow::Series.find params[:id]
  rescue ActiveRecord::RecordNotFound
    flash[:error] = 'Deployment Window Series not found.'
    redirect_to :back
  end

  def session_scope_name(scope)
    session_filter_var + (scope.nil? ? '' : "_#{scope}")
  end

  def session_scope(scope = nil)
    scope_name = session_scope_name(scope)
    session[scope_name] = {} unless session[scope_name].present?
    session[scope_name]
  end

  def find_deployment_window_series
    begin
      @deployment_window_series = DeploymentWindow::Series.find params[:id]
    rescue ActiveRecord::RecordNotFound
      flash[:error] = "Deployment window series you are trying to access either does not exist or has been deleted"
      redirect_to(deployment_window_series_path) && return
    end
  end
end
