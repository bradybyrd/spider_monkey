################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

require 'spec_helper'


describe Release do

  context '' do
    before(:all) do
      @release = Release.new
    end

    let(:Release_with_ArchivableModelHelpers) {
      Release.new do
        include Release::ArchivableModelHelpers
      end
    }

    describe "validations" do
      it { @release.should validate_presence_of(:name) }
    end

    describe "named scopes" do
      it { Release.should respond_to :in_order }
      it { Release.should respond_to :name_order }
      it { Release.should respond_to :filter_by_name }
    end

    describe "methods" do
      it "should have insertion_point" do
        @release.insertion_point.should == @release.position
      end
    end

    describe "associations" do
      it { @release.should have_many(:requests) }
      it { @release.should have_many(:plans) }
    end
  end

  describe '#filtered' do

    before(:all) do
      Release.delete_all
      @release1 = create_release()
      @release2 = create_release(:name => 'Archived Release')
      @release2.archive
      @release2.reload
      @release3 = create_release(:name => 'New Release')
      @active = [@release1, @release3]
      @inactive = [@release2]
    end

    after(:all) do
      Release.delete_all
    end

    it_behaves_like 'active/inactive filter' do

      it 'cumulative filter active by default' do
        result = described_class.filtered(:name => 'New Release')
        result.should match_array([@release3])
      end

      it 'empty cumulative filter active by default' do
        result = described_class.filtered(:name => @release2.name)
        result.should be_empty
      end

      it 'cumulative filter inactive' do
        result = described_class.filtered(:archived => true, :name => @release2.name)
        result.should match_array([@release2])
      end
    end

  end

  protected

  def create_release(options = nil)
    create(:release, options)
  end

end



