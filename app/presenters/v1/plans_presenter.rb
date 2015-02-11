################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class V1::PlansPresenter < V1::AbstractPresenter

  # creates a local accessor based on the passed symbol
  presents :plans

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
      # :id => plan.id,
      # :name => plan.name,
      # :release => release
    # }
    # data_hash = { :other_resource => data_hash } if include_root
  # end

  # example of a reference to the presenter of another model
  # def release
    # Api::V1::ResourcePresenter.new( plan.release ).as_json( false )
  # end

  private
  
  def resource_options
    return { :only => safe_attributes, :include => { :plan_template => { :only => [:id, :name, :is_automatic], :include => { :stages => { :only => [:id, :name, 'auto-start'] }}},
                           :release => { :only => [:id, :name] },
                           :teams => { :only => [:id, :name ] },
                           :plan_routes => { :only => [:id], :include => {
                               :route => { :only => [:id, :name, :description, :route_type]}} },
                           :plan_stage_instances => { :only => [:id, :aasm_state], :include => {
                               :plan_stage => {:only => [:id, :name] }}}
                           }
           }
  end

  def safe_attributes
    return [:id, :name, :description, :aasm_state, :plan_template_id, :project_server_id, :foreign_id, :release_date, :release_id, :release_manager_id, :created_at, :updated_at]
  end

end

