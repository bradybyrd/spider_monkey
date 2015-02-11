################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Category do
  before(:each) do
    @category = Category.new
    @user = create(:user)
    User.stub(:current_user) { @user }
  end

  describe "validations" do
    it { @category.should validate_presence_of(:name) }
    it { @category.should validate_presence_of(:categorized_type) }
    it { @category.should ensure_length_of(:name).is_at_most(255) }
    # shoulda validator is fooled by our array accessor, so we have to test this one old school
    it "should require associated_events" do
      category = build(:category, :associated_events => [])
      category.should_not be_valid
    end
  end

  describe "normalizations" do
    it { should normalize_attribute(:name).from('  Hello  ').to('Hello') }
  end

  describe "named scopes" do

    describe "associated_event" do
      it "should return the categories with the given associated event" do
        category = create(:category, :associated_events => ['foo', 'bar', 'baz'])
        Category.associated_event('foo').should == [category]
        Category.associated_event('bar').should == [category]
        Category.associated_event('baz').should == [category]
      end
    end

    describe "request" do
      it "should return the categories typed for requests" do
        request_category = create(:category, :categorized_type => 'request')
        step_category = create(:category, :categorized_type => 'step')
        Category.request.should == [request_category]
      end
    end

    describe "step" do
      it "should return the categories typed for steps" do
        request_category = create(:category, :categorized_type => 'request')
        step_category = create(:category, :categorized_type => 'step')
        Category.step.should == [step_category]
      end
    end
  end

  describe "#associated_events=" do
    it "should store the events array as a comma-separated string" do
      @category.associated_events = ['foo', 'bar', 'baz']
      @category[:associated_events].should == 'foo,bar,baz'
    end
  end

  describe "#associated_events" do
    it "should return the comma-separated string as an array" do
      @category[:associated_events] = 'foo,bar,baz'
      @category.associated_events.should == ['foo', 'bar', 'baz']
    end
  end

  describe "#human_associated_event" do
    it "should return the associated event with spaces and capitalization" do
      @category.associated_events = ["the_associated_event"]
      @category.human_associated_events.should == "The associated event"
    end
  end

  describe "acts_as_archival" do
    describe "should be archivable" do
      before(:each) do
        @category = create(:category)
        stub_activity_log
      end
      it "should archive" do
        @category.archived?.should be_falsey
        @category.archive
        @category.archived?.should be_truthy
      end

      it "should be immutable when archived" do
        @category.archive
        @category.name = 'Test Mutability'
        @category.save.should be_falsey
      end

      it "should unarchive" do
        @category.archive
        @category.archived?.should be_truthy
        @category.unarchive
        @category.archived?.should be_falsey
        @category.name = 'Test Mutability'
        @category.save.should be_truthy
      end

      it "should have archival scopes" do
        @category2 = create(:category)
        @category2.archive
        Category.count.should == 2
        Category.archived.count.should == 1
        Category.unarchived.count.should == 1
      end

      it "should not archive if belongs to a running request" do
        @request = create(:request)
        @request.plan_it!
        @category.requests << @request
        @category.requests.in_progress.count.should == 1
        Category.unarchived.count.should == 1
        results = @category.archive
        results.should be_falsey
        Category.unarchived.count.should == 1
      end

      it "should allow archiving if it has no functional requests" do
        @request = create(:request)
        @category.requests << @request
        @request.destroy
        @category.requests.functional.count.should == 0
        Category.unarchived.count.should == 1
        results = @category.archive
        results.should be_truthy
        Category.unarchived.count.should == 0
        Category.archived.count.should == 1
      end

      it "but should not archive if belongs to a running step" do
        @request = create(:request)
        @step = create(:step, :request => @request)
        @request.plan_it!
        @request.start!
        @step.ready_for_work!
        @step.start!
        @step.aasm_state.should == 'in_process'
        @step.request.aasm_state.should == 'started'
        @category.update_attributes(:categorized_type => 'step')
        @step.update_attribute(:category, @category)
        Step.count.should == 1
        Step.running.count.should == 1
        Category.unarchived.count.should == 1
        results = @step.category.archive
        results.should be_falsey
        Category.unarchived.count.should == 1
      end

      it "but should allow archiving if it is associated with a step and the request to which this step belongs has been deleted" do
        @request = create(:request)
        @step = create(:step, :request => @request)
        @category.update_attribute(:categorized_type,'step')
        @category.steps << @step
        @request.cancel!
        @request.unfreeze_request!
        @request.soft_delete!
        @request.aasm_state.should == 'deleted'
        @category.archive
        Category.unarchived.count.should == 0
        Category.archived.count.should == 1
      end
    end
  end

  describe "should not be destroyable unless archived and free of associations" do

    before(:each) do
      @category = create(:category)
    end

    it "should not allow deletion if not archived" do
      Category.count.should == 1
      @category.archived?.should be_falsey
      results = @category.destroy
      results.should be_falsey
      Category.count.should == 1
    end

    it "should allow deletion if archived and without steps or requests" do
      Category.count.should == 1
      @category.requests.count.should == 0
      @category.steps.count.should == 0
      @category.archive
      @category.archived?.should be_truthy
      results = @category.destroy
      results.should be_truthy
      Category.count.should == 0
    end

    it "should not allow deletion if archived and has requests" do
      Category.count.should == 1
      @category.archived?.should be_falsey
      @request = create(:request, :category => @category)
      @category.archive
      results = @category.destroy
      results.should be_falsey
      Category.count.should == 1
    end

    it "but should allow archiving if it has no running steps" do
      Category.count.should == 1
      @category.archived?.should be_falsey
      @category.update_attribute(:categorized_type, 'step')
      @request = create(:request)
      @step = create(:step, :request => @request, :category => @category)
      @category.archive
      results = @category.destroy
      results.should be_falsey
      Category.count.should == 1
    end
  end

  describe '#filtered' do

    before(:all) do
      Category.delete_all
      @cat1 = create_category()
      @cat2 = create_category(:name => 'OtherCategory')
      @cat2.archive
      @cat2.reload
      @cat3 = create_category(:name => 'Cat2')
      @active = [@cat1, @cat3]
      @inactive = [@cat2]
    end

    after(:all) do
      Category.delete_all
    end

    it_behaves_like 'active/inactive filter' do

      it 'cumulative filter active by default' do
        result = described_class.filtered(:name => 'Cat2')
        result.should match_array([@cat3])
      end

      it 'empty cumulative filter active by default' do
        result = described_class.filtered(:name => @cat2.name)
        result.should be_empty
      end

      it 'cumulative filter inactive' do
        result = described_class.filtered(:archived => true, :name => @cat2.name)
        result.should match_array([@cat2])
      end
    end
  end

  protected

  def create_category(options = nil)
    create(:category, options)
  end
end

