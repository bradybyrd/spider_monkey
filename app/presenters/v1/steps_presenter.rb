################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class V1::StepsPresenter < V1::AbstractPresenter

  # creates a local accessor based on the passed symbol
  presents :steps

  # overwrite the default json to provide a unique hash with child objects
  # def as_json( options = nil )
    # custom_hash.as_json
  # end

  # # overwrite the default XML to provide a unique string with child objects
  # def to_xml( options = {})
  #   custom_hash.to_xml
  # end
  
  # # underlying logic for assembling the correct serialized hash
  # def custom_hash
  # data_hash = {
      # :id => step.id,
      # :name => step.name
    # }
    # data_hash = { :other_resource => data_hash } if include_root
  # end

  # example of a reference to the presenter of another model
  # def step
    # Api::V1::ResourcePresenter.new( step.requests ).as_json( false )
  # end

  private

  def resource_options
    {
      only: safe_attributes,
      methods: [:number],
      include: { parent: { only: [:id, :name], methods: [:number] },
                 owner: { only: [:id, :name, :email, :login] },
                 script: { only: [:id, :name] },
                 work_task: { only: [:id, :name] },
                 phase: { only: [:id, :name] },
                 runtime_phase: { only: [:id, :name] },
                 installed_component: { only: [:id, :application_environment_id, :application_component_id], methods: [:app, :component, :environment] },
                 component: { only: [:id, :name] },
                 request: { only: [:id, :name, :aasm_state], methods: [:number] },
                 category: { only: [:id, :name] },
                 floating_procedure: { only: [:id, :name] },
                 package_template: { only: [:id, :name] },
                 version_tag: { only: [:id, :name] },
                 package: { only: [:id, :name] },
                 package_instance: { only: [:id, :name] }
      }
    }
  end

  def safe_attributes
    [:id, :name, :position, :owner_type, :created_at, :updated_at, :component_version, :complete_by,
     :different_level_from_previous, :estimate, :location_detail, :aasm_state, :work_started_at, :work_finished_at,
     :ready_at, :start_by, :procedure, :should_execute, :execute_anytime, :script_type, :own_version,
     :custom_ticket_id, :release_content_item_id, :manual, :description, :on_plan, :latest_package_instance,
     :create_new_package_instance
    ]
  end
end
