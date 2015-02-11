require 'spec_helper'

feature 'User views packages index' do
  include PackageSortingAndPaginationHelper

  before do
    sign_in create(:user, :root)
    @packages_per_page = Package.per_page
  end

  after(:each) do
    Package.per_page = @packages_per_page
  end

  scenario 'and they see links to view paginated active packages', js: true do
    create_paginated_packages(2, active: true)

    visit packages_path

    within '.active_package_pages' do
      expect(pagination_links).to have_current_page(1)
      expect(pagination_links).to have_link_to_page(2)
    end
  end

  scenario 'and they can click to second page', js: true do
    package_a = create(:package, name: 'Package A', active: true)
    package_b = create(:package, name: 'Package B', active: true)
    Package.per_page = 1

    visit packages_path
    expect(active_packages).to list_first(package_a)

    click_second_page

    expect(active_packages).to list_first(package_b)
  end

  scenario 'and they see links to view paginated inactive packages', js: true do
    create_paginated_packages(2, active: false)

    visit packages_path

    within '.inactive_package_pages' do
      expect(pagination_links).to have_current_page(1)
      expect(pagination_links).to have_link_to_page(2)
    end
  end

  scenario 'and packages are ordered asc by name', js: true do
    package_a = create(:package, name: 'Package A', active: true)
    package_b = create(:package, name: 'Package B', active: true)
    inactive_package_a = create(:package, name: 'Inactive A', active: false)
    inactive_package_b = create(:package, name: 'Inactive B', active: false)

    visit packages_path

    expect(active_packages).to list_first(package_a)
    expect(active_packages).to list_last(package_b)
    expect(inactive_packages).to list_first(inactive_package_a)
    expect(inactive_packages).to list_last(inactive_package_b)
  end

  scenario 'and packages can be sorted desc by name', js: true do
    package_a = create(:package, name: 'Package A', active: true)
    package_b = create(:package, name: 'Package B', active: true)
    inactive_package_a = create(:package, name: 'Inactive A', active: false)
    inactive_package_b = create(:package, name: 'Inactive B', active: false)

    visit packages_path
    toggle_sort_direction

    expect(active_packages).to list_first(package_b)
    expect(active_packages).to list_last(package_a)
    expect(inactive_packages).to list_first(inactive_package_b)
    expect(inactive_packages).to list_last(inactive_package_a)
  end

  def active_packages
    find('#active_table tbody')
  end

  def inactive_packages
    find('#inactive_table tbody')
  end

  def create_paginated_packages(number_of_packages, package_options)
    packages = create_list(:package, number_of_packages, package_options)
    Package.per_page = 1
  end
end
