require "spec_helper"
require "cancan/matchers"
require "permissions/permission_granters"

describe PermissionGranter do

  it "initialize should set user" do
    instance = PermissionGranter.new
    instance.instance_variable_get(:@user).should_not == nil
  end

  it "key should set key value to the child instance" do
    key_value = :some_key
    other_key_value = :some_other_key
    class SomePermGranter < PermissionGranter
      set_key :some_key
    end
    class SomeOtherPermGranter < PermissionGranter
      set_key :some_other_key
    end

    instance = SomePermGranter.new
    instance.key.should == key_value
    instance = SomeOtherPermGranter.new
    instance.key.should == other_key_value
  end

  it "get_subject should return subject class for some object" do
    obj = Plan.new
    PermissionGranter.get_subject(obj).should == "Plan"
  end

  it "get_subject should return value for string value" do
    obj = "main_tab"
    PermissionGranter.get_subject(obj).should == obj
  end

  describe "instance" do
    before(:each) do
      @instance = PermissionGranter.new
    end

    it "grant? should raise NotImplementedError" do
      lambda{@instance.grant?(:any, :any)}.should raise_error(NotImplementedError)
    end

  end
end