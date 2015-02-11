################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class V1::ApplicationPackagePresenter < V1::AbstractPresenter

  # creates a local accessor based on the passed symbol
  presents :application_package

  private

  def resource_options
    { only: safe_attributes, include: {
        app: { only: [:id, :name] },
        package: { only: [:id, :name] },
        properties: property_attributes,
        property_values: property_value_attributes
      }
    }
  end

  def safe_attributes
    [:created_at, :updated_at]
  end

  def property_attributes
    { only: [:id, :name, :default_value, :is_private, :active] }
  end

  def property_value_attributes
    {
      only: [:id, :value],
      methods: [:name]
    }
  end
end
