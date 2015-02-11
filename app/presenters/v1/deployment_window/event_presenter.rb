################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################
class V1::DeploymentWindow::EventPresenter < V1::AbstractPresenter

  # creates a local accessor based on the passed symbol
  presents :event

  private

  def resource_options
    {
      :only => safe_attributes,
      :include => {
        :environment => {:only => [:id, :name]},
        :occurrence => {:only => [:id, :position, :start_at, :finish_at]},
        :series => {:only => [:id, :name, :behavior]}
      }
    }
  end

  def safe_attributes
    [:id, :state, :start_at, :finish_at, :created_at, :updated_at, :reason]
  end

end
