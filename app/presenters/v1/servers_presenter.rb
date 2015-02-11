################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class V1::ServersPresenter < V1::AbstractPresenter

  # creates a local accessor based on the passed symbol
  presents :servers

  # call super with a list of safe fields
  # def as_json( options = nil )
    # super( {:only => safe_attributes }.merge(options) )
  # end
# 
  # # call super with a list of safe fields
  # def to_xml( options = {})
    # super( default_options.merge(options) )
  # end
  
  # # underlying logic for assembling the correct serialized hash
  # def custom_hash
  # data_hash = {
      # :id => user.id,
      # :name => user.name
    # }
    # data_hash = { :other_resource => data_hash } if include_root
  # end

  # example of a reference to the presenter of another model
  # def user
    # Api::V1::ResourcePresenter.new( user.users ).as_json( false )
  # end
  
  private
  
  def resource_options
    return { :only => safe_attributes, :include => {
        :property_values => 
        { 
          :only => [:id, :value, :property_id, :deleted_at, :created_at],
          :methods => [:name] 
        },
       :properties => { :only => [:id, :name] },
       :server_aspects => { :only => [:id, :name, :server_level_id] },
       :environments => { :only => [:id, :name] },
       :server_groups => { :only => [:id, :name] },
       :installed_components => { 
         :only => [ :id, :application_component_id, :application_environment_id, :location,
                    :version, :default_server_group_id, :reference_id ],
         :include => { 
           :component => { :only => [:id, :name] },
           :app => { :only => [:id, :name] },
           :environment  => { :only => [:id, :name] }
           } }
       }
    }
  end

  
  def safe_attributes
    return [:id, :name, :dns, :ip_address, :os_platform, :created_at, :updated_at, :active]
  end
end
