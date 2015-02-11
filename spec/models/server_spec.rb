################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

require 'spec_helper'

describe Server do
  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:name) }
    it { should ensure_length_of(:name).is_at_most(255) }
    it 'validates permissions per environment', custom_roles: true do
      should validate_permissions_per_environments
    end
  end

  describe "attribute normalizations" do
    it { should normalize_attribute(:name).from('  Hello  ').to('Hello') }
  end

  describe "associations" do
    it { should have_many(:environment_servers) }
    it { should have_many(:environments).through(:environment_servers) }
    it { should have_many(:application_environments).through(:environments) }
    it { should have_many(:assigned_apps).through(:application_environments) }

    it { should have_many(:server_aspects) }
    it { should have_many(:property_values) }
    it { should have_many(:current_property_values) }
    it { should have_many(:deleted_property_values) }

    it { should have_and_belong_to_many(:server_groups) }
    it { should have_and_belong_to_many(:installed_components) }
    it { should have_and_belong_to_many(:properties) }
  end

  describe '#filtered' do

    before(:all) do
      Server.delete_all
      @server1 = create_server(:active => true)
      @server2 = create_server(:active => false, :name => 'Dev')
      @server3 = create_server(:active => true, :name => 'Staging')
      @active = [@server1, @server3]
      @inactive = [@server2]
    end

    after(:all) do
      Server.delete_all
    end

    it_behaves_like 'active/inactive filter' do

      it 'cumulative filter active by default' do
        result = described_class.filtered(:name => 'Staging')
        result.should match_array([@server3])
      end

      it 'empty cumulative filter active by default' do
        result = described_class.filtered(:name => 'Dev')
        result.should be_empty
      end

      it 'cumulative filter inactive' do
        result = described_class.filtered(:inactive => true, :name => 'Dev')
        result.should match_array([@server2])
      end
    end

  end

  describe "when removing association with a environment" do

    before(:each) do
      @environment = create(:environment)
      @server = create(:server, environments: [@environment])
      @app = create(:app)
      @app.environments << @environment
      @app.reload

      #@server.environments << @environment
      #@server.reload
    end

    it "should allow removal of server with no package references" do
      expect{
        @server.update_attribute :environments, []
      }.to change{
        @server.environments.count
      }.from(1).to(0)
    end

    it "should prevent removal from environment with package reference to server" do
      package = create( :package )
      reference = create( :reference, package: package, server: @server )
      @app.packages << package
      expect{
        @server.update_attribute :environments, []
      }.to raise_exception( ActiveRecord::RecordInvalid )
    end
  end
  protected

  def create_server(options = nil)
    create(:server, options)
  end
end
