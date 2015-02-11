################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class V1::RolePresenter < V1::AbstractPresenter
  presents :role

  private

  def resource_options
    { only: safe_attributes }
  end

  def safe_attributes
    [:id, :name, :active]
  end
end



