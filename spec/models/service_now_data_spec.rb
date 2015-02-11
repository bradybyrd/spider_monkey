require "spec_helper"

describe ServiceNowData do

  before(:all) do
    @service_now_data = ServiceNowData.new
    @service_now_data.table_name = :service_now_data
  end

  it "should have #table_name" do
    @service_now_data.table_name.should == :service_now_data
  end

  describe "validations" do
    it { @service_now_data.should validate_presence_of(:name) }
    it { @service_now_data.should validate_presence_of(:sys_id) }
    it { @service_now_data.should validate_presence_of(:project_server_id) }
  end

  describe "associations" do
    it { @service_now_data.should belong_to(:project_server) }
  end

  describe "named scopes" do
    it "should have a proper return" do
      ServiceNowData.of_project_server(1).size.should_not be > 2
      ServiceNowData.name_equals(['test1', 'test2', 'test3']).size.should_not be > 2
      ServiceNowData.by_name_fragment('test').size.should_not be > 2
      #ServiceNowData.sys_ids_equals(1..3).size.should_not be > 2
    end
  end

end




