module PropertyValuesFromApi
  ## mainly to support rest client
  def find_property_by_name( prop_name )
    if self.properties.present?
      self.properties.find { | prop | prop.name == prop_name }
    end
  end

  # convenience finder (mostly for REST clients) that allows you to pass property value pairs
  # and have the matching properties looked up and updated safely
  # Note that this must be called after the entity is saved.
  def find_properties_with_values
    # normalize the incoming to always be an array because multiple XML tag sets might produce an array
    self.properties_with_values = [self.properties_with_values].compact unless self.properties_with_values.is_a? Array
    self.properties_with_values_lookup_failed = false
    self.properties_with_values_sanitized = []
    if self.properties_with_values.present?
      # start stepping through the values
      self.properties_with_values.each do |pv|
        # in order to support XML, we support a verbose format with property_name and property value tags
        # so we need to figure out which allowed format we have
        if pv[:property_name].present? && pv[:property_value].present?
          property_name = pv[:property_name]
          p_value = pv[:property_value]
          # find the property
          my_property = self.find_property_by_name(property_name.to_s)
          # if the property is found, change its value
          if my_property.blank?
            self.properties_with_values_lookup_failed = true
            # self.errors.add(:properties_with_values, "contained references to properties could not be found. Did you confirm the property exists and the name is correct?")
          else
            self.properties_with_values_sanitized << {property: my_property, value: p_value}
          end
        else
          # otherwise we likely have the short form suitable for json and one work XML elements
          pv.each_pair do |p_name, p_value|
            # find the property
            my_property = self.find_property_by_name(p_name.to_s)
            Rails.logger.info('-------my_property: ' + my_property.inspect)
            # if the property is found, change its value
            if my_property.blank?
              self.properties_with_values_lookup_failed = true
              # self.errors.add(:properties_with_values, "contained references to properties could not be found. Did you confirm the property exists and the name is correct?")
              break
            else
              self.properties_with_values_sanitized << {property: my_property, value: p_value}
            end
          end
        end
      end
    end
    # be sure the call back returns true or else the call will fail with no error message
    # from the validation loop
    true
  end


  # property updates have to be done after the record is saved, so this is called by an
  # after save hook
  def update_properties_with_values
    self.find_properties_with_values

    # don't do anything if there was an error looking them up or no properties were passed
    unless self.properties_with_values_lookup_failed || self.properties_with_values_sanitized.blank?
      # looped through the passed pairs
      self.properties_with_values_sanitized.each do |my_property_row|
        my_property = my_property_row[:property]
        my_value = my_property_row[:value]
        # if the property is found, change its value
        unless my_property.blank?
          my_property.update_value_for_reference(self, my_value)
        end
      end
    end
    # be sure the call back returns true or else the call will fail with no error message
    # from the validation loop
    true
  end
end
