################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################
class V1::ConstraintPresenter < V1::AbstractPresenter

  # creates a local accessor based on the passed symbol
  presents :constraint

  private

  def resource_options
    return {only: safe_attributes}
  end

  def safe_attributes
    return [:id, :active, :constrainable_id, :constrainable_type, :governable_id, :governable_type, :created_at, :updated_at]
  end

end
