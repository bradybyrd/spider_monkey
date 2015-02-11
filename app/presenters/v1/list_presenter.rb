################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################
class V1::ListPresenter < V1::AbstractPresenter

  # creates a local accessor based on the passed symbol
  presents :list

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
    return { :only => safe_attributes, :methods => [:required?], :include => {
        :list_items => { :only => [ :id, :value_text, :value_num, :last_modified_by_id, 
                                    :created_at, :updated_at, :archive_number, :archived_at ]}  
      }
    }
  end

  def safe_attributes
    return [:id, :name, :created_by_id, :is_text, :archive_number, :archived_at, :created_at, :updated_at]
  end

end
