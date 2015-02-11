################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class ActivityCategoriesController < ApplicationController
  before_filter :authenticate_user!, :except => [:list]
  before_filter :activity_categories_detail, :only => [:show, :list]

  def filter_index_columns
    @activity_category = find_activity_category
    @groups = Group.name_order
    logger.debug "BJB params to filter by: #{params.inspect}"
    @visible_activity_ids = @activity_category.activities.name_order.filter_by(params[:filters] || {}, current_user.admin? ? true :false).map(&:id)

    group_ids = []
    @groups.each do |group|
      group_ids << group.id
    end
    @group_ids = group_ids.uniq
  end

  def edit_index_columns
    @activity_category = find_activity_category
    authorize! :modify, @activity_category
    render :layout => false
  end

  def create_index_columns
    @activity_category = find_activity_category
    authorize! :modify, @activity_category
    ActivityIndexColumn.create(params[:column])
    render :layout => false
  end

  def update_index_columns
    activity_category = find_activity_category
    authorize! :modify, activity_category
    col = activity_category.index_columns.find(params[:column_id])
    col.update_attributes(params[:column])
    render :nothing => true
  end

  def destroy_index_columns
    if params[:column_destroy_ids].present?
      column_ids = params[:column_destroy_ids]
      activity_category = find_activity_category
      authorize! :modify, activity_category
      cols = activity_category.index_columns.find(:all, :conditions => "id IN (#{column_ids})")
      cols.each do |col|
        col.destroy
      end
    end
    redirect_to activity_category_path(params[:id])
  end

protected

  def find_activity_category
    ActivityCategory.find params[:id]
  end

  def activity_categories_detail
    session[:category_id] = params[:id]
    @search = false
    redirect_to request_projects_path
  end
end

