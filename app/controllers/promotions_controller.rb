################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class PromotionsController < ApplicationController
  
  def new
    @request_templates = RequestTemplate.unarchived.by_app_id(params[:app_id])
    @selected_values = params
    render :layout => false     
  end
  
  def promotion_table
    @promotion = Promotion.new(params[:promotion])
    if @promotion.valid?
      @app =  @promotion.app
    else
      show_validation_errors(:promotion)
    end
  end
  
end
