################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

require 'spec_helper'


describe ProjectServer do

  describe '#server_type' do
    it 'returns the server type' do
      hudson_server_key = 5
      project_server = create_project_server(server_name_id: hudson_server_key)

      expect(project_server.server_type).to eq 'Hudson/Jenkins'
    end
  end

  describe '#filtered' do

    before(:all) do
      ProjectServer.delete_all
      @ps1 = create_project_server()
      @ps2 = create_project_server(:name => 'Old Project Server', :is_active => false)
      @ps3 = create_project_server(:name => 'New Project Server')
      @active = [@ps1, @ps3]
      @inactive = [@ps2]
      @filter_flags = [:active, :inactive]
    end

    after(:all) do
      ProjectServer.delete_all
    end

    it_behaves_like 'active/inactive filter' do

      it 'cumulative filter active by default' do
        result = described_class.filtered(:name => 'New Project Server')
        result.should match_array([@ps3])
      end

      it 'empty cumulative filter active by default' do
        result = described_class.filtered(:name => 'Old Project Server')
        result.should be_empty
      end

      it 'cumulative filter inactive' do
        result = described_class.filtered(:inactive => true, :name => 'Old Project Server')
        result.should match_array([@ps2])
      end
    end

  end

  protected

  def create_project_server(options = nil)
    create(:project_server, options)
  end

end

