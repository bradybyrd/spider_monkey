require 'spec_helper'

feature 'User creates a package instance' do
  context 'with a package that has a reference' do
    scenario 'references checkboxes are checked by default' do
      sign_in create(:user, :root)
      package = create(:package)
      create(:reference, package: package)
      visit new_package_instance_path(package)

      expect(reference_table).to have_checked_reference_field
    end
  end

  def reference_table
    find('#reference_table')
  end

  def have_checked_reference_field
    have_checked_field('package_instance[selected_reference_ids][]')
  end
end
