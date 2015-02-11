################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class IntegrationCsvsController < ApplicationController
  
  before_filter :find_plan

  def create
    @integration_csv = IntegrationCsv.new(params[:integration_csv])
    @integration_csv.csv = params[:csv]
    @integration_csv.user_id = current_user.id
    @integration_csv.tab_id = set_plan_tab_id
    responds_to_parent do 
      if @integration_csv.valid?
        @integration_csv.parse!
        @integration_csv.save_csv_data!
        if @integration_csv.saved!
          eval("
          ajax_redirect(#{Plan::TABS[@integration_csv.tab_id]}_plan_path(
            @integration_csv.plan_id, :instance_template_type => Plan::TABS[@integration_csv.tab_id])
          )")
        else
          render :update do |page|
            page << "$('#csv_errors').html('')"
            page << "$('#integration_csv_can_be_saved').val('1')"
            page.replace_html "csv_headers", :partial => "integration_csvs/csv_headers"
          end
        end
      else
        show_validation_errors(:integration_csv, {:div => "csv_errors"})
      end
    end
  end
    
end
