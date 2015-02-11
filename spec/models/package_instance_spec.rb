require 'spec_helper'

describe PackageInstance do
  describe "#filtered" do
    before(:each) do
      @prop = create(:property, :name => 'test_property')
      @package = create(:package, properties: [@prop])
    end

    it 'can be filtered by name' do
      foo_active_instance = create(:package_instance, package: @package, active: true, name: 'foo')
      bar_active_instance = create(:package_instance, package: @package, active: true, name: 'bar')
      foo_inactive_instance = create(:package_instance, package: @package, active: false, name: 'foo_i')
      other_package_instance = create(:package_instance)

      results = @package.package_instances.filtered(name: 'foo')

      expect(results).to eq [foo_active_instance]
      expect(results).to_not include bar_active_instance
      expect(results).to_not include foo_inactive_instance
      expect(results).to_not include other_package_instance
    end

    it 'can be filtered by package_name' do
      foo_active_instance = create(:package_instance, package: @package, active: true, name: 'foo')

      results = PackageInstance.filtered(package_name: @package.name)

      expect(results).to eq [foo_active_instance]
      expect(results).to_not include @package.name
    end

    it 'can be filtered by property_name' do
      foo_active_instance = create(:package_instance, package: @package, active: true, name: 'foo', properties: [@prop])

      results = PackageInstance.filtered(property_name: @prop.name)

      expect(results).to eq [foo_active_instance]
    end
  end

  it "reports the recent unique Requests it has been on" do
    package_instance = create(:package_instance)
    requests = create_pair(:request)
    duplicate_request = requests.second
    create(:step, package_instance: package_instance, request: duplicate_request)
    create(:step, package_instance: package_instance, request: duplicate_request)
    create(:step, package_instance: package_instance, request: requests.first)

    recent_activity = package_instance.recent_activity.map(&:number).sort.to_sentence

    expected_string = requests.map(&:number).sort.to_sentence
    expect(recent_activity).to eq expected_string
  end

  context '' do
    before(:each) do
      User.current_user = User.find_by_login("admin")
      default_server = create(:server)

      @package = create(:package)
      @package_instance = create(:package_instance, package: @package, active: true, name: 'test')

    end

    describe "validations" do
      it { @package_instance.should validate_presence_of(:name) }
    end

    describe "associations" do
      it "should belong to" do
        @package_instance.should belong_to(:package)
      end

      it "should have many" do
        @package_instance.should have_many(:instance_references)
        @package_instance.should have_many(:property_values)
        @package_instance.should have_many(:properties).through(:property_values)
      end
    end
  end

  describe '.accessible_instances_of_package' do
    it 'returns objects that belong to a user and a package' do
      app, user = create_connected_app_and_user
      package = create_package_in(app)
      other_package = create_package_in(app)
      expected_instance = create(:package_instance, package: package)
      unexpected_instance = create(:package_instance, package: other_package)

      actual = PackageInstance.accessible_instances_of_package(user.id, package.id)

      expect(actual).to include expected_instance
      expect(actual).to_not include unexpected_instance
    end

    def create_connected_app_and_user
      assigned_app = create(:assigned_app)
      [assigned_app.app, assigned_app.user]
    end

    def create_package_in(app)
      create(:application_package, app: app).package
    end
  end

  context "#destroyableOrUsed" do
    it "is destroyable and not used" do
      package = create(:package)
      package_instance = create(:package_instance, package: package)
      expect(package_instance).to be_destroyable
      expect(package_instance).to_not be_used
    end

    it "is used and not destroyable" do
      package = create(:package)
      package_instance = create(:package_instance, package: package)
      app = create(:app, :with_installed_component)
      app.packages = [package]
      request = create(:request, apps:[app], environment: app.environments.last)
      step = create(:step, request: request)
      step.related_object_type = "package"
      step.package = package
      step.package_instance = package_instance
      step.save!
      package_instance.requests = [request]
      expect(package_instance).to_not be_destroyable
      expect(package_instance).to be_used
    end
  end
end
