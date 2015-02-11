################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################
class V1::PlanStageInstancePresenter < V1::AbstractPresenter

  # creates a local accessor based on the passed symbol
  presents :plan_stage_instance

  private

  def resource_options
    return {only: safe_attributes, :methods => [:constraint_violations], include: {
        plan: {only: [:id, :name], include: {
            plan_template: {only: [:id, :name]}
        }
        },
        plan_stage: {only: [:id, :name], include: {
            plan_template: {only: [:id, :name]},
            environment_type: {only: [:id, :name]}
        }
        },
        constraints: {only: [:id, :constrainable_id, :constrainable_type]}
    }
    }
  end

  def safe_attributes
    return [:id, :aasm_state, :archive_number, :archived_at, :created_at, :updated_at]
  end

end
