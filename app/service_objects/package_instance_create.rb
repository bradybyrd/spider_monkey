class PackageInstanceCreate

##
## Creates an package instance for the package.
##   The package_ref_ids are a list of reference ids that
##   will be copied for this
##   Returns the package instance, package_instance will contain errors if there was an error
##
  def self.call( package_instance, attributes={} )
    ## increment the instance number
    begin
      ActiveRecord::Base.transaction do

          hold_name = attributes['name']
          attributes.delete('name')
          package_instance.update_attributes(attributes)

          package = package_instance.package

          if package.blank?
            package_instance.errors.add(:package_instance, I18n.t('package_instance.package_blank') )
            raise I18n.t('package_instance.package_blank')
          end

          package_instance.active = true

          # Apply the name if it was not provided.
          if package_instance.name.blank?
            if hold_name.nil?
              package_instance.name = package_instance.format_name( package.instance_name_format, package.next_instance_number )
            else
              package_instance.name = hold_name
            end
          end

          package.increment_next_instance_number

          package_instance.not_from_rest =  true

          package_instance.copy_property_from_package

          package.save!
          package_instance.save!
          package_instance.copy_references( package_instance.selected_reference_ids || package_instance.reference_ids )

          ## Override reference values
          package_instance.update_reference_properties_with_values!

        end
    rescue => e
        Rails.logger.error('ERROR PackageInstanceService create_instance: ' + e.message + "\n" + e.backtrace.join("\n"))
    end
    package_instance
  end

end


