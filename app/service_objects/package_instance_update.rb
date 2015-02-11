class PackageInstanceUpdate

##
## Updates the package instance.
##   The selected_reference_ids are a list of reference ids that
##   will be copied from the package to this instance
##   Returns the package instance.  If there was an error it will
##   be included in package instance errors array.
##
  def self.call( package_instance, attributes={} )
    begin
      ActiveRecord::Base.transaction do
        # rails converts [] to nil, need to keep the []
        if attributes.has_key?(:reference_ids) && attributes[:reference_ids].nil?
          attributes[:reference_ids] = []
        end
        package_instance.update_attributes(attributes)
        package_instance.save!

        if package_instance.reference_ids.nil?
          package_instance.copy_references( package_instance.selected_reference_ids )
          package_instance.remove_references( package_instance.remove_reference_ids )
        else
          current_reference_ids = package_instance.package_reference_ids
          package_instance.copy_references( package_instance.reference_ids - current_reference_ids )
          package_instance.remove_references( current_reference_ids - package_instance.reference_ids )
        end

        ## Override reference values
        package_instance.update_reference_properties_with_values

      end
      rescue => e
        Rails.logger.error('ERROR PackageInstanceService update_instance: ' + e.message + "\n" + e.backtrace.join("\n"))
        package_instance.errors.add(:package_instance, "Error updating: #{e.message}" )
      end
    return package_instance
  end

end
