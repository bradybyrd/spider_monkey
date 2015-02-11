require 'spec_helper'

describe ChangeRequest do
  before(:each) do
    @change_request = ChangeRequest.new
  end

  describe "associations" do
    it "should have many" do
      @change_request.should have_many(:steps)
      @change_request.should have_many(:step_holders)
    end

    it "should belong to" do
      @change_request.should belong_to(:plan)
      @change_request.should belong_to(:query)
      @change_request.should belong_to(:project_server)
    end
  end

  it "should have the scopes" do
    ChangeRequest.should respond_to(:ascend_by_cg_no)
  end

  describe "should have array constants" do
    it { ChangeRequest::Fields.should be_a Array }
    it "should contain symbols" do
      ChangeRequest::Fields.each { |s| s.should be_a Symbol }
    end
    it { ChangeRequest::TextAreaFields.should be_a Array }
    it "should contain symbols" do
      ChangeRequest::TextAreaFields.each { |s| s.should be_a Symbol }
    end
  end

  it 'should run proper callback before save' do
    change_request = ChangeRequest.new
    change_request.should_receive(:stringify_attributes!)
    change_request.send(:save)
  end

  it "should have hashed labels" do
    ChangeRequest.labels.should be_a Hash
  end
end
