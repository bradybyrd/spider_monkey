class PackageInstancesController < ApplicationController
  include PropertyUpdater
  include TableSorter

  helper_method :sort_direction, :sort_column

  before_filter :find_package

  def index
    authorize! :view_instances, @package
    package_instances = current_user.accessible_package_instances(package_id)
    @active_package_instances = sort(package_instances.active)
    @inactive_package_instances = sort(package_instances.inactive)
    @keyword = params[:key]
    if @keyword.present?
      @active_package_instances = @active_package_instances.search_by_ci("name", @keyword)
      @inactive_package_instances = @inactive_package_instances.search_by_ci("name", @keyword)
    end
    if @active_package_instances.blank? && @inactive_package_instances.blank?
      flash[:error] = t('package_instance.not_found')
    end

    @active_package_instances = @active_package_instances.paginate(page: page)
    @inactive_package_instances = @inactive_package_instances.paginate(page: inactive_page)
    @total_records = @active_package_instances.length
    render partial: "index", layout: false if request.xhr?
  end

  def new
    authorize! :create_instance, @package
    @package_instance = @package.package_instances.new
    @package_instance.name = @package_instance.format_name( @package.instance_name_format, @package.next_instance_number )
  end

  def edit
    begin
      @package_instance = find_package_instance
      authorize! :edit, @package_instance
    rescue ActiveRecord::RecordNotFound
      flash[:error] = "No Package Instance found"
      redirect_to :back
    end
  end

  def create
    authorize! :create_instance, @package
    @package_instance = @package.package_instances.build
    if PackageInstanceCreate.call( @package_instance, params[:package_instance] ) && @package_instance.errors.blank?
      flash[:notice] = 'Package instance was successfully created.'
      redirect_to edit_package_instance_path( :package_id => @package.id, :id => @package_instance.id )
    else
      @package_instance.errors
      flash[:error] = "Error creating package instance"
      render action: "new"
    end
  end

  def update
    begin
      @package_instance = find_package_instance
      authorize! :edit, @package_instance
    rescue ActiveRecord::RecordNotFound
      flash[:error] = "No Package Instance found"
      render action: "edit"
    end
    @package_instance.not_from_rest =  true

    if PackageInstanceUpdate.call( @package_instance,params[:package_instance] ) && @package_instance.errors.blank?
      flash[:notice] = I18n.t('package_instance.updated')
      if ( params[:auto_submit] == 'y' )
        render :action => "edit"
      else
        redirect_to package_instances_path(:page => params[:page], :key => params[:key], :package_id => @package.id )
      end
    else
      flash[:error] = "Error updating package instance"
      render action: "edit"
    end
  end

  def add_references
    @package_instance = find_package_instance
    render :partial => 'package_instances/add_references', :locals => {:package_instance => @package_instance, :page => params[:page], :key => params[:key]}
  end


  def activate
    @package_instance = find_package_instance
    authorize! :make_active_inactive, @package_instance
    @package = find_package

    @package_instance.activate!

    redirect_to package_instances_path(:page => params[:page], :key => params[:key], :package_id => @package.id )
  end

  def deactivate
    @package_instance = find_package_instance
    authorize! :make_active_inactive, @package_instance
    @package = find_package

    @package_instance.deactivate!

    redirect_to package_instances_path(:page => params[:page], :key => params[:key], :package_id => @package.id )
  end


  def destroy
    @package_instance = find_package_instance
    authorize! :delete, @package_instance
    @package = find_package

    @package_instance.destroy

    redirect_to package_instances_path(:page => params[:page], :key => params[:key], :package_id => @package.id )
  end

  private

  def sort_column_is_safe?
    PackageInstance.column_names.include?(params[:sort])
  end

  def sort_column_prefix
    if OracleAdapter
      "#{PackageInstance.table_name}."
    else
      ""
    end
  end

  def inactive_page
    params[:inactive_page]
  end

  def page
    if params[:page].present?
      params[:page]
    else
      1
    end
  end

  def find_package_instance
    @package_instance ||= PackageInstance.find params[:id]
  end

  def find_package
    @package ||= Package.where(id: params[:package_id]).first || find_package_instance.package
  end

  def package_id
    params[:package_id]
  end

end
