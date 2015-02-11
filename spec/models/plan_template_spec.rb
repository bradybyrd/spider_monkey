################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################
require 'spec_helper'


describe PlanTemplate do

  describe "validations" do

    before(:each) do
      @plan_template = create(:plan_template)
    end

    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:name).case_insensitive }
    it { should ensure_length_of(:name).is_at_most(255)}

    it { PlanTemplate::TYPES.each do |value|
      should allow_value(value[1]).for(:template_type)
    end }

    it "should allow deletion if it has no plans" do
      @plan_template.plans.count.should == 0
      PlanTemplate.count.should == 1
      @plan_template.delete
      PlanTemplate.count.should == 0
      @plan_template.errors[:plans].should be_empty
    end

  end

  describe "attribute normalizations" do
    it { should normalize_attribute(:name).from('  Hello  ').to('Hello') }
  end

  describe "named scopes" do
    describe "#name_order" do
      it "should return all plan templates in name order" do
        plan_template = create(:plan_template, :name => "Zanado")
        plan_template2 = create(:plan_template, :name => "Abracadabra")
        PlanTemplate.name_order.last.should == plan_template
        PlanTemplate.name_order.first.should == plan_template2
      end
    end

    describe "#having_template_types" do
      it "should return all plan templates for one or more templates" do
        plan_template1 = create(:plan_template, :template_type => "deploy")
        plan_template2 = create(:plan_template, :template_type => "deploy")
        plan_template3 = create(:plan_template, :template_type => "continuous_integration")
        plan_template4 = create(:plan_template, :template_type => "release_plan")
        PlanTemplate.having_template_types("deploy").count.should == 2
        PlanTemplate.having_template_types(["deploy","release_plan"]).count.should == 3
      end
    end
  end

  describe "custom accessors" do
    describe "default_stage_id" do
      before (:each) do
        @plan_template = create(:plan_template)
        @stage1 = create(:plan_stage, :plan_template => @plan_template, :position => 2)
        @stage2 = create(:plan_stage, :plan_template => @plan_template, :position => 1)
      end
      it "should return the first id of the stage based on the position field" do
        @plan_template.default_stage_id.should == @stage2.id
      end
    end

    describe "template_type_label" do
      it "should return the label field for the template value" do
        @plan_template = create(:plan_template, :template_type => 'deploy')
        @plan_template.template_type_label.should == 'Deploy'
        @plan_template.update_attributes(:template_type => 'continuous_integration')
        @plan_template.template_type_label.should == 'Continuous Integration'
        @plan_template.update_attributes(:template_type => 'release_plan')
        @plan_template.template_type_label.should == 'Release Plan'
        @plan_template.update_attributes(:template_type => 'not_to_be_found')
        @plan_template.template_type_label.should == 'Unsupported type: not_to_be_found'
      end
    end
  end

  describe '#filtered' do

    before(:all) do
      PlanTemplate.delete_all
      @pt1 = create(:plan_template)
      @pt2 = create(:plan_template, name: 'Old Plan Template')
      @pt2.archive
      # Name has been changed during arcivation
      @pt2.reload
      @pt3 = create(:plan_template, name: 'New Plan Template')
      @active = [@pt1, @pt3]
      @inactive = [@pt2]
    end

    after(:all) do
      PlanTemplate.delete_all
    end

    it_behaves_like 'active/inactive filter' do

      it 'cumulative filter active by default' do
        result = described_class.filtered(:name => 'New Plan Template')
        result.should match_array([@pt3])
      end

      it 'empty cumulative filter active by default' do
        result = described_class.filtered(:name => 'Old Plan Template')
        result.should be_empty
      end

      it 'cumulative filter inactive' do
        result = described_class.filtered(:archived => true, :name => @pt2.name)
        # cause archived name looks like 'Pt [archived ...]' and ProjectTemplate filter by name  is 'name LIKE ?' not 'name LIKE ?%'
        result.should =~ [@pt2]
      end
    end

  end

end
