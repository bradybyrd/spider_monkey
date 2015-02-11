require 'spec_helper'

feature 'User views package instances index' do
  include PackageSortingAndPaginationHelper

  before do
    sign_in create(:user, :root)
    @per_page = PackageInstance.per_page
  end

  after(:each) do
    PackageInstance.per_page = @per_page
  end

  scenario 'and they see package instances', js: true do
    package = create(:package)
    active = create(:package_instance, package: package, active: true)
    inactive = create(:package_instance, package: package, active: false)
    steps = create_pair(:step, package_instance: active)
    requests = steps.map(&:request)

    visit package_instances_path(package)

    expect(active_instances).to have_instance_named(active.name)
    expect(active_instances).to have_timestamp(active.created_at)
    requests.each do |request|
      expect(active_instances).to have_recent_request_number(request.number)
    end
    expect(inactive_instances).to have_instance_named(inactive.name)
  end

  scenario 'and they see links to view paginated active instances', js: true do
    package = create(:package)
    create_paginated_package_instances(2, package: package, active: true)

    visit package_instances_path(package)

    within '.active_package_instance_pages' do
      expect(pagination_links).to have_current_page(1)
      expect(pagination_links).to have_link_to_page(2)
    end
  end

  scenario 'and they see links to view paginated inactive instances', js: true do
    package = create(:package)
    create_paginated_package_instances(2, package: package, active: false)

    visit package_instances_path(package)

    within '.inactive_package_instance_pages' do
      expect(pagination_links).to have_current_page(1)
      expect(pagination_links).to have_link_to_page(2)
    end
  end

  scenario 'and packages are ordered asc by name', js: true do
    package = create(:package)
    instance_a = create(:package_instance, package: package, name: 'Package A', active: true)
    instance_b = create(:package_instance, package: package, name: 'Package B', active: true)
    inactive_instance_a = create(:package_instance, package: package, name: 'Inactive A', active: false)
    inactive_instance_b = create(:package_instance, package: package, name: 'Inactive B', active: false)

    visit package_instances_path(package)

    expect(active_instances).to list_first(instance_a)
    expect(active_instances).to list_last(instance_b)
    expect(inactive_instances).to list_first(inactive_instance_a)
    expect(inactive_instances).to list_last(inactive_instance_b)
  end

  scenario 'and packages can be sorted desc by name', js: true do
    package = create(:package)
    instance_a = create(:package_instance, package: package, name: 'Package A', active: true)
    instance_b = create(:package_instance, package: package, name: 'Package B', active: true)
    inactive_instance_a = create(:package_instance, package: package, name: 'Inactive A', active: false)
    inactive_instance_b = create(:package_instance, package: package, name: 'Inactive B', active: false)

    visit package_instances_path(package)
    toggle_sort_direction

    expect(active_instances).to list_first(instance_b)
    expect(active_instances).to list_last(instance_a)
    expect(inactive_instances).to list_first(inactive_instance_b)
    expect(inactive_instances).to list_last(inactive_instance_a)
  end

  scenario 'and there is a link to go back to the packages list' do
    package_instance = create(:package_instance, name: 'Package A')

    visit package_instances_path(package_instance.package)
    click_back_link

    expect(current_path).to eq packages_path
  end

  def create_paginated_package_instances(number_of_records, package_options)
    create_list(:package_instance, number_of_records, package_options)
    PackageInstance.per_page = 1
  end

  def active_instances
    find('#active_table tbody')
  end

  def inactive_instances
    find('#inactive_table tbody')
  end

  def have_instance_named(name)
    have_css('td', text: name)
  end

  def have_timestamp(created_at)
    have_css("[data-timestamp=\"#{created_at.utc}\"]")
  end

  def have_recent_request_number(request_number)
    have_css('td', text: request_number.to_s )
  end

  def click_back_link
    find('.metadata_backlink').click
  end
end
