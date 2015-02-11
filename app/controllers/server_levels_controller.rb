################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class ServerLevelsController < ApplicationController
  include AlphabeticalPaginator

  before_filter :find_server_level, :except => [:new, :create, :destroy]

  def new
    @server_level = ServerLevel.new
    authorize! :create, @server_level
    render :partial => 'form'
  end

  def create
    @server_level = ServerLevel.new(params[:server_level])
    authorize! :create, @server_level

    if @server_level.save
      flash.now[:success] = I18n.t('activerecord.notices.created', model: @server_level.name)
    else
      flash.now[:error] = I18n.t('activerecord.notices.not_created', model: I18n.t('activerecord.models.server_level'))
    end

  end

  def show
    authorize! :inspect, @server_level
    if @server_level.server_aspects.empty?
      @server_aspect = @server_level.server_aspects.build
      grouped_parents = @server_level.grouped_potential_parents
      if !grouped_parents.empty?
        @server_aspect.parent = grouped_parents.first.last.first
      end
    end

    @per_page = 30
    @keyword = params[:key]
    @server_level_server_aspect = @server_level.server_aspects.order('server_aspects.name asc')
    @server_level_server_aspect = @server_level_server_aspect.search_by_ci("name", @keyword) if @keyword.present?
    @server_level_server_aspect.uniq!
    @total_records = @server_level_server_aspect.length
    if @server_level_server_aspect.blank?
      flash.now[:error] = "No  Instances  Found for #{@server_level.name}  "
    end
    @server_level_server_aspect = alphabetical_paginator  @per_page, @server_level_server_aspect
    if params[:render_no_rjs].present?
      render :partial => "server_level_show", :layout => false
    else
      respond_to do |format|
        format.html
        format.js
      end
    end
  end

  def edit
    authorize! :edit, @server_level
  end

  def update
    authorize! :edit, @server_level
    @server_level.update_attributes(params[:server_level])
  end

  def search #ToDo - Use ControllerSearch module instead of using this search action method
    unless params[:key].blank?
      condition = params[:key]
      @server_level_server_aspect = @server_level.server_aspects.server_level_id_equals(params[:id]).name_begins_with(ServerAspect.pagination_search_server_levels_letter(params[:id],params[:key]))
      render :action => "show"
    else
      redirect_to server_level_path(params[:id])
    end
  end

  protected

  def find_server_level
    @server_level = ServerLevel.find(params[:id])
  end

end

