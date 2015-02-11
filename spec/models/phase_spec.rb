################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

require 'spec_helper'


describe Phase do

  context 'general' do
    before(:each) do
      @phase = Phase.new
    end

    let(:Phase_with_ArchivableModelHelpers) {
      Phase.new do
        include Phase::ArchivableModelHelpers
      end
    }

    describe 'validations' do
      before(:each) { create(:phase) }
      it { @phase.should validate_presence_of(:name) }
      it { @phase.should validate_uniqueness_of(:name) }
    end

    it 'should have associations' do
      @phase.should have_many(:runtime_phases)
      @phase.should have_many(:steps)
    end

    it 'should have the scopes' do
      Phase.should respond_to(:filter_by_name)
      Phase.should respond_to(:in_order)
    end

    it { @phase.insertion_point.should == @phase.position }
  end

  describe '#filtered' do

    before(:all) do
      Phase.delete_all
      @phase1 = create_phase
      @phase2 = create_phase(:name => 'Archived Phase')
      @phase2.archive
      @phase2.reload
      @phase3 = create_phase(:name => 'Current Phase')
      @active = [@phase1, @phase3]
      @inactive = [@phase2]
    end

    after(:all) do
      Phase.delete_all
    end

    it_behaves_like 'active/inactive filter' do

      it 'cumulative filter active by default' do
        result = described_class.filtered(:name => 'Current Phase')
        result.should match_array([@phase3])
      end

      it 'empty cumulative filter active by default' do
        result = described_class.filtered(:name => @phase2.name)
        result.should be_empty
      end

      it 'cumulative filter inactive' do
        result = described_class.filtered(:archived => true, :name => @phase2.name)
        result.should match_array([@phase2])
      end
    end

  end

  protected

  def create_phase(options = nil)
    create(:phase, options)
  end

end


