# This file is the property of StreamStep, Inc.
# The contents of this file are covered by Copyright by StreamStep, Inc.
# Any unauthorized and unlicensed use is strictly prohibited.
# The software source code can be used only with a valid software license from StreamStep, Inc.
# In NO WAY is this software open source, free, or in the public domain.

class VersionTagsController < ApplicationController
  include ControllerSharedScript
  include ArchivableController
  include ControllerSearch
  include PropertyUpdater

  before_filter :find_version_tag, :except => [:index, :create, :new, :installed_component_remote_options, :app_env_remote_options,
                                               :bulk_create, :app_component_remote_options, :app_env_pick_list]


  def index
    authorize! :list, VersionTag.new

    @keyword = params[:key]
    @for = params[:for] if params[:page] && params[:for]
    @page=params[:page] || 1
    @per_page=params[:per_page] || 20
    # Paginate
    @version_tags = VersionTag.unarchived.name_order.paginate(:page => @page, :per_page => @per_page)
    @archived_version_tags = VersionTag.archived.name_order.paginate(:page => @page, :per_page => @per_page)
    # Keyword filtering
    if @keyword.present?
      @version_tags = @version_tags.where("version_tags.name like '%#{@keyword}%'")
      @archived_version_tags = @archived_version_tags.where("version_tags.name like '%#{@keyword}%'")
    end
    # Order
    @order = params[:order]
    @order.each do |k, v|
      @version_tags = @version_tags.sorted_by(v[0].to_sym, "#{v[1]}")
      @archived_version_tags = @archived_version_tags.sorted_by(v[0].to_sym, "#{v[1]}")
    end if @order
    if request.xhr?
      render :partial => "ajax_search_section", :layout => false, :content_type => 'text/html'
    end
  end

  def details
    authorize! :list, VersionTag.new

    @keyword = params[:key]
    @page=params[:page] || 1
    @per_page=params[:per_page] || 20
    # Filter
    if params[:position] == 'unarchived'
      @version_tags = VersionTag.unarchived
    else
      @version_tags = VersionTag.archived
    end
    # Paginate
    @version_tags = @version_tags.paginate(:page => @page, :per_page => @per_page)
    # Keyword filtering
    if @keyword.present?
      @version_tags = @version_tags.where("version_tags.name like '%#{@keyword}%'")
    end
    # Order
    @order = params[:order]
    @order.each do |k, v|
      @version_tags = @version_tags.sorted_by(v[0].to_sym, "#{v[1]}")
    end if @order
    @version_tags.empty?
    render :partial => 'version_tags/details', :locals => {:@version_tag_list => @version_tags, :@position => params[:position]}
  end

  def new
    authorize! :create, VersionTag.new

    @version_tag = VersionTag.new
    @apps = App.active.order("LOWER(name) asc")
  end

  def edit
    authorize! :edit, @version_tag

    if @version_tag.nil?
      flash[:error] = I18n.t(:exists_not_or_deleted, model: I18n.t(:'activerecord.models.version_tag'))
      redirect_to(version_tags_path)
    end
  end

  def create
    @version_tag = VersionTag.new(params[:version_tag])
    @version_tag.app_id = params[:app_id]
    @version_tag.app_env_id = params[:installed_component_id] == '' ? params[:app_env_id] : nil
    @version_tag.installed_component_id = params[:installed_component_id]
    @version_tag.not_from_rest = true

    authorize! :create, @version_tag

    if @version_tag.save
      flash[:notice] = I18n.t(:'activerecord.notices.created', model: I18n.t(:'activerecord.models.version_tag'))
      redirect_to version_tags_path
    else
      render :action => 'new'
    end
  end

  def bulk_create
    authorize! :create, VersionTag.new

    if request.post?
      @errors = validate_bulk_create_parameters
      unless @errors.blank?
        @error_tags = @errors.collect { |e| "<li>#{e}</li>" }.join
      else
        created_versions = []
        updated_versions = []
        params['environment_ids'].each { |e_id|
          ic = InstalledComponent.find_by_app_comp_env(params['app_id'].to_i, params['component_id'].to_i, e_id.to_i) rescue nil
          if ic
            v = VersionTag.find_by_name_and_installed_component_id(params['name'], ic.id)
            if v
              if v.update_attributes(:not_from_rest => true, :artifact_url => params['artifact_url'])
                updated_versions << v
              end
            else
              v = VersionTag.new
              if v.update_attributes(:name => params[:name], :app_id => params['app_id'].to_i, :not_from_rest => true,
                                     :installed_component_id => ic.id, :artifact_url => params['artifact_url'])
                created_versions << v
              else
                if (created_versions.size == 0) && (updated_versions.size == 0) && (v.errors.size != 0)
                  @version_tag = v
                  (show_validation_errors :version_tag) && return
                end
              end
            end
          end
        }

        if (created_versions.size > 0) || (updated_versions.size > 0)
          message = 'Succesfully'
          message = message + " Created #{created_versions.size}" if created_versions.size > 0
          message = message + " Updated #{updated_versions.size}" if updated_versions.size > 0
          message = message + " version tags"
          flash[:success] = message
        else
          flash[:error] = "Could not create/update any versions"
        end

        request.xhr? ? ajax_redirect(version_tags_path) : redirect_to(version_tags_path) && return
      end
    else
      # Simply render the default form
    end
  end

  def validate_bulk_create_parameters
    errors = []
    errors.push(I18n.t('version_tag.validations.empty_name')) if params['name'].blank?
    errors.push(I18n.t('version_tag.validations.empty_application')) if params['app_id'].blank?
    errors.push(I18n.t('version_tag.validations.empty_component')) if params['component_id'].blank?
    unless params['app_id'].blank?
      errors.push(I18n.t('version_tag.validations.empty_environments')) if params['environment_ids'].blank?
    end
    errors
  end

  def update
    authorize! :edit, @version_tag

    @version_tag.app_id = params[:app_id]
    @version_tag.app_env_id = params[:installed_component_id] == '' ? params[:app_env_id] : nil
    @version_tag.installed_component_id = params[:installed_component_id]
    @version_tag.not_from_rest = true
    if @version_tag.update_attributes(params[:version_tag])
      flash[:notice] = I18n.t(:'activerecord.notices.updated', model: I18n.t(:'activerecord.models.version_tag'))
      redirect_to version_tags_path
    else
      render :action => 'edit'
    end
  end

  def destroy
    authorize! :delete, @version_tag

    if @version_tag.destroy
      flash[:notice] = I18n.t(:'activerecord.notices.deleted', model: I18n.t(:'activerecord.models.version_tag'))
    end

    redirect_to version_tags_path
  end

  def artifact_url
    if request.xhr?
      render :text => @version_tag.artifact_url
    end
  end

  def app_component_remote_options
    if params[:app_id].blank?
      render :text => ""
    else
      app = App.find_by_id(params[:app_id])
      render :text => options_from_model_association(app, :components, :selected => 0)
    end
  end

  def app_env_pick_list
    if params[:app_id].blank?
      render :text => "Please select an Application"
    else
      app = App.find(params[:app_id])
      if params[:component_id].blank?
        @environments = app.environments
      else
        @environments = app.environments.select { |e|
          ic = InstalledComponent.find_by_app_comp_env(params['app_id'].to_i, params['component_id'].to_i, e.id) rescue nil
          ic
        }
      end
      render :partial => "app_env_pick_list"
    end
  end

  def app_env_remote_options
    if params[:app_id].nil? || params[:app_id] == ''
      render :text => ''
    else
      app = App.find_by_id(params[:app_id])
      find_version_tag(true)

      if @version_tag.installed_component.nil?
        env_id = @version_tag.app_env_id.nil? ? 0 : @version_tag.app_env_id
      else
        env_id = @version_tag.installed_component.application_environment_id
      end

      render :text => options_from_model_association(app, :application_environments, :named_scope => [:in_order, :with_installed_components],
                                                     :selected => env_id)
    end
  end

  def installed_component_remote_options
    if params[:app_env_id].blank?
      render :text => ""
    else
      find_version_tag(true)
      comp_id = @version_tag.installed_component.nil? ? 0 : @version_tag.installed_component_id
      logger.info "SS__ VersionTag COmp: #{comp_id}"
      app_env = ApplicationEnvironment.find_by_id(params[:app_env_id])
      render :text => options_from_model_association(app_env, :installed_components, :selected => comp_id, :include_blank => true)
    end
  end


  ###
  ##Overriding the archive and unarchive methods from the ArchivableController module so that we can get a hook for the
  #model object which is used to set the 'not_from_rest' flag.Essentially there is no requirement for including the generic module
  # in this controller but keeping it for consistency.
  ###
  def archive
    authorize! :archive_unarchive, @version_tag

    @version_tag.not_from_rest=true
    success=@version_tag.archive
    flash[:error] = I18n.t(:'problem_archiving', model: I18n.t(:'activerecord.models.version_tag')) unless success
    respond_to do |wants|
      wants.html { redirect_to :action => :index, :page => params[:page], :key => params[:key] }
      wants.js { render :nothing => true }
    end
  end

  def unarchive
    authorize! :archive_unarchive, @version_tag

    @version_tag.not_from_rest = true
    success = @version_tag.unarchive

    flash[:error] = I18n.t(:'problem_unarchiving', model: I18n.t(:'activerecord.models.version_tag')) unless success
    respond_to do |wants|
      wants.html { redirect_to :action => :index, :page => params[:page], :key => params[:key] }
      wants.js { render :nothing => true }
    end

  end


  protected

  def find_version_tag(return_new = false)
    if params[:id].nil? && return_new
      @version_tag = VersionTag.new
    else
      begin
        @version_tag = VersionTag.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        unless request.xhr?
          flash[:error] = "The version tag you are looking for, does not exist"
          redirect_to version_tags_path
        end
      end
    end
  end

end
