class ScriptedResourcesController < ApplicationController
  include AlphabeticalPaginator
  include ControllerSharedScript

  def edit
    authorize! :edit, :automation
    begin
    @script = find_script
    rescue ActiveRecord::RecordNotFound
      flash[:error] = "script you are trying to access either does not exist or has been deleted"
      redirect_to(automation_scripts_path) and return
    end
    # @script.update_bladelogic_arguments if bladelogic?
    @store_url = true
    render_edit
  end

  def update
    authorize! :edit, :automation
    @script = find_script
    if @script.update_attributes(params[:script])
      if request.xhr? && params[:do_not_render].blank?
        render :template => "shared_scripts/update"
      else
        redirect_to(index_path)
      end
    else
      #@scripts = paginate_records(Script.all, params, 10)
      request.xhr? ? show_validation_errors(:script, {:div => "script_error_messages"}) : render_edit
    end
  end


  def create
    authorize! :create, :automation
    @script = Script.new(params[:script])

    if @script.save
      request.xhr? ? ajax_redirect(automation_scripts_path) : redirect_to(automation_scripts_path)
    else
      @scripts = paginate_records(Script.sorted, params, params[:per_page] || 10)
      request.xhr? ? show_validation_errors(:script, {:div => "#{@script.class.to_s.underscore}_error_messages"}) : render_new
    end
  end


  private

  def index_path
    scripted_resources_path(:page => params[:page], :key => params[:key])
  end

  def find_script
      Script.find params[:id]
  end

  def render_new
    if params.include?("stand_alone")
      render :template => 'scripted_resources/new', :layout => false
    else
      if request.xhr?
        render :template => 'scripted_resources/detail_new', :layout => false
      else
        render :template => 'scripted_resources/detail_new'
      end
    end
  end

  def render_edit
    if request.xhr?
      render :template => 'scripted_resources/edit', :layout => false
    else
      render :template => 'scripted_resources/detail_edit'
    end
  end

end
