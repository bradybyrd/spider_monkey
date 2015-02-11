################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

require 'spec_helper'

describe PropertyValue do
  it {should belong_to(:property)}
  it {should belong_to(:value_holder)}
end

describe PropertyValue do
  before do
    user = User.find_by_login('admin')
    User.current_user = user || create(:user)
  end
  describe 'validations' do
    before do
      @property = create(:property)
      @server_level = create(:server_level)
      @property_value = PropertyValue.new
    end

    it { @property_value.should validate_presence_of(:property_id) }
    it { @property_value.should validate_presence_of(:value_holder) }

    it 'should require property object' do
       @property_value.value_holder = @server_level
       expect(@property_value).to_not be_valid
       expect(@property_value.errors[:property_id].size).to eq(1)
    end

    it 'should require value holder' do
      @property_value.property = @property
      expect(@property_value).to_not be_valid
      expect(@property_value.errors[:value_holder].size).to eq(1)
    end

  end

  describe "named scope" do
    before do
        @property_one = create(:property)
        @property_two = create(:property)
        @property_three = create(:property, :active => false)
        @server_level = create(:server_level)
        @server_aspect = create(:server_aspect, :server_level => @server_level)
        @property_value_one = create(:property_value,:property => @property_one, :value_holder => @server_level)
        @property_value_two = create(:property_value,:property => @property_two, :value_holder => @server_aspect)
        @property_value_three = create(:property_value,:property => @property_three, :value_holder => @server_level)
    end

    describe ".active" do
      it "should list all property values which has active property" do
        PropertyValue.active.should include(@property_value_one)
        PropertyValue.active.should include(@property_value_two)
      end
      it "should not list property value which has in-active property" do
        PropertyValue.active.should_not include(@property_value_three)
      end
    end

    describe ".upto_date" do
      it "should list all property values which are created before given date" do
        # fast machines will capture the new records in the same instant -- alternatives to sleep?
        @freeze_time = Time.zone.now.utc
        sleep 1
        property_new = create(:property)
        property_value_new = create(:property_value, :property => property_new, :value_holder => @server_level)
        PropertyValue.upto_date(@freeze_time).should include(@property_value_one)
        PropertyValue.upto_date(@freeze_time).should_not include(property_value_new)
      end
    end

    describe ".in_order" do
      it "should return list order by value_holder_type, value_holder_id, created_at DESC" do
        property_new = create(:property)
        property_value_new = create(:property_value, :property => property_new, :value_holder => @server_aspect)
        PropertyValue.in_order.last(4).first.should == property_value_new
        PropertyValue.in_order.last(4).second.should == @property_value_two
        PropertyValue.in_order.last(4).third.should == @property_value_three
        PropertyValue.in_order.last(4).fourth.should == @property_value_one
      end
    end

    describe ".values_for_app_comp" do
      it "should return list of property values for given application component id" do
        property = create(:property)
        app = create(:app)
        component = create(:component)
        app_component = create(:application_component, :app => app, :component => component)
        property_value = create(:property_value, :property => property, :value_holder => app_component)
        PropertyValue.values_for_app_comp(app_component.id).count.should == 1
        PropertyValue.values_for_app_comp(app_component.id).first.should == property_value
      end
    end
  end

  describe "delegates" do
    it{ should respond_to(:name)}
  end
end

describe PropertyValue do
  before do
    user = User.find_by_login('admin')
    User.current_user = user || create(:user)
  end
  describe "#holder" do
    it "should return value holder object" do
      property = create(:property)
      server_level = create(:server_level)
      property_value = create(:property_value, :property => property, :value_holder => server_level)
      property_value.holder.should == server_level
    end
  end

  describe "#value_label" do
    before do
      @property = create(:property)
      @server_level = create(:server_level)
      @server_aspect = create(:server_aspect, :server_level => @server_level)
      @server = create(:server)
      @app = create(:app)
      @component = create(:component)
      @env = create(:environment)
      @app_envionment = create(:application_environment, :app => @app, :environment => @env)
      @app_component = create(:application_component, :app => @app, :component => @component)

      @installed_component = create(:installed_component, :application_component => @app_component, :application_environment => @app_envionment)


      @package = create(:package)
      @package_instance = create(:package_instance, package: @package, active: true, name: 'test')

      @reference = create( :reference, uri: 'myUri', server: @server, package: @package )
      @inst_ref = create(:instance_reference, server: @server, package_instance: @package_instance, reference: @reference)


    end
    it "should return (property-global) as label value if the holder is nil" do
      property_value = @property.property_values.first
      property_value.value_label.should == '(property-global)'
    end

    it "should return 'property name (server)' as label value" do
       property_value = create(:property_value, :property => @property, :value_holder => @server)
       property_value.value_label.should == "#{property_value.holder.name} (server)"
    end

    it "should return 'property name (server-level)' as label value" do
      property_value = create(:property_value, :property => @property, :value_holder => @server_aspect)
      property_value.value_label.should == "#{property_value.holder.name} (server-level)"
    end

    it "should return 'app name - component name (application component)' as label value" do
      property_value = create(:property_value, :property => @property, :value_holder => @app_component)
      property_value.value_label.should == "#{property_value.holder.app.name} - #{property_value.holder.component.name} (application component)"
    end

    it "should return 'app name - component name - environment name (installed component)' as label value" do
      property_value = create(:property_value, :property => @property, :value_holder => @installed_component)
      property_value.value_label.should == "#{property_value.holder.application_component.app.name} - #{property_value.holder.component.name} - #{property_value.holder.application_environment.environment.name} (installed component)"
    end

    it "should return 'property name (server-level) -inactive' as label value for deleted property value" do
      property_value = create(:property_value, :property => @property, :value_holder => @server_aspect)
      property_value.should_receive(:deleted_at).and_return(Time.now.utc)
      property_value.value_label.should == "#{property_value.holder.name} (server-level)-inactive"
    end

    it "should return 'package name - reference name (package reference)' as label value" do
      property_value = create(:property_value, :property => @property, :value_holder => @reference)
      property_value.value_label.should == "#{@reference.package.name} #{@reference.name} (package reference)"
    end

    it "should return '... (package instance)' as label value" do
      property_value = create(:property_value, :property => @property, :value_holder => @package_instance)
      property_value.value_label.should == "#{@package_instance.package.name} #{@package_instance.name} (package instance)"
    end

    it "should return '.. (package instance reference)' as label value" do
      property_value = create(:property_value, :property => @property, :value_holder => @inst_ref)
      property_value.value_label.should == "#{@inst_ref.package_instance.package.name} #{@inst_ref.package_instance.name} #{@inst_ref.name} (package instance reference)"
    end


  end

  describe "#display_value" do
    before do
      @property = create(:property)
      @server_level = create(:server_level)
      @property_value = create(:property_value, :property => @property, :value_holder => @server_level, :value => "test value")
    end
    it "should return value" do
      @property_value.display_value.should == 'test value'
    end

    it "should return masked value if property is private" do
      private_property = create(:property, :is_private => true)
      @property_value.should_receive(:property).and_return(private_property)
      @property_value.display_value.should == '**********'
    end
  end
end


