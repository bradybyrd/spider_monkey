################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

require 'spec_helper'


module AppEnvCompSpecHelper
  def unique_name
      Time.now.to_f.to_s
  end
  def create_installed_component
    @app = create(:app,:name => unique_name)
    @environment = create(:environment,:name => unique_name)
    @component = create(:component,:name => unique_name)
    @application_environment = ApplicationEnvironment.find_or_create_by_app_id_and_environment_id @app.id, @environment.id
    @application_component = ApplicationComponent.find_or_create_by_app_id_and_component_id @app.id, @component.id
    InstalledComponent.create! :application_environment => @application_environment, :application_component => @application_component
  end
end

describe Property do
    before(:each) do
      @property = Property.new
    end

    it {should have_many(:server_level_properties)}
    it {should have_many(:server_levels).through(:server_level_properties)}

    it {should have_many(:component_properties)}
    it {should have_many(:components).through(:component_properties)}

    it {should have_many(:property_work_tasks)}
    it {should have_many(:work_tasks).through(:property_work_tasks)}

    it {should have_many(:script_argument_to_property_maps)}
    it {should have_many(:property_values)}
    it {should have_many(:property_holder_values).class_name('PropertyValue')}

    it {should have_many(:deleted_temporary_property_values).class_name('TemporaryPropertyValue').dependent(:destroy).conditions('deleted_at IS NOT NULL')}
    it {should have_many(:current_temporary_property_values).class_name('TemporaryPropertyValue').dependent(:destroy).conditions('deleted_at IS NULL')}

    it {should have_many(:deleted_property_values).class_name('PropertyValue').dependent(:destroy).conditions('deleted_at IS NOT NULL')}
    it {should have_many(:current_property_values).class_name('PropertyValue').dependent(:destroy).conditions('deleted_at IS NULL')}

    it {should have_and_belong_to_many(:servers)}
    it {should have_and_belong_to_many(:apps)}
end

describe Property do
  include AppEnvCompSpecHelper
  describe "validations" do
    before(:each) do
      @property = Property.new
      @attributes = {:name => "property one"}
    end

    it "should require a name" do
      @attributes[:name] = nil
      @property.update_attributes(@attributes)
      @property.should_not be_valid
   end

   it "should require a unique name" do
      @property.update_attributes(@attributes)
      @duplicate_property = Property.new(@attributes)
      @duplicate_property.should_not be_valid
   end
  end

  describe "named scope" do
    describe ".vary_by_environment_for" do
       before(:each) do
        Property.delete_all
        @app = create(:app,:name => "app test1")
        @property_on_app = create(:property)
        @app.properties << @property_on_app
        @property_not_on_app = create(:property, :name => "Prop 2")
      end

      it "should return properties that are not associated with the given app" do
        Property.vary_by_environment_for(@app).should == [@property_not_on_app]
      end

      it "should return all properties when given an app that has none" do
        other_app = create(:app,:name => "other app test2")
        Property.vary_by_environment_for(other_app).should == [@property_on_app, @property_not_on_app]
      end
    end
    describe ".static_for" do
      before do
        @app = create(:app,:name  => "static for app test1")
        @property_on_app = create(:property)
        @app.properties << @property_on_app
        @property_not_on_app = create(:property,:name => "Prop 2")
      end

      it "should return properties that are associated with the given app" do
        Property.static_for(@app).should == [@property_on_app]
      end

      it "should return nothing if the app has no properties" do
        other_app = create(:app,:name => "static for app test2")
        Property.static_for(other_app).should == []
      end
    end
    describe ".active" do
      before(:each) do
        @property1 = create(:property,:name => "prop 1", :active => true)
        @property2 = create(:property,:name => "prop 2", :active => true)
        @property3 = create(:property,:name => "prop 3", :active => false)
      end

      it "should return all active properties" do
        Property.active.should include(@property1)
        Property.active.should include(@property2)
        Property.active.should_not include(@property3)
      end

      it "should return all active properties sorted by name" do
        Property.active.first.should == @property1
        Property.active.second.should == @property2
      end

    end
    describe ".sorted" do
      before(:each) do
        @property1 = create(:property,:name => "prop 1", :active => true)
        @property2 = create(:property,:name => "prop 2", :active => true)
        @property3 = create(:property,:name => "prop 3", :active => false)
      end

      it "should return all propeties order by name" do
        Property.sorted.first.should == @property1
        Property.sorted.second.should == @property2
        Property.sorted.third.should == @property3
      end
    end
    describe ".property_not_present" do
      before(:each) do
       @property1 = create(:property,:name => "prop 1", :active => true)
       @property2 = create(:property,:name => "prop 2", :active => true)
       @property3 = create(:property,:name => "prop 3", :active => false)
       @component = create(:component,:name => unique_name)
       @component.properties << [@property1,@property3]
       @component.reload
       @property3.reload
      end

      it "should return all properties which are assigned to component" do
         Property.property_not_present(@component).should include(@property1)
         Property.property_not_present(@component).should include(@property2)
         Property.property_not_present(@component).should include(@property3)
      end

      it "should return all active properties which are assigned to component" do
         Property.active.property_not_present(@component).should include(@property1)
         Property.active.property_not_present(@component).should_not include(@property3)
      end
    end
  end

  describe 'filtered by' do
    before(:all) do
      User.current_user = create(:old_user)
      @assigned_app = create(:app)
      @property1 = create(:property)
      @property2 = create(:property, active: false)
      @property3 = create(:property, apps: [@assigned_app])
      @property4 = create(:property)
      @active = [@property1, @property3, @property4]
      @inactive = [@property2]
    end
    after(:all) do
      Property.delete_all
    end

    it 'default' do
      Property.filtered().should =~ @active
    end
    it 'active false and inactive true' do
      Property.filtered(active: false, inactive: true).should =~ @inactive
    end
    it 'both active and inactive' do
      Property.filtered(active: true, inactive: true).should =~ @active + @inactive
    end
    it 'name' do
      Property.filtered(name: @property1.name).should =~ [@property1]
    end
    it 'app_name' do
      Property.filtered(app_name: @assigned_app.name).should =~ [@property3]
    end
  end
  describe "paginate" do
    before(:each) do
      @property = create(:property)
      @property.stub("per_page").and_return(30)
    end

    it "#should return number of items per page" do
      @property.per_page.should be_an_instance_of(Fixnum)
      @property.per_page.should_not be_an_instance_of(String)
    end
  end

  describe "#static_for?" do
    before do
      @associated_app = create(:app,:name => "app test1")
      @non_associated_app = create(:app,:name => "app test2")
      @property = Property.new(:name =>Time.now.to_f.to_s)
      @property.apps << @associated_app
    end

    it "should be true if the property is associated with the given app" do
      @property.should be_static_for(@associated_app)
    end

    it "should be false otherwise" do
      @property.should_not be_static_for(nil)
      @property.should_not be_static_for(@non_associated_app)
    end
  end

  describe "#execution_task_ids=" do
    before(:each) do
      @property = create(:property)
    end
    it "should set @new_execution_task_ids" do
      @property.execution_task_ids = [1,2,3]
      @property.instance_eval { @new_execution_task_ids }.should == [1,2,3]
    end
  end

  describe "#execution_task_ids" do
    before(:each) do
      @property = create(:property)
    end
    it "should return the tasks that allow entry on step execution" do
      task = create(:work_task)
      @property.name = "Property"
      @property.save!
      @property.property_work_tasks.create(:work_task_id => task.id, :entry_during_step_execution => true)
      @property.execution_task_ids.should == [task.id]
    end
  end

  describe "#creation_task_ids=" do
    before(:each) do
      @property = create(:property)
    end
    it "should set @new_creation_task_ids" do
      @property.creation_task_ids = [1,2,3]
      @property.instance_eval { @new_creation_task_ids }.should == [1,2,3]
    end
  end

  describe "#creation_task_ids" do
    before(:each) do
      @property = create(:property)
    end

    it "should return the tasks that allow entry on step creation" do
      task = create(:work_task)
      @property.name = "Property"
      @property.save!
      @property.property_work_tasks.create(:work_task_id => task.id) { |x| x.entry_during_step_creation = true }
      @property.creation_task_ids.should == [task.id]
    end
  end

  describe "#entry_during_step_execution_on_task?" do
    before do
      @property = create(:property)
      @task_on_execution = create(:work_task)
      @property.property_work_tasks.create!(:work_task_id => @task_on_execution.id, :entry_during_step_execution => true)
    end

    it "should be true if the property has a task with entry_during_step_execution true on its join model" do
      @property.entry_during_step_execution_on_task?(@task_on_execution).should be_truthy
    end

    it "should be false for tasks that don't have entry_during_step_execution" do
      task_not_on_execution = create(:work_task,:name => "non-matching task")
      @property.property_work_tasks.create!(:work_task_id => @task_on_execution.id, :entry_during_step_execution => false)
      @property.entry_during_step_execution_on_task?(task_not_on_execution).should be_falsey
    end

    it "should be false for tasks not associated with the property" do
      unassociated_task = create(:work_task,:name => "unassociated task")
      @property.work_tasks.should_not include(unassociated_task)
      @property.entry_during_step_execution_on_task?(unassociated_task).should be_falsey
    end
  end

  describe "#entry_during_step_creation_on_work_task?" do
    before do
      @property = create(:property)
      @task_on_creation = create(:work_task)
      @property.property_work_tasks.create!(:work_task_id => @task_on_creation.id) { |x| x.entry_during_step_creation = true }
    end

    it "should be true if the property has a task with entry_during_step_creation true on its join model" do
      @property.entry_during_step_creation_on_work_task?(@task_on_creation).should be_truthy
    end

    it "should be false for tasks that don't have entry_during_step_creation" do
      task_not_on_creation = create(:work_task,:name => "non-matching task")
      @property.property_work_tasks.create!(:work_task_id => @task_on_creation.id) { |x| x.entry_during_step_creation = false }
      @property.entry_during_step_creation_on_work_task?(task_not_on_creation).should be_falsey
    end

    it "should be false for tasks not associated with the property" do
      unassociated_task = create(:work_task,:name => "unassociated task")
      @property.work_tasks.should_not include(unassociated_task)
      @property.entry_during_step_creation_on_work_task?(unassociated_task).should be_falsey
    end
  end

  describe "#property_value_for_date_and_installed_component_id" do
    before do
      @date_of_change = Time.now
      @property = create(:property,:default_value => "a value")#Property.new(:name => Time.now.to_f.to_s,:default_value => "a value")
      @installed_component = create_installed_component
      @property_value = create(:property_value, :property => @property, :value_holder => @installed_component, :value => "a value")
    end

    it "should convert the date to UTC" do
      @date_of_change.should_receive(:utc)
      @property.property_value_for_date_and_installed_component_id(@date_of_change,@installed_component)
    end

    it "should try to find a current property value that existed at the given date" do
      @property.property_value_for_date_and_installed_component_id(@date_of_change, @installed_component).should == 'a value'
    end
  end

  describe "#value_changed_at_date_for_installed_component_id?" do
    before(:each) do
      @property = create(:property)
      @installed_component = create_installed_component
      @property_value = create(:property_value,:property => @property, :value_holder => @installed_component)
      @date_of_change = @property_value.created_at
    end

    it "should convert the date to UTC" do
     @date_of_change.should_receive(:utc)
     @property.value_changed_at_date_for_installed_component_id?(@date_of_change, @installed_component.id)
    end

    it "should return true if a value is found" do
       @property.value_changed_at_date_for_installed_component_id?(@date_of_change, @installed_component.id).should be_truthy
    end

    it "should return false if a value is not found" do
      @property.value_changed_at_date_for_installed_component_id?(@date_of_change, @some_id).should be_falsey
    end
  end

  describe "#value_for_installed_component" do
    before(:each) do
      @property = create(:property)
      @installed_component = create_installed_component
      @property_value = create(:property_value,:property => @property, :value_holder => @installed_component)
    end

    it "should return the property value between the property and the given installed component" do
      @property.value_for_installed_component(@installed_component).should == @property_value
    end
  end

  describe "#value_for_application_component" do
    before(:each) do
      @app = create(:app)

      @property = create(:property)
      @component = create(:component)
      @application_component = create(:application_component, :app => @app, :component => @component) #ApplicationComponent.find_or_create_by_app_id_and_component_id @app.id, @component.id
      @property_value = create(:property_value,:property => @property, :value_holder => @application_component)
    end

    it "should return the property value between the property and the given application component" do
      @property.value_for_application_component(@application_component).should == @property_value
    end
  end

  describe "#value_for_request" do
    before(:each) do
      @request = create(:request)
      @property = create(:property)
      @property_value = create(:property_value,:property => @property, :value_holder => @request)
    end

    it "should return property value for given request" do
       @property.value_for_request(@request).should == @property_value
    end
  end

  describe "#value_for_server" do
     before(:each) do
       @property = create(:property)
       @server = create(:server)
       @property_value = create(:property_value, :property => @property, :value_holder => @server)
     end

    it "should return property value for given server" do
      @property.value_for_server(@server).should == @property_value
    end
  end

  describe "#value_for_server_aspect" do
    before(:each) do
      @property = create(:property)
      @server_level = create(:server_level)
      @server_aspect = create(:server_aspect, :server_level => @server_level)
      @property_value = create(:property_value, :property => @property, :value_holder => @server_aspect)
    end

    it "should return property values for given server aspect" do
      @property.value_for_server_aspect(@server_aspect).should == @property_value
    end
  end

  describe "#value_for_server_level" do
    before(:each) do
      @property = create(:property)
      @server_level = create(:server_level)
      @property_value = create(:property_value, :property => @property, :value_holder => @server_level)
    end

    it "should return property value for given server level" do
      @property.value_for_server_level(@server_level).should == @property_value
    end
  end

  describe "#value_for_property" do
    before(:each) do
      @property = create(:property, :default_value => "a default value")
      @server_level = create(:server_level)
      @property_value = create(:property_value, :property => @property,:value_holder => @server_level)
    end

    it "should return value for property" do
      @property.value_for_property.try(:value).should == "a default value"
    end

  end

#  describe "#value_for_step" do
#    before(:each) do
#      @property = create(:property, :default_value => "a default value")
#      @request = create(:request)
#      @step = create(:step, :request => @request)
#    end

#    it "should return value for request if property is associated with request" do
#      @property_value = create(:property_value, :property => @property, :value_holder => @request)
#      @property.value_for_request(@step.request).should == @property_value
#      @property.value_for_step(@step).try(:value).should_not == "a default value"
#    end

#    it "should return value for installed component if property is associated with install component" do
#      @installed_component = create_installed_component
#      @property_value = create(:property_value, :property => @property, :value_holder => @installed_component)
#
#      @property.value_for_step(@step).should == @property_value
#      @property.value_for_step(@step).try(:value).should_not == "a default value"
#    end

#    it "should return value for application component if property is associated with application component" do
#      @app = create(:app)
#      @component = create(:component)
#      @application_component = create(:application_component, :app => @app, :component => @component)
#      @property_value = create(:property_value, :property => @property, :value_holder => @application_component)
#
#      @property.value_for_step(@step).should == @property_value
#      @property.value_for_step(@step).try(:value).should_not == "a default value"
#    end
#
#    it "should return default property value" do
#      @property.value_for_step(@step).try(:value).should == "a default value"
#    end

#  end

  describe "#update_value_for_object" do
    #    TODO: update cases for deleted property values
    before(:each) do
      @property = create(:property)
    end

    it "should create property value for server" do
      @server = create(:server)
      @property_value = create(:property_value, :property => @property, :value_holder => @server)
      @property.value_for_server(@server).try(:value).should == @property_value.try(:value)
      @new_property_value = @property.update_value_for_object(@property_value, "new updated value")
      @new_property_value.try(:value).should == "new updated value"
    end

    it "should create new property value for server aspect" do
      @server_level = create(:server_level)
      @server_aspect = create(:server_aspect, :server_level => @server_level)
      @property_value = create(:property_value, :property => @property, :value_holder => @server_aspect)
      @property.value_for_server_aspect(@server_aspect).try(:value).should == @property_value.try(:value)
      @new_property_value = @property.update_value_for_object(@property_value, "new updated value")
      @new_property_value.try(:value).should == "new updated value"
    end

    it "should create new property value for server level" do
       @server_level = create(:server_level)
       @property_value = create(:property_value, :property => @property, :value_holder => @server_level)
       @property.value_for_server_level(@server_level).try(:value).should == @property_value.try(:value)
       @new_property_value = @property.update_value_for_object(@property_value,"new server level value")
       @new_property_value.try(:value).should == "new server level value"
    end

    it "should create property value for request" do
       @request = create(:request)
       @property_value = create(:property_value, :property => @property, :value_holder => @request)
       @property.value_for_request(@request).try(:value).should == @property_value.try(:value)
       @new_property_value = @property.update_value_for_object(@property_value, "new req prop value")
       @new_property_value.try(:value).should == "new req prop value"
    end

    it "should create new property value for application component " do
       @app = create(:app)
       @component = create(:component)
       @application_component = create(:application_component, :app => @app, :component => @component)
       @property_value = create(:property_value, :property => @property, :value_holder => @application_component)
       @property.value_for_application_component(@application_component).try(:value) == @property_value.try(:value)
       @new_property_value = @property.update_value_for_object(@property_value, "new app comp value")
       @new_property_value.try(:value) == "new app comp value"
    end

    it "should create new property value for install component" do
      @installed_component = create_installed_component
      @property_value = create(:property_value, :property => @property, :value_holder => @installed_component)
      @property.value_for_installed_component(@installed_component).try(:value).should == @property_value.try(:value)
      @new_property_value = @property.update_value_for_object(@installed_component, "new inst comp val")
      @new_property_value.try(:value).should == "new inst comp val"
    end

    it "should update the property value" do
       # value already exists by default so no need to create a new one
       @property_value = @property.value_for_property
       @property_value.update_attributes(:value => 'Updated Value')
       @property.value_for_property.try(:value).should == @property_value.try(:value)
       @new_property_value = @property.update_value_for_object(@property, "new property val")
       @new_property_value.try(:value).should == "new property val"
    end
  end

  describe "#locked_for_installed_component" do
    before(:each) do
      @property = create(:property)
      @app = create(:app)
      @component = create(:component)
      @installed_component = create_installed_component
      @application_component = create(:application_component, :app => @app, :component => @component)
    end

    it "for InstalledComponent" do
      @property_value = create(:property_value, :property => @property, :value_holder => @installed_component, :locked => true)
      @property.locked_for_installed_component?(@installed_component).should be_truthy
    end
  end


  describe "#remove_property_for_installed_component" do
    before do
      @installed_component = create_installed_component
      @property = create(:property, :component_ids => [@installed_component.component.id])
      @property_value = create(:property_value, :property => @property, :value_holder => @installed_component)
    end

    it "should mark property value deleted and destroy the component property" do
      comp_property = ComponentProperty.find_by_component_id_and_property_id(@installed_component.component.id, @property.id)

      @property.component_properties.find_by_component_id(@installed_component.component.id).should == comp_property

      @property.remove_property_for_installed_component(@installed_component,@application_component)

      @property.property_values.find_all_by_value_holder_id_and_value_holder_type(@installed_component.id,"InstalledComponent").each { |pc|
       pc.try(:deleted_at).should_not be_nil
      }
      comp_property = ComponentProperty.find_by_component_id_and_property_id(@installed_component.component.id, @property.id)
      comp_property.should be_nil
    end
  end

  describe "#value_for" do
    it "should return the value object for the property" do
      property = create(:property,:name => "property")
      server_level = create(:server_level,:name => "Virtual Servers")
      server_level.properties << property
      server_aspect = create(:server_aspect, :name => "VS1", :server_level => server_level)
      property_value = create(:property_value, :property => property, :value_holder => server_aspect, :value => "Foo")

      property.value_for(server_aspect).should == property_value
    end
  end

  describe "#update_value_for" do
    before do
      @property = create(:property)
      @server_level = create(:server_level)
      @server_level.properties << @property
      @server_aspect = create(:server_aspect, :server_level => @server_level)
    end

    it "should create a new value object when none exists" do
      @property.value_for(@server_aspect).should be_nil
      @property.update_value_for(@server_aspect, "New value!")

      value = @property.value_for(@server_aspect)
      value.should be_a(PropertyValue)
      value.value.should == "New value!"
    end

    it "should update an existing value object when one exists" do
      property_value = create(:property_value,:property => @property, :value_holder => @server_aspect, :value => "Old value.")

      @property.update_value_for(@server_aspect, "New value!")
      updated_value = @property.value_for(@server_aspect)
      updated_value.should == property_value
      updated_value.value.should == "New value!"
    end
  end
end

describe Property do
  describe "#component_ids_with_destroy_unused_values=" do
    before do
      @property = create(:property)
      @property.stub(:component_ids_without_destroy_unused_values=)
    end

    it "should set @removed_component_ids to the value of the old ids minus the new ids" do
      @property.stub(:component_ids).and_return([1, 2, 3])
      @property.component_ids_with_destroy_unused_values = [3, 4, 5]
      @property.instance_variable_get(:@removed_component_ids).should == [1, 2]
    end

    it "should call component_ids_without_destroy_unused_values= with the values" do
      @property.should_receive(:component_ids_without_destroy_unused_values=).with([])
      @property.component_ids_with_destroy_unused_values = []
    end
  end
  describe "#update_work_tasks after save hook" do
    before do
      @property = create(:property)
      @task1 = create(:work_task)
      @task2 = create(:work_task,:name => "task2")
      @property.name = "property"
    end

    it "should associate the tasks noted in @new_execution_task_ids with the property and mark them as entry_during_step_execution" do
      @property.instance_variable_set(:@new_execution_task_ids, [@task1.id, @task2.id])
      @property.save!
      @property.property_work_tasks.count.should == 2
      @property.property_work_tasks.map { |pt| pt.work_task }.should include(@task1)
      @property.property_work_tasks.map { |pt| pt.work_task }.should include(@task2)
      @property.property_work_tasks.map { |pt| pt.entry_during_step_execution }.all?.should be_truthy
      @property.property_work_tasks.map { |pt| pt.entry_during_step_creation }.any?.should be_falsey
    end

    it "should associate the tasks noted in @new_creation_task_ids with the property and mark them as entry_during_step_creation" do
      @property.instance_variable_set(:@new_creation_task_ids, [@task1.id, @task2.id])
      @property.save!
      @property.property_work_tasks.count.should == 2
      @property.property_work_tasks.map { |pt| pt.work_task }.should include(@task1)
      @property.property_work_tasks.map { |pt| pt.work_task }.should include(@task2)
      @property.property_work_tasks.map { |pt| pt.entry_during_step_creation }.all?.should be_truthy
      @property.property_work_tasks.map { |pt| pt.entry_during_step_execution }.any?.should be_falsey
    end

    it "should not create more than one property_task per task" do
      @property.instance_variable_set(:@new_execution_task_ids, [@task1.id, @task2.id])
      @property.instance_variable_set(:@new_creation_task_ids, [@task1.id])
      @property.save!
      @property.property_work_tasks.count.should == 2
      @property.work_tasks.count.should == 2
    end

    it "should remove old tasks" do
      @property.save!
      @property.instance_variable_set(:@new_execution_task_ids, [])
      @property.instance_variable_set(:@new_creation_task_ids, [])
      create(:property_work_task, :property => @property, :work_task => @task1, :entry_during_step_execution => true)
      create(:property_work_task, :property => @property, :work_task => @task2, :entry_during_step_creation => true)
      @property.property_work_tasks.count.should == 2
      @property.save!
      @property.property_work_tasks.should be_empty
    end
  end
  describe "#update_property_values after save hook" do
    before do
        @property = create(:property, :default_value => "default value!")
    end
    it "should create new property value and mark deleted the old one" do
        @property.property_values.count.should == 1
        @property.property_holder_values.first.try(:deleted_at).should be_nil
        @property.property_holder_values.first.try(:value).should == "default value!"
        @value_id = @property.property_holder_values.first.id
        @property.name ="pro2"
        @property.save!
        @property.reload
        @property.property_values.count.should == 2
        @property.property_holder_values.first.try(:value).should == "default value!"
        @property.property_holder_values.last.try(:value).should == "default value!"
        second = @property.property_holder_values.where('property_values.id <> ?', @value_id).try(:first)
        second.try(:deleted_at).should be_nil
        first = @property.property_holder_values.find(@value_id)
        first.try(:deleted_at).should_not be_nil
    end
  end
  describe "#update_script_argument_to_property_maps after save hook" do
    before do
      @property = Property.new(:name => "property 101")
    end

    it "should return nil if @removed_component_ids is blank" do
      @property.instance_eval { @removed_component_ids = [] }
      @property.save!
    end
#    TODO: complete the followting example
#    it "should delete all script argument property mapping if @removed_component_ids is given" do
#      @property.name = "new prop 101"
#      msmap = mock_model(ScriptArgumentToPropertyMap)
#      @property.instance_eval { @removed_component_ids = [2] }
#      ScriptArgumentToPropertyMap.property_id_equals(self.id).for_components.with_components(@removed_component_ids)
#      @property.save!
#    end
  end
  describe "#remove_property_value_references after save hook" do
    #TODO: complete following examples
    before do
      # initialization
    end

    it "should not do anything if old_app_ids blank" do
    # case
    end

    it "should not do anything if deleted_property_apps not present" do
    # case
    end

    it "should remove property values if deleted_property_apps and old_app_ids present" do
    # case
    end
  end
  describe "#destroy_values_if_component_changes before save hook" do
    before do
      @property = Property.new
      @component = create(:component)
      @property_values = [create(:property_value, :value_holder_id => @component.id)]
      @property.instance_eval { @removed_component_ids = [1] }
      @property.property_values.stub(:all).and_return(@property_values)
      Component.stub(:find).and_return(@component)
    end

    it "should find the components in question" do
      Component.should_receive(:find).with(1).and_return(@component)
      @property.send(:destroy_values_if_component_changes)
    end

    it "should collect the property values to destroy" do
      @property.property_values.should_receive(:all).with(:conditions => { :value_holder_id => @component.installed_component_ids,
                                                                           :value_holder_type => 'InstalledComponent' }).and_return(@property_values)
      @property.send(:destroy_values_if_component_changes)
    end

    it "should destroy the values found" do
      @property_values.each { |cf| cf.should_receive(:destroy) }
      @property.send(:destroy_values_if_component_changes)
    end
  end
end

describe Property do

  describe '#filtered' do

    before(:all) do
      Property.delete_all
      User.current_user = create(:old_user)
      @app = create(:app, :name => 'Test app')
      @comp = create(:component, :name => 'Some component')
      @server = create(:server, :name => 'Dev Server')
      @server_level = create(:server_level, :name => 'Top level')
      @work_task = create(:work_task, :name => 'WorkTask')
      @p1 = create_property(:name => 'Default property', :apps => [@app], :components => [@comp])
      @p2 = create_property(:name => 'Inactive property', :active => false, :servers => [@server],
                            :server_levels => [@server_level], :work_tasks => [@work_task])
      @p3 = create_property(:name => 'Active property')

      @prop_val1 = create(:property_value, :property => @p3, :value => 'Old Value', :value_holder => @server,
                          :deleted_at => Time.now)
      @prop_val2 = create(:property_value, :property => @p3, :value => 'New Value', :value_holder => @server)

      @active = [@p1, @p3]
      @inactive = [@p2]
    end

    after(:all) do
      PropertyValue.delete([@prop_val1, @prop_val2])
      Property.delete_all
      WorkTask.delete([@work_task])
      ServerLevel.delete([@server_level])
      Server.delete([@server])
      Component.delete([@comp])
      App.delete([@app])

    end

    it_behaves_like 'active/inactive filter' do

      it 'cumulative filter active by default' do
        result = described_class.filtered()
        result.should match_array([@p1, @p3])
      end

      it 'empty cumulative filter' do
        result = described_class.filtered(:name => 'Inactive property')
        result.should be_empty
      end

      it 'cumulative filter inactive' do
        result = described_class.filtered(:inactive => true, :name => 'Inactive property')
        result.should match_array([@p2])
      end

      it 'cumulative filter by name, app_name, component_name' do
        result = described_class.filtered(:name => 'Default property',
                                          :app_name => 'Test app',
                                          :component_name => 'Some component')
        result.should match_array([@p1])
      end

      it 'cumulative filter by server_name, server_level_name, work_task' do
        result = described_class.filtered(:inactive => true,
                                          :server_name => 'Dev Server',
                                          :server_level_name => 'Top level',
                                          :work_task => 'WorkTask')
        result.should match_array([@p2])
      end

      it 'cumulative filter by current_value' do
        result = described_class.filtered(:current_value => 'New Value')
        result.should match_array([@p3])
      end

      it 'cumulative filter by deleted_value' do
        result = described_class.filtered(:deleted_value => 'Old Value')
        result.should match_array([@p3])
      end

    end
  end

  protected

  def create_property(options = nil)
    create(:property, options)
  end
end
