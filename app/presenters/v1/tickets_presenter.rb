################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class V1::TicketsPresenter < V1::AbstractPresenter
  # creates a local accessor based on the passed symbol
  presents :tickets

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
    return { :include => { :project_server => { :only => [:id, :name] },
                           :app => { :only => [:id, :name] },
                           :plans => { :only => [:id, :name] },
                           :related_tickets => { :only => [:id, :name] },
                           :steps => { :only => [:id, :name ], :methods => [:number] },
                           :extended_attributes => { :only => [:id, :name, :value_text] }
                         }
           }
  end
end
