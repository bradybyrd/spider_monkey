################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

class V1::ScheduledJobsPresenter < V1::AbstractPresenter

  # creates a local accessor based on the passed symbol
  presents :scheduled_jobs

  private

  def resource_options
    return { only: safe_attributes, include: {
        owner: { only: [:id, :login, :email, :first_name, :last_name] },
        resource: { only: [:id, :name ] }
      }
    }
  end

  def safe_attributes
    return [:id, :status, :planned_at, :log, :created_at, :updated_at]
  end

end
