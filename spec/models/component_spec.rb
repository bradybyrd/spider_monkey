################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

require 'spec_helper'

describe Component do

  context '' do
    before(:each) do
      User.current_user = User.find_by_login("admin")
      @business_component = Component.new
      @comp1 = create(:component)
    end

    describe "validations" do
      it { @comp1.should validate_presence_of(:name) }
      it { @comp1.should validate_uniqueness_of(:name)}

    end

    describe "attribute normalizations" do
      it { should normalize_attribute(:name).from('  Hello  ').to('Hello') }
    end


    describe "associations" do
      it "should have many" do
        @comp1.should have_many(:application_components)
        @comp1.should have_many(:apps)
        @comp1.should have_many(:installed_components)
        @comp1.should have_many(:steps)
        @comp1.should have_many(:component_properties)
        @comp1.should have_many(:properties)
      end
    end
  end

  describe '#filtered' do

    before(:all) do
      User.current_user = create(:old_user)
      Component.delete_all
      @app = create(:app, :name => 'Default App')
      @prop = create(:property, :name => 'test_property')

      @comp1 = create_component(:name => 'Component 1')
      @comp2 = create_component(:name => 'Component 2', :apps => [@app])
      @comp2a = create_component(:name => 'Component 2a', :apps => [@app], :active => false)
      @comp3 = create_component(:name => 'Component 3', :properties => [@prop])
      @comp3a = create_component(:name => 'Component 3a', :properties => [@prop], :active => false)
      @comp4 = create_component(:name => 'Component 4', :apps => [@app], :properties => [@prop])
      @comp4a = create_component(:name => 'Component 4a', :apps => [@app], :properties => [@prop], :active => false)

      @active = [@comp1, @comp2, @comp3, @comp4]
      @inactive = [@comp2a, @comp3a, @comp4a]
    end

    after(:all) do
      Component.delete_all
      App.delete(@app)
      Property.delete(@prop)
    end

    it_behaves_like 'active/inactive filter' do
      describe 'filter by name' do
        subject { described_class.filtered(:name => 'Component 1') }
        it { should match_array([@comp1]) }
      end

      describe 'filter by app_name' do
        subject { described_class.filtered(:app_name => @app.name) }
        it { should match_array([@comp2, @comp4]) }
      end

      describe 'filter by property_name' do
        subject { described_class.filtered(:property_name => @prop.name) }
        it { should match_array([@comp3, @comp4]) }
      end

      describe 'filter by name, app_name and property_name' do
        subject { described_class.filtered(:name => 'Component 4', :app_name => @app.name, :property_name => @prop.name) }
        it { should match_array([@comp4]) }
      end

      describe 'filter by name (inactive is not specified)' do
        subject { described_class.filtered(:name => 'Component 4a') }
        it { should be_empty }
      end

      describe 'filter by name (inactive is specified)' do
        subject { described_class.filtered(:name => 'Component 4a', :inactive => true) }
        it { should match_array([@comp4a]) }
      end
    end
  end

  describe '#granter_type', custom_roles: true do
    it 'returns application granter type if component has no installed components' do
      component = build(:component)
      user = build(:user)

      expect(component).to_not receive(:has_installed_components_by_apps?)
      expect(component.granter_type(user)).to eq :application
    end

    it "returns application granter type if component has no installed components through user's assigned apps" do
      component = create(:installed_component).component
      user = build(:user)
      allow(component).to receive(:has_installed_components_by_apps?).and_return(false)

      expect(component.granter_type(user)).to eq :application
    end

    it 'returns environment granter type if component has installed components through assigned apps' do
      component = create(:installed_component).component
      user = build(:user)
      allow(component).to receive(:has_installed_components_by_apps?).and_return(true)

      expect(component.granter_type(user)).to eq :environment
    end
  end

  describe '#has_installed_components_by_apps?', custom_roles: true do
    it "returns true if component has installed components through user's assigned apps" do
      installed_component = create(:installed_component)
      component = installed_component.component
      user = create(:user, apps: [installed_component.app])

      expect(component.has_installed_components_by_apps?(user)).to be_truthy
    end

    it 'returns false if user has no assigned apps' do
      installed_component = create(:installed_component)
      component = installed_component.component
      user = create(:user)

      expect(component.has_installed_components_by_apps?(user)).to be_falsey
    end

    it 'returns false if component has no installed components' do
      application_component = create(:application_component)
      component = application_component.component
      user = create(:user, apps: [application_component.app])

      expect(component.has_installed_components_by_apps?(user)).to be_falsey
    end

    it 'returns false if component has no application components' do
      component = create(:component)
      user = create(:user, apps: [create(:app)])

      expect(component.has_installed_components_by_apps?(user)).to be_falsey
    end
  end

  def create_component(options = nil)
    create(:component, options)
  end
end
