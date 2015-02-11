################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class V1::PlanTemplatesPresenter < V1::AbstractPresenter

  # creates a local accessor based on the passed symbol
  presents :plan_templates

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
      # :id => plan_template.id,
      # :name => plan_template.name
    # }
    # data_hash = { :other_resource => data_hash } if include_root
  # end

  # example of a reference to the presenter of another model
  # def plan_template
    # Api::V1::ResourcePresenter.new( plan_template.plan_templates ).as_json( false )
  # end
  
  
  private
  
  def resource_options
    return { :only => safe_attributes, :include => { :plans => { :only => [:id, :name] },
                           :stages => { :only => [:id, :name] } } } 
  end

  def safe_attributes
    return [:id, :name, :template_type, :is_automatic, :archive_number, :archived_at, :created_at, :updated_at, :aasm_state, :created_by]
  end

end