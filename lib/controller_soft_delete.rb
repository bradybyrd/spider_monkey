################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

module ControllerSoftDelete

  def activate
    authorize_and :activate!

    redirect_to :action => :index, :page => params[:page], :key => params[:key]
  end

  def deactivate
    authorize_and :deactivate!

    respond_to do |wants|
      wants.html { redirect_to :action => :index, :page => params[:page], :key => params[:key] }
      wants.js { render :nothing => true }
    end
  end

  private

  def get_model_name
    self.class.to_s.gsub(/Controller$/, '').singularize.underscore
  end

  def authorize_and(action)
    object = self.send("find_#{get_model_name}")

    authorize! :make_active_inactive, object
    object.public_send(action)
  end
end
