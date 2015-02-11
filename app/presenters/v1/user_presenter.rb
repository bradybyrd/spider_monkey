################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

class V1::UserPresenter < V1::AbstractPresenter

  presents :user

  private

  def resource_options
    {
        only: safe_attributes,
        include: {
            teams: {only: [:id, :name]},
            groups: {only: [:id, :name]}
        }
    }
  end

  def safe_attributes
    [:id, :login, :first_name, :last_name, :email, :location, :contact_number,
     :time_zone, :employment_type, :max_allocation, :type, :admin,
     :system_user, :global_access, :active, :created_at, :updated_at]
  end

end
