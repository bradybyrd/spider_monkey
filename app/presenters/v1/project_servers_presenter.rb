################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class V1::ProjectServersPresenter < V1::AbstractPresenter

  # creates a local accessor based on the passed symbol
  presents :project_servers

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
       :queries => { :only => [:id, :name] },
       :projects => { :only => [:id, :name] },
       :parent_projects => { :only => [:id, :name] },
       :releases => { :only => [:id, :name] },
       :tickets => { :only => [:id, :name, :foreign_id, :status, :ticket_type, :app_id] }
       }
    }
  end

  
  def safe_attributes
    return [:id, :name, :ip, :server_url, :port, :username, :details, :server_name_id]
  end

end
