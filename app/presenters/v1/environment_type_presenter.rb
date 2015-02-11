################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################
class V1::EnvironmentTypePresenter < V1::AbstractPresenter

  # creates a local accessor based on the passed symbol
  presents :environment_type

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
    {:only => safe_attributes, :include => {
        :environments => {:only => [:id, :name]},
        :plan_stages => {:only => [:id, :name, :plan_template_id]}
      }
    }
  end

  def safe_attributes
    [:id, :name, :description, :strict, :label_color, :position, :archive_number, :archived_at, :created_at, :updated_at]
  end

end
