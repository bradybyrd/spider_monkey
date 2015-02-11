################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################
class V1::PropertyPresenter < V1::AbstractPresenter

  # creates a local accessor based on the passed symbol
  presents :property

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
  # :id: user.id,
  # :name: user.name
  # }
  # data_hash = { :other_resource: data_hash } if include_root
  # end

  # example of a reference to the presenter of another model
  # def user
  # Api::V1::ResourcePresenter.new( user.users ).as_json( false )
  # end

  private

  def resource_options
    return { only: safe_attributes, include: {
        current_property_values: { only: [ :id, :name, :value, :value_holder_id, :value_holder_type,
                              :created_at, :deleted_at ] },
        deleted_property_values: { only: [ :id, :name, :value, :value_holder_id, :value_holder_type,
                              :created_at, :deleted_at ] },
        work_tasks: { only: [ :id, :name ] },
        components: { only: [ :id, :name ] },
        packages: { only: [ :id, :name ] },
        server_levels: { only: [ :id, :name ] },
        servers: { only: [ :id, :name ] },
        apps: { only: [ :id, :name ] }
      }
    }
  end

  def safe_attributes
    return [:id, :name, :value_num, :active, :default_value, :is_private, :created_at, :updated_at]
  end

end
