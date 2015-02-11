################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class V1::RunsPresenter < V1::AbstractPresenter

  # creates a local accessor based on the passed symbol
  presents :runs

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
      # :id => run.id,
      # :name => run.name,
      # :release => release
    # }
    # data_hash = { :other_resource => data_hash } if include_root
  # end

  # example of a reference to the presenter of another model
  # def release
    # Api::V1::ResourcePresenter.new( run.release ).as_json( false )
  # end

  private
  
  def resource_options
    return { :include => { :plan => { :only => [:id, :name, :aasm_state] }, 
                           :plan_stage => { :only => [:id, :name] },
                           :plan_members => { :only => [:id, :name, :position], 
                             :include => { :request => { :only => [ :id, :name, :aasm_state ] } } }
                           }
           } 
  end

end
