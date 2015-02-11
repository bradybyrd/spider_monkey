require 'spec_helper'

describe PackageInstanceCreate do
  it 'does not save a package instance if its properties fail to be updated' do
    package = create(:package)
    reference = create(:reference, package: package)
    package_instance = PackageInstance.new
    package_instance.package = package
    PackageInstanceCreate.call( package_instance,
                                selected_reference_ids: [reference.id],
                                properties_with_values: [invalid_property: 'invalid_property_value'],
                                reference_properties_with_values: [ref_id: reference.id, property_name: 'invalid_property', property_value: 'invalid_property_value']
    )
    expect{PackageInstance.find(package_instance.id)}.to raise_error(ActiveRecord::RecordNotFound)
  end
end