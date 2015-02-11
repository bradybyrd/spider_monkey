################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

module Charts
  class PropertyDataCollector

    def initialize(options)
      @property        = Property.find_by_id(options[:property_id])
      @summed_property = Property.find_by_id(options[:summed_property_id])
      @chart_factor    = options[:chart_factor]

      init_data
    end

    def data
      @data ||= Charts::Data.new
    end

    def name
      return '' unless ready_to_collect?
      @name ||= init_name
    end

  protected

    attr_reader :property, :summed_property

    def one_factor?
      @chart_factor == 'single'
    end

    def ready_to_collect?
      if one_factor?
        property
      else
        property && summed_property
      end.to_bool
    end

    def values
      @values ||= property.default_values if property
    end

    def init_name
      if one_factor?
        property.name.titleize
      else
        "#{summed_property.name.titleize} by #{property.name.titleize}"
      end
    end

    def init_data
      return unless ready_to_collect?

      if one_factor?
        collect_count_data
      else
        collect_sum_data
      end
    end

    def collect_count_data
      used_values = []
      value_holder_ids_hash.each do |value_holder_type, value_holder_ids|
        used_values += PropertyValue.find_all_by_value_holder_id_and_value_holder_type_and_property_id(
                         value_holder_ids, value_holder_type, property.id).map { |v| v.value }
      end

      # Any installed component that didn't have a PropertyValue model associated with it is presumed to be using the first value
      default_value = values.first
      (used_values.size - value_holder_ids.size).times { used_values << default_value }

      values.each do |val|
        value_count = used_values.select { |v| v == val }.size
        data.add val, value_count
      end
    end

#FIXME: This is broken.  Needs to be reworked for the value_holder_ids_hash method like above.
    def collect_sum_data
      remaining_ic_ids = value_holder_ids.dup

      values.each do |val|
        selected_ic_ids = PropertyValue.find_all_by_value_holder_id_and_value_holder_type_and_property_id_and_value(
                            remaining_ic_ids, value_holder_type, property.id, val)
        selected_ic_ids.map! { |pv| pv.value_holder_id }
        
        remaining_ic_ids -= selected_ic_ids

        used_values = PropertyValue.find_all_by_value_holder_id_and_value_holder_type_and_property_id(
                        selected_ic_ids, value_holder_type, summed_property.id).map { |v| v.value.to_i }

        data.add val, used_values.sum
      end
    end

  end
end
