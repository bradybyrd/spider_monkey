class DeploymentWindow::OccurrencesController < ApplicationController
  before_filter :find_series
  respond_to :js

  def index
    authorize! :list, DeploymentWindow::Series.new

    set_default_start_at
    @modified_params = [MappedParams::Order, MappedParams::Filter]
      .inject(params.deep_symbolize_keys.dup) { |params, mod|
        mod.(session_scope, params, @series.occurrences.scoped)
      }
    @filter_params = session_scope[:collection_manipulations]

    authorize! :list, @series

    @occurrences = @series.occurrences.scoped.reorder(@modified_params[:order])
                                             .filter(@modified_params[:filters])
                                             .paginate(page: @modified_params[:page] || 1)

    respond_to do |format|
      format.html {
        if request.xhr?
          @occurrences.present? ? render(partial: 'list') :
            render(partial: 'shared/blank_data_message', locals: { message: 'There are no occurrences at this time.'})
        end
      }
      format.json { render json: @occurrences }
    end
  end

  def show
    @occurrence = DeploymentWindow::Occurrence.find(params[:id])
    authorize! :list, @series

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @occurrence }
    end
  end

  def new
    @occurrence = DeploymentWindow::Occurrence.new
    authorize! :create, @series

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @occurrence }
    end
  end

  def edit
    authorize! :edit, @series
    @occurrence = DeploymentWindow::Occurrence.find(params[:id])
  end

  def create
    authorize! :create, @series
    @occurrence = DeploymentWindow::Occurrence.new(params[:occurrence])

    respond_to do |format|
      if @occurrence.save
        format.html { redirect_to @occurrence, notice: 'Occurrence was successfully created.' }
        format.json { render json: @occurrence, status: :created, location: @occurrence }
      else
        format.html { render action: "new" }
        format.json { render json: @occurrence.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    authorize! :edit, @series
    @occurrence = DeploymentWindow::Occurrence.find(params[:id])

    respond_to do |format|
      if @occurrence.update_attributes(params[:occurrence])
        format.html { redirect_to @occurrence, notice: 'Occurrence was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @occurrence.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    authorize! :delete, @series
    @occurrence = DeploymentWindow::Occurrence.find(params[:id])
    @occurrence.destroy

    respond_to do |format|
      format.html { redirect_to occurrences_url }
      format.json { head :no_content }
    end
  end

  private

  def find_series
    @series = DeploymentWindow::Series.find params[:series_id]
  end

  def session_scope
    session_scope_name = session_filter_var + "_#{@series.id}"
    session[session_scope_name] = {} unless session[session_scope_name].present?
    session[session_scope_name]
  end

private

  def filter_saved?(field)
    session_scope.has_key?(:collection_manipulations) and
    session_scope[:collection_manipulations].has_key?(:filters) and
    session_scope[:collection_manipulations][:filters].has_key?(field)
  end

  def set_default_start_at
    if !filter_saved?(:start_at) and
       (!params.include?(:filters) or !params[:filters].include?(:start_at))
      params[:filters] ||= {}
      params[:filters][:start_at] ||= session_scope.fetch(:collection_manipulations, {})
                                                   .fetch(:filters, {})
                                                   .fetch(:start_at, {})
      params[:filters][:start_at] = params[:filters][:start_at].presence ||
                                    DateTime.now.strftime(GlobalSettings['default_date_format'].split(' ')[0])
    end
  end

end
