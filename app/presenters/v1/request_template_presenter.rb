################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

class V1::RequestTemplatePresenter < V1::AbstractPresenter

  # creates a local accessor based on the passed symbol
  presents :request_template

  private

  def resource_options
    { only: safe_attributes,
      include: {
          request: {only: [:id, :name, :aasm_state]},
          parent_template: {only: [:id, :name]},
          plan_stages: {only: [:id, :name]}
      }
    }
  end

  def safe_attributes
    [:id, :name, :recur_time, :team_id, :parent_id, :archive_number, :archived_at, :created_at, :updated_at,:aasm_state,:created_by]
  end

end
