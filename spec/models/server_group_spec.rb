################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

require 'spec_helper'


describe ServerGroup do

  context '' do
    before(:each) do
      @server_group = ServerGroup.create(:name => "sg001")
    end

    describe "associations" do
      it { @server_group.should have_and_belong_to_many(:servers) }
      it { @server_group.should have_many(:environments) }
      it { @server_group.should have_many(:server_aspects) }
    end

    describe "validations" do
      it { @server_group.should validate_presence_of(:name) }
      it { @server_group.should validate_uniqueness_of(:name) }
    end

    describe "normalizations" do
      it { should normalize_attribute(:name).from('  Hello  ').to('Hello') }
    end

    describe "named scopes" do
      it "active" do
        @server_group2 = create(:server_group, :name => "sg002", :active => true)
        @server_group3 = create(:server_group, :name => "sg003", :active => false)
        ServerGroup.active.should include(@server_group2)
        ServerGroup.active.should_not include(@server_group3)

      end

      it "inactive" do
        @server_group2 = create(:server_group, :name => "sg002", :active => true)
        @server_group3 = create(:server_group, :name => "sg003", :active => false)
        ServerGroup.inactive.should_not include(@server_group2)
        ServerGroup.inactive.should include(@server_group3)
      end
    end
  end

  describe '#filtered' do

    before(:all) do
      ServerGroup.delete_all
      @srv_grp1 = create_server_group(:active => true)
      @srv_grp2 = create_server_group(:active => false, :name => 'Old Servers')
      @srv_grp3 = create_server_group(:active => true, :name => ' New Servers')
      @active = [@srv_grp1, @srv_grp3]
      @inactive = [@srv_grp2]
    end

    after(:all) do
      ServerGroup.delete_all
    end

    it_behaves_like 'active/inactive filter' do

      it 'cumulative filter active by default' do
        result = described_class.filtered(:name => 'New Servers')
        result.should match_array([@srv_grp3])
      end

      it 'empty cumulative filter active by default' do
        result = described_class.filtered(:name => 'Old Servers')
        result.should be_empty
      end

      it 'cumulative filter inactive' do
        result = described_class.filtered(:inactive => true, :name => 'Old Servers')
        result.should match_array([@srv_grp2])
      end
    end

  end

  protected

  def create_server_group(options = nil)
    create(:server_group, options)
  end

end
