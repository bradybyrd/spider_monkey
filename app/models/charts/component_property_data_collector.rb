################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

module Charts
  class ComponentPropertyDataCollector < PropertyDataCollector
    def initialize(options)
      @component = Component.find_by_id(options[:component_id])
      super
    end

  private

    attr_reader :component, :value_holder_ids

    def value_holder_ids_hash
      unless @value_holder_ids
        application_components = ApplicationComponent.find_all_by_component_id(component.id)
        @value_holder_ids = { "ApplicationComponent" => application_components.map { |ac| ac.id } }
        @value_holder_ids.update "InstalledComponent" => InstalledComponent.find_all_by_application_component_id(application_components).map { |ic| ic.id }
      end
      @value_holder_ids
    end
  end
end
