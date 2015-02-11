################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class ServerGroupsController < ApplicationController
  before_filter :find_server_group, only: [:edit, :update, :destroy, :activate, :deactivate]
  before_filter :collect_servers_and_environments, :only => [:new, :edit]

  def index
    authorize! :list, ServerGroup.new
    @keyword = params[:key]
    params[:page] = 1 if params[:page].blank?
    if @keyword.present?
      @active_server_groups = ServerGroup.active.includes([:servers, :environments]).search_by_ci("name", @keyword).page(params[:page])
      @inactive_server_groups = ServerGroup.inactive.includes([:servers, :environments]).search_by_ci("name", @keyword)
    else
      @active_server_groups = ServerGroup.active.includes([:servers, :environments]).page(params[:page])
      @inactive_server_groups = ServerGroup.inactive.includes([:servers, :environments])
    end
    if @active_server_groups.blank? and @inactive_server_groups.blank?
      flash.now[:error] = "No Server Group found."
    end
    if params[:render_no_rjs].present? && params[:paginated].nil?
      render :partial => "index", :layout => false
    end
  end

  def activate
    authorize! :make_active_inactive, @server_group
    @server_group.activate!
    ajax_redirect(server_groups_path(:page => params[:page],:key => params[:key]))
  end

  def deactivate
    authorize! :make_active_inactive, @server_group
    @server_group.deactivate!
    ajax_redirect(server_groups_path(:page => params[:page],:key => params[:key]))
  end


  def new
    @server_group = ServerGroup.new
    authorize! :create, @server_group
    render :template => 'server_groups/load_form' if request.xhr?
  end

  def create
    @server_group = ServerGroup.new(params[:server_group])
    authorize! :create, @server_group
    @server_group.save
    after_save_actions(:on_failure_render => 'new')
  end

  def edit
    authorize! :edit, @server_group
    render :template => 'server_groups/load_form' if request.xhr?
  end

  def update
    authorize! :edit, @server_group

    if !params[:server_group].key?(:server_ids)
      params[:server_group][:server_ids]=Array.new;
    end
    if !params[:server_group].key?(:environment_ids)
      params[:server_group][:environment_ids]=Array.new;
    end

    @server_group.update_attributes(params[:server_group])
    after_save_actions(:on_failure_render => 'edit')
  end

  def destroy
    authorize! :delete, @server_group
    if @server_group.destroyable? && @server_group.destroy
      flash[:success] = I18n.t('activerecord.notices.deleted', model: I18n.t('activerecord.models.server_group'))
    else
      flash[:error] = I18n.t('activerecord.notices.not_deleted', model: I18n.t('activerecord.models.server_group'))
    end

    redirect_to servers_path
  end

private

  def find_server_group
    @server_group = ServerGroup.find(params[:id])
  end

  def collect_servers_and_environments
    @servers = Server.active.order("LOWER(name) asc")
    @environments = Environment.active.order("LOWER(name) asc")
    @server_levels = ServerLevel.in_order
  end

  def after_save_actions(options)
    action = params[:action]
    if @server_group.valid?
      if request.xhr?
        index
        respond_to do |format|
          format.js { render :template => 'server_groups/index', :handlers => [:erb], :content_type => 'application/javascript'}
        end
      else
        flash[:success] = "Server group successfully #{action}d."
        redirect_to servers_path(:page => params[:page],:key => params[:key])
      end
    else
      if request.xhr?
        show_validation_errors(:server_group)
      else
      flash.now[:error] = "There was a problem #{action.sub(/\w$/, '')}ing the server group."
      collect_servers_and_environments
      render :action => options[:on_failure_render]
      end
    end
  end

end
