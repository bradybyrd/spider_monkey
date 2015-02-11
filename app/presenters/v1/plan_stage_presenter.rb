################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class V1::PlanStagePresenter < V1::AbstractPresenter

  # creates a local accessor based on the passed symbol
  presents :plan_stage

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
      # :id => plan_stage.id,
      # :name => plan_stage.name
    # }
    # data_hash = { :other_resource => data_hash } if include_root
  # end

  # example of a reference to the presenter of another model
  # def plan_stage
    # Api::V1::ResourcePresenter.new( plan_stage.plan_stages ).as_json( false )
  # end  
  
  private
  
  def resource_options
    return { :include => { :plan_template => { :only => [:id, :name, :is_automatic] }, 
                           :request_templates => { :only => [:id, :name], :methods => [:number] },
                           :plan_stage_dates => { :only => [:id, :start_date, :end_date]},
                           :members => { :only => [:position], 
                                         :include => { :stage => { :only => [:id, :name, :position] },
                                         :request => { :only => [:name, :aasm_state], :methods => [:number] } } },
                           :environment_type => { :only => [:id, :name, :description ]}
                           }
    }
  end

end
