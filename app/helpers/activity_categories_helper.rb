################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

module ActivityCategoriesHelper
  def column_count
    # 4 hard-coded columns: Leading Group, ID, Budget Projected, filter submit button
    @activity_category.index_columns.length + 4
  end

  def render_activities_by_group group
    if current_user.present? && current_user.admin?
      render 'activity_categories/activities',
             :activities => Activity.fetch_by_group(@activity_category.id, group.id, true, @activity_ids),
             :columns => @activity_category.index_columns
    else
      render 'activity_categories/activities',
             :activities => Activity.fetch_by_group(@activity_category.id, group.id, false, @activity_ids),
             :columns => @activity_category.index_columns
    end
  end

  def render_activities_partial group
    # BJB I don't think this code gets used 3/28/10
    # added error line to see...
    if current_user.present? && current_user.admin?
      render 'activity_categories/activities',
             :activities => @activity_category.
                              activities.
                              name_order.throw_error.
                              with_projected_cost.
                              in_group(group).
                              filter_by(params[:filters] || {}),
             :columns => @activity_category.index_columns
    else
      render 'activity_categories/activities',
           :activities => @activity_category.
                            activities.
                            active_activities.
                            name_order.
                            with_projected_cost.
                            in_group(group),
           :columns => @activity_category.index_columns
    end
  end

  def count_group(activity_category_id, group_id)
    group = Activity.fetch_by_group(activity_category_id, group_id, current_user.admin? ? true : false, @activity_ids)
    return group.size
  end

end

