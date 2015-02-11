################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

require 'spec_helper'

describe EnvironmentType do
  context 'simple validations and associations' do

    before(:each) do
      @environment_type = build(:environment_type)
    end

    describe "associations" do
      it "should have many" do
        @environment_type.should have_many(:environments)
        @environment_type.should have_many(:plan_stages)
      end
    end

    describe "validations" do
      it { @environment_type.should validate_presence_of(:name) }
      it { @environment_type.should validate_presence_of(:label_color) }
      it { @environment_type.should ensure_inclusion_of(:label_color).in_array(Colors::Shades.map(&:last)) }
      it { @environment_type.should validate_uniqueness_of(:name) }
      it { @environment_type.should ensure_length_of(:name).is_at_most(255) }
      it { @environment_type.should ensure_length_of(:description).is_at_most(255) }
    end

    describe "attribute normalizations" do
      it { should normalize_attribute(:name).from('  Hello  ').to('Hello') }
      it { should normalize_attribute(:description).from('  Hello  ').to('Hello') }
    end

  end


  describe "custom validations" do
    before(:each) do
      @environment_type = create(:environment_type)
    end

    it "should not be valid if becoming strict with plan stage instances but allow other changes" do
      @environment_type.plan_stage_instances.count.should == 0
      @plan_stage = create(:plan_stage, :environment_type => @environment_type)
      @plan = create(:plan, :plan_template => @plan_stage.plan_template)
      @plan_stage_instance = PlanStageInstance.where(:plan_id => @plan.id, :plan_stage_id => @plan_stage.id).first
      @environment_type.plan_stage_instances.count.should == 1
      @environment_type.update_attributes(:strict => true)
      @environment_type.should_not be_valid
      @environment_type.update_attributes(:name => "Random New Name", :strict => false)
      @environment_type.should be_valid
    end

  end

  describe "acts_as_archival" do
    describe "should be archivable" do
      before(:each) do
        @environment_type = create(:environment_type)
      end
      it "should archive" do
        @environment_type.archived?.should be_falsey
        @environment_type.archive
        @environment_type.archived?.should be_truthy
      end

      it "should be immutable when archived" do
        @environment_type.archive
        @environment_type.name = 'Test Mutability'
        @environment_type.save.should be_falsey
      end

      it "should unarchive" do
        @environment_type.archive
        @environment_type.archived?.should be_truthy
        @environment_type.unarchive
        @environment_type.reload
        @environment_type.archived?.should be_falsey
        @environment_type.name = 'Test Mutability'
        @environment_type.save.should be_truthy
      end

      it "should have archival scopes" do
        @environment_type2 = create(:environment_type)
        @environment_type2.archive
        current_count = EnvironmentType.count
        EnvironmentType.archived.count.should == 1
        EnvironmentType.unarchived.count.should == current_count - 1
      end

      it "should not archive if has environment" do
        @environment = create(:environment)
        @environment_type.environments << @environment
        @environment_type.environments.count.should == 1
        current_count = EnvironmentType.unarchived.count
        results = @environment_type.archive
        results.should be_falsey
        EnvironmentType.unarchived.count.should == current_count
      end

    end
  end

  describe "should not be destroyable unless archived and free of associations" do

    before(:each) do
      @environment_type = create(:environment_type)
    end

    it "should not allow deletion if not archived" do
      current_count = EnvironmentType.count
      @environment_type.archived?.should be_falsey
      results = @environment_type.destroy
      results.should be_falsey
      EnvironmentType.count.should == current_count
    end

    it "should allow deletion if archived" do
      current_count = EnvironmentType.count
      @environment_type.archive
      @environment_type.archived?.should be_truthy
      results = @environment_type.destroy
      results.should be_truthy
      EnvironmentType.count.should == current_count - 1
    end

  end

  describe '#filtered' do

    before(:all) do
      EnvironmentType.delete_all
      @env_type_1 = create(:environment_type)
      @env_type_2 = create(:environment_type, :name => 'Another Environment Type')
      @env_type_2.archive
      @archived_name = @env_type_2.name
      @env_type_3 = create(:environment_type, :name => 'Default Environment Type')
      @active = [@env_type_1, @env_type_3]
      @inactive = [@env_type_2]
    end

    after(:all) do
      EnvironmentType.delete_all
    end

    it_behaves_like 'active/inactive filter' do

      it 'cumulative filter active by default' do
        result = described_class.filtered(:name => 'Default Environment Type')
        result.should match_array([@env_type_3])
      end

      it 'empty cumulative filter active by default' do
        result = described_class.filtered(:name => @archived_name)
        result.should be_empty
      end

      it 'cumulative filter inactive' do
        result = described_class.filtered(:archived => true)
        result.should match_array [@env_type_2]
      end
    end
  end

  describe "should provide convenience methods" do

    before(:each) do
      @strict_environment_type = build(:environment_type, strict: true)
      @open_environment_type = build(:environment_type, strict: false)
    end

    it "should provide a truncated short name" do
      @strict_environment_type.short_name.should == @strict_environment_type.name.truncate(30)
    end

    it "should provide a label qualified with strict if strict" do
      @strict_environment_type.label.should == @strict_environment_type.name.truncate(30) + ' (Strict)'
    end

    it "should provide a label unqualified if not strict" do
      @open_environment_type.label.should == @open_environment_type.name.truncate(30)
    end
  end

  describe "import_app method" do

    before(:each) do
      @env_type_name = "Productionesque"
      @env_type_hash = {"description" => "A default environment type.",
                        "label_color" =>"#FF0000",
                        "name" => @env_type_name,
                        "position" => 4,
                        "strict" => false}
    end

    it "should create a new env type from hash" do
      EnvironmentType.delete_all
      environment_type = EnvironmentType.import_app(@env_type_hash)
      environment_type.name.should == @env_type_name
      environment_type.should == EnvironmentType.find_by_name(@env_type_name)
    end
  end

end
