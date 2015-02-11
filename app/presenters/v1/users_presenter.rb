################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

class V1::UsersPresenter < V1::AbstractPresenter

  presents :users

  private

  def resource_options
    {
        only: safe_attributes,
        include: [:teams, :groups]
    }
  end

  def safe_attributes
    [:id, :login, :email, :first_name, :last_name, :location, :contact_number,
     :created_at, :updated_at, :employment_type, :max_allocation,
     :system_user, :type, :admin, :active, :time_zone, :global_access]
  end

end
