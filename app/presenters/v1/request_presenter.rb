################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class V1::RequestPresenter < V1::AbstractPresenter

  # creates a local accessor based on the passed symbol
  presents :request

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
      # :id => request.id,
      # :name => request.name
    # }
    # data_hash = { :other_resource => data_hash } if include_root
  # end

  # example of a reference to the presenter of another model
  # def request
    # Api::V1::ResourcePresenter.new( request.requests ).as_json( false )
  # end

  private
  def resource_options
    { only: safe_attributes, include: included_attributes }
  end

  def included_attributes
        {
          :release => { :only => [:id, :name] },
          :steps => { :only => [:id, :name, :component_version, :aasm_state, :work_started_at, :work_finished_at, :manual, :position, :component_id, :installed_component_id], :methods => [:number, :component_name] },
          :executable_steps => { :only => [:id, :name]},
          :checked_steps => { :only => [:id, :name]},
          :environment => { :only => [:id, :name ] },
          :activity => { :only => [:id, :name ] },
          :deployment_coordinator => { :only => [:id, :login ], :methods => [:name] },
          :owner => { :only => [:id, :login ], :methods => [:name] },
          :requestor => { :only => [:id, :login ], :methods => [:name] },
          :apps => { :only => [:id, :name] },
          :plan_member =>
            {
              :only => [:id],
              :include => {
                :plan => { :only => [:id, :name] },
                :stage => { :only => [:id, :name] }
              }
            },
          :business_process => { :only => [:id, :name] },
          :package_contents => { :only => [:id, :name] },
          :category => { :only => [:id, :name] },
          :request_template => { :only => [:id, :name] },
          :associated_current_property_values => { :only => [:id, :value], :methods => [:name] },
          :associated_property_values => { :only => [:id, :value], :methods => [:name] },
          :messages => { :only => [:id, :value] },
          :email_recipients => { :only => [:id, :recipient_id, :recipient_type] },
          :parent_request_origin => { :only => [:id, :name] },
          deployment_window_event: { only: [:id, :name, :start_at, :finish_at, :duration] }
        }.delete_if{|k,v| @include_except.include? k.to_s}
  end


  def safe_attributes
    [:id, :name, :aasm_state, :created_at, :updated_at, :description, :wiki_url, :estimate, :rescheduled, :scheduled_at_date,
      :scheduled_at_hour, :scheduled_at_minute, :scheduled_at_meridian, :target_completion_at_date,
      :target_completion_at_hour, :target_completion_at_minute, :target_completion_at_meridian, :notes,
      :scheduled_at, :started_at, :target_completion_at, :completed_at, :cancelled_at, :deleted_at,
      :planned_at, :server_association_id, :server_association_type,:created_from_template,
      :promotion, :auto_start,

      :notify_on_request_planned, :notify_on_request_start, :notify_on_request_problem, :notify_on_request_resolved,
      :notify_on_request_hold, :notify_on_request_cancel, :notify_on_request_complete,
      :notify_on_request_step_owners,

      :notify_on_step_ready, :notify_on_step_start, :notify_on_step_block, :notify_on_step_problem, :notify_on_step_complete,
      :notify_on_step_step_owners, :notify_on_step_requestor_owner,

      :notify_on_request_participiant, :notify_on_step_participiant, :additional_email_addresses, :notify_group_only
    ]
  end
end
