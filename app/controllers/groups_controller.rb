################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

class GroupsController < ApplicationController
  include ControllerSoftDelete
  include AlphabeticalPaginator
  include MultiplePicker

  before_filter :parse_role_ids, only: [:update, :create]
  after_filter :set_default_group_for_user, only: [:update]

  cache_sweeper :user_root_sweeper, only: [:update, :destroy, :create]

  def index
    @per_page = 30
    @keyword = params[:key]
    groups = Group.search(@keyword)
    @active_groups = groups.active
    @inactive_groups = groups.inactive
    @total_records = @active_groups.length
    if @active_groups.blank? and @inactive_groups.blank?
      flash.now[:error] = I18n.t(:'activerecord.notices.not_found', model: I18n.t('activerecord.models.group'))
    end
    @active_groups = alphabetical_paginator @per_page, @active_groups
    render :partial => 'index', :layout => false if request.xhr?
  end

  def new
    @group = Group.new
    authorize! :create, @group
    @unmanaged_users = User.unmanaged.index_order
  end

  def create
    @group = Group.new(group_params)
    authorize! :create, @group
    if @group.save
      flash[:success] = 'Resource Group was successfully created.'
      redirect_to groups_path(:page => params[:page], :key => params[:key])
    else
      @unmanaged_users = User.unmanaged.index_order
      render :action => 'new'
    end
  end

  def edit
    @group = find_group
    authorize! :edit, @group
    collect_unmanaged_resources
  end

  def update
    @group = find_group
    authorize! :edit, @group
    @before_update_group_user_ids = @group.user_ids

    if @group.update_attributes(group_params)
      #PermissionMap.instance.bulk_clean(@group.users)
      flash[:success] = 'Resource Group was successfully updated.'
      redirect_to groups_path(:page => params[:page], :key => params[:key])
    else
      collect_unmanaged_resources
      render :edit
    end
  end

  def set_default
    @group = find_group
    authorize! :make_default, @group

    @group.make_default!
    flash[:success] = 'Resource Group was successfully updated.'
    redirect_to groups_path(:page => params[:page], :key => params[:key])
  end

  def deactivate
    @group = find_group
    authorize! :make_active_inactive, @group

    flash[:error] = t('group.deactivate_error') unless @group.deactivate!
    redirect_to groups_path(page: params[:page], key: params[:key])
  end

  protected

  def find_group
    Group.find(params[:id])
  end

  def collect_unmanaged_resources
    @unmanaged_users = (@group.resources + User.unmanaged.index_order).sort_by { |u| u.name_for_index }
  end

  private

  def parse_role_ids
    group_params[:role_ids] = role_ids.gsub(/\[|\]/, '').split(',').map(&:to_i)
  end

  def role_ids
    group_params[:role_ids].to_s
  end

  def group_params
    params[:group] || {}
  end

  def set_default_group_for_user
    user_ids_diff = @before_update_group_user_ids - @group.user_ids
    default_group = Group.default_group
    if user_ids_diff.any? && default_group
      User.find(user_ids_diff).each do |user|
        user.groups << default_group if user.groups.empty?
      end
    end
  end
end
