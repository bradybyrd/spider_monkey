################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

class DashboardController < ApplicationController

  before_filter :dashboard_setup, :only => [:promotions]
  skip_before_filter :verify_authenticity_token, :only => [:self_services]

  def self_services
    #authorize! :view, :dashboard_tab
    redirect_to activities_path
  end

  def recent_activities
    get_recent_activities
    @page_no = params[:page] || 1
    if params[:pagination].present?
      if @recent_activities.blank?
        render :text => "No recent activity found"
      else
        render :partial => "dashboard/self_services/recent_activity"
      end
    elsif @page_no == 1
      render :layout => false
    else
      render :partial => "dashboard/recent_activities_table"
    end
  end

  def index
    self_services
  end

  private

  def get_recent_activities
    @recent_activities = paginate_records(current_user.related_recent_activity.uniq, params, 3)
  end


end
