################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2015
# All Rights Reserved.
################################################################################

class Reports::CalendarsController < ApplicationController
  
  before_filter :find_calendar_report, only: [:edit, :update, :destroy]
  
  def index
    @calendar_reports = CalendarReport.all(order: 'team_name ASC')
  end
  
  def new
    @calendar_report = CalendarReport.new
    render layout: false
  end
  
  def create
    @calendar_report = CalendarReport.new(params[:calendar_report])
    @calendar_report.user_id = current_user.id
    if @calendar_report.save
      ajax_redirect(reports_calendars_path)
    else
      show_validation_errors(:calendar_report)
    end
  end
  
  def edit
    render layout: false
  end
  
  def update
    if @calendar_report.update_attributes(params[:calendar_report])
      ajax_redirect(reports_calendars_path)
    else
      show_validation_errors(:calendar_report)
    end
  end
  
  def destroy
    @calendar_report.destroy
    ajax_redirect(reports_calendars_path)
  end
  
  protected
  
  def find_calendar_report
    @calendar_report = CalendarReport.find(params[:id])
  end
  
end
