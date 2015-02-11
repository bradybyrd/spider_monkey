################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

require 'spec_helper'

describe App do

  context '' do
    before(:each) do
      User.current_user = User.find_by_login("admin")
      @app1 = create(:app)
      @app = create(:app)
    end

    describe "associations" do
      it "should have many" do
        @app1.should have_many(:apps_requests)
        @app1.should have_many(:requests)
        @app1.should have_many(:application_environments)
        @app1.should have_many(:environments)
        @app1.should have_many(:application_components)
        @app1.should have_many(:components)
        @app1.should have_many(:installed_components)
        @app1.should have_many(:version_tags)
        @app1.should have_many(:development_teams)
        @app1.should have_many(:teams)
        @app1.should have_many(:apps_business_processes)
        @app1.should have_many(:business_processes)
        @app1.should have_many(:assigned_apps)
        @app1.should have_many(:users)
        @app1.should have_many(:component_templates)
        @app1.should have_many(:package_templates)
        @app1.should have_many(:assigned_apps)
        @app1.should have_many(:steps)
        @app1.should have_many(:routes)
        @app1.should have_many(:route_gates)
        @app1.should have_many(:groups).through(:teams)
      end

      it "should have and belong to many" do
        @app1.should have_and_belong_to_many(:procedures)
        @app1.should have_and_belong_to_many(:properties)
      end
    end

    describe "validations" do
      it "should always have name" do
        @app1.should validate_presence_of(:name)
        @app1.should validate_uniqueness_of(:name)
      end
    end

    describe "attribute normalizations" do
      it { should normalize_attribute(:name).from('  Hello  ').to('Hello') }
    end

    describe "post create hooks" do
      it 'should create a default route' do
        routes = Route.filter_by_app_id(@app.id)
        routes.length.should == 1
        routes.first.name.should == '[default]'
      end
    end
  end

  describe 'application packages' do
    it 'adds new packages when new package ids are set' do
      app = create(:app)
      packages = create_list(:package, 2)
      package_ids = packages.map(&:id)
      expect(app.packages).to eq []

      app.package_ids = package_ids
      app.save

      expect(app.packages.reload).to eq packages
    end

    it 'removes packages when packages ids are removed' do
      app = create(:app)
      packages = create_list(:package, 2)
      associate_app_with_packages(app, packages)
      expect(app.packages).to eq packages

      app.package_ids = [packages.last.id]
      app.save

      expect(app.packages.reload).to eq [packages.last]
    end

    it 'removes all packages when package ids are set to an empty array' do
      app = create(:app)
      packages = create_list(:package, 2)
      associate_app_with_packages(app, packages)
      expect(app.packages).to eq packages

      app.package_ids = []
      app.save

      expect(app.packages.reload).to eq []
    end

    it 'keeps the packages if package_ids are not changed' do
      app = create(:app)
      packages = create_list(:package, 2)
      associate_app_with_packages(app, packages)

      app.touch

      expect(app.packages.reload).to eq packages
    end
  end

  describe '#filtered' do

    before(:all) do
      App.delete_all
      User.current_user = create(:old_user)
      @app1 = create_app(:active => true)
      @app2 = create_app(:active => false, :name => 'Inactive App')
      @app3 = create_app(:active => true, :name => 'Default App')
      @active = [@app1, @app3]
      @inactive = [@app2]
    end

    after(:all) do
      App.delete_all
    end

    it_behaves_like 'active/inactive filter' do

      it 'cumulative filter active by default' do
        result = described_class.filtered(:name => 'Default App')
        result.should match_array([@app3])
      end

      it 'empty cumulative filter active by default' do
        result = described_class.filtered(:name => 'Inactive App')
        result.should be_empty
      end

      it 'cumulative filter inactive' do
        result = described_class.filtered(:inactive => true, :name => 'Inactive App')
        result.should match_array([@app2])
      end
    end

  end

  describe '#environments_visible_to_user' do
    context 'for user with assigned app' do
      it 'returns only environments assigned to application which user has access through team' do
        user        = create(:user, :non_root, login: 'Mr. Doe')
        environment = create(:environment, name: 'Almighty')
        app         = create(:app, environments: [environment], user_ids: [user.id])
        create(:team, groups: user.groups, apps: [app])
        create(:environment, name: 'Environment not assigned to app')

        expect(app.environments_visible_to_user(user)).to eq [environment]
      end
    end

    context 'for user with assigned app from app creation' do
      it 'returns only environments assigned to application which user has access through team' do
        user        = create(:user, :non_root, login: 'Mr. Doe')
        environment = create(:environment, name: 'Almighty')
        team = create(:team, groups: user.groups)
        create(:environment, name: 'Environment not assigned to app')
        app = create(:app, environments: [environment], teams:[team])

        expect(app.environments_visible_to_user(user)).to eq [environment]
      end
    end

    context 'for user without assigned app' do
      it 'returns nothing' do
        user        = create(:user, :non_root, login: 'Mr. Doe')
        other_user  = create(:user, :non_root, login: 'Mr. Holms')
        environment = create(:environment, name: 'Almighty')
        app         = create(:app, environments: [environment], user_ids: [user.id])
        create(:team, groups: user.groups, apps: [app])
        create(:environment, name: 'Environment not assigned to the app')

        expect(app.environments_visible_to_user(other_user)).to be_empty
      end
    end

    context 'user is root' do
      it 'returns unassigned applications as well' do
        root_user = create :user, :root
        environment = create(:environment, name: 'Almighty')
        User.current_user = nil # to prevent creation of default assigned_apps, see App#give_access_to_creator
        unassigned_application = create :app, environments: [environment]

        environment_ids = unassigned_application.environments_visible_to_user(root_user).map(&:id)

        expect(environment_ids).to include environment.id
      end
    end
  end

  protected

  def create_app(options = nil)
    create(:app, options)
  end

  def associate_app_with_packages(app, packages)
    packages.each do |package|
      create(:application_package, package: package, app: app)
    end
  end

end
