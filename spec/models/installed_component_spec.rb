################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

require 'spec_helper'

describe InstalledComponent do

  context '' do
    before(:each) do
      User.current_user = User.find_by_login('admin')
      @installed_component = InstalledComponent.new
    end

    describe 'associations' do
      it 'should belong to' do
        @installed_component.should belong_to(:reference)
        @installed_component.should belong_to(:application_environment)
        @installed_component.should belong_to(:application_component)

      end

      it 'should have many ' do
        @installed_component.should have_many(:associated_current_property_values)
        @installed_component.should have_many(:associated_deleted_property_values)
        @installed_component.should have_many(:associated_property_values)
        @installed_component.should have_many(:steps)
      end

      it 'should have and belong to many' do
        @installed_component.should have_and_belong_to_many(:server_aspects)
        @installed_component.should have_and_belong_to_many(:servers)
        @installed_component.should have_and_belong_to_many(:server_aspect_groups)
      end

    end

    describe 'validations' do

      before(:each) do
      # uniqueness matcher needs one other record to test against
        @loaded_installed_component = create(:installed_component)
        @installed_component = InstalledComponent.new
      end

      it { @installed_component.should validate_presence_of(:application_component_id) }
      it { @installed_component.should validate_presence_of(:application_environment_id) }
      it { @installed_component.should validate_uniqueness_of(:application_component_id).scoped_to(:application_environment_id) }

    end

    describe 'mandatory name based lookups for REST' do

      before(:each) do
        @app = create(:app, :name => 'TBF_|_App To be Found')
        @environment = create(:environment, :name => 'TBF_|_Environment To be Found')
        @application_environment = create(:application_environment, :app => @app, :environment => @environment)
        @component = create(:component, :name => 'TBF_|_Component To be Found')
        @application_component = create(:application_component, :app => @app, :component => @component)
        @installed_component = create(:installed_component,
            :application_environment => @application_environment,
            :application_component => @application_component)
      end

      it 'should be valid if application, environment, and component names are all found' do
        @installed_component.should be_valid
        @installed_component.update_attributes( :app_name => 'TBF_|_App To be Found',
        :environment_name => 'TBF_|_Environment To be Found',
        :component_name => 'TBF_|_Component To be Found')
        @installed_component.should be_valid
      end

      it 'should be valid if the short form of the application name is used' do
        @installed_component.should be_valid
        @installed_component.update_attributes( :app_name => 'TBF',
        :environment_name => 'TBF_|_Environment To be Found',
        :component_name => 'TBF_|_Component To be Found')
        @installed_component.should be_valid
      end

      it 'should be invalid if application name is not found' do
        @installed_component.should be_valid
        @installed_component.update_attributes( :app_name => 'Something Else',
        :environment_name => 'TBF_|_Environment To be Found',
        :component_name => 'TBF_|_Component To be Found')
        @installed_component.should_not be_valid

      end

      it 'should be invalid if environment name is not found' do
        @installed_component.should be_valid
        @installed_component.update_attributes( :app_name => 'TBF_|_App To be Found',
        :environment_name => 'Something Else',
        :component_name => 'TBF_|_Component To be Found')
        @installed_component.should_not be_valid
      end

      it 'should be invalid if component name is not found' do
        @installed_component.should be_valid
        @installed_component.update_attributes( :app_name => 'TBF_|_App To be Found',
        :environment_name => 'TBF_|_Environment To be Found',
        :component_name => 'Something Else')
        @installed_component.should_not be_valid
      end
    end

    describe 'server lookups for REST' do

      before(:each) do
        @installed_component = create(:installed_component)
        # assign a default to be sure the types are switching properly
        @default_server = create(:server)
        @installed_component.update_attributes( :server_names => [@default_server.name] )
      end

      it 'should assign a server when passed a server name' do
        @server = create(:server)
        @installed_component.update_attributes( :server_names => [@server.name] )
        @installed_component.should be_valid
        @installed_component.servers.should include(@server)
        @installed_component.server_group.should be_nil
        @installed_component.server_aspect_groups.should be_empty
        @installed_component.server_aspects.should be_empty
      end

      it 'should be invalid if given a bad server name' do
        @server = create(:server)
        @installed_component.update_attributes( :server_names => ['Does not exist'] )
        @installed_component.should_not be_valid
        @installed_component.servers.should_not include(@server)
        @installed_component.servers.should include(@default_server)
        @installed_component.server_group.should be_nil
        @installed_component.server_aspect_groups.should be_empty
        @installed_component.server_aspects.should be_empty
      end

      it 'should assign a server group when passed a server group name' do
        @server_group = create(:server_group)
        @installed_component.update_attributes( :server_group_name => [@server_group.name] )
        @installed_component.should be_valid
        @installed_component.servers.should be_empty
        @installed_component.server_group.should == @server_group
        @installed_component.server_aspect_groups.should be_empty
        @installed_component.server_aspects.should be_empty
      end

      it 'should be invalid if given a bad server group name' do
        @server_group = create(:server_group)
        @installed_component.update_attributes( :server_group_name => ['Does not exist'] )
        @installed_component.should_not be_valid
        @installed_component.servers.should include(@default_server)
        @installed_component.server_group.should be_nil
        @installed_component.server_aspect_groups.should be_empty
        @installed_component.server_aspects.should be_empty
      end

      it 'should assign a server aspect when passed a server aspect name' do
        @server_aspect = create(:server_aspect)
        @installed_component.update_attributes( :server_aspect_names => [@server_aspect.name] )
        @installed_component.should be_valid
        @installed_component.servers.should be_empty
        @installed_component.server_group.should be_nil
        @installed_component.server_aspect_groups.should be_empty
        @installed_component.server_aspects.should include(@server_aspect)
      end

      it 'should be invalid if given a bad server aspect name' do
        @server_aspect = create(:server_aspect)
        @installed_component.update_attributes( :server_aspect_names => ['Does not exist'] )
        @installed_component.should_not be_valid
        @installed_component.servers.should include(@default_server)
        @installed_component.server_group.should be_nil
        @installed_component.server_aspect_groups.should be_empty
        @installed_component.server_aspects.should be_empty
      end

      it 'should assign a server aspect when passed a server aspect group name' do
        @server_aspect_group = create(:server_aspect_group)
        @installed_component.update_attributes( :server_aspect_group_names => [@server_aspect_group.name] )
        @installed_component.should be_valid
        @installed_component.servers.should be_empty
        @installed_component.server_group.should be_nil
        @installed_component.server_aspect_groups.should include(@server_aspect_group)
        @installed_component.server_aspects.should be_empty
      end

      it 'should be invalid if given a bad server aspect group name' do
        @server_aspect_group = create(:server_aspect_group)
        @installed_component.update_attributes( :server_aspect_group_names => ['Does not exist'] )
        @installed_component.should_not be_valid
        @installed_component.servers.should include(@default_server)
        @installed_component.server_group.should be_nil
        @installed_component.server_aspect_groups.should be_empty
        @installed_component.server_aspects.should be_empty
      end

    end

    describe 'property assignments for REST' do

      before(:each) do
        @installed_component = create(:installed_component)
        @property = create(:property)
        @installed_component.component.properties << @property
      end

      it 'should assign a property value when passed a key value pair' do
        @installed_component.update_attributes( :properties_with_values => { @property.name => 'Sample value' } )
        @installed_component.should be_valid
        @installed_component.properties.should include(@property)
        @installed_component.associated_current_property_values.first.value.should == 'Sample value'
      end

      it 'should reject non-existant property names' do
        @installed_component.update_attributes( :properties_with_values => { 'Does Not Exist' => 'Sample value' } )
        @installed_component.should_not be_valid
        @installed_component.associated_current_property_values.should be_empty
      end

    end
  end

  describe '#filtered' do

    before(:all) do
      InstalledComponent.delete_all

      @app = []
      @env = []
      @comp = []
      (1..2).each do |i|
        @app[i] = create(:app, :name => "App #{i}")
        @env[i] = create(:environment, :name => "Env #{i}")
        @comp[i] = create(:component, :name => "Comp #{i}")
      end

      @ac = []
      @ae = []
      (1..2).each do |i|
        @ac[i] = []
        @ae[i] = []
        (1..2).each do |j|
          @ac[i][j] = create(:application_component, :app => @app[i], :component => @comp[j])
          @ae[i][j] = create(:application_environment, :app => @app[i], :environment => @env[j])
        end
      end

      #@test = create(:installed_component, :application_component => @ac[1][1], :application_environment => @ae[2][1])

      @ic_ace = []
      (1..2).each do |i|
        @ic_ace[i] = []
        (1..2).each do |j|
          @ic_ace[i][j] = []
          (1..2).each do |k|
            @ic_ace[i][j][k] = create(:installed_component, :application_component => @ac[i][j], :application_environment => @ae[i][k])
          end
        end
      end
      @srv = create(:server, :name => 'Server 1')
      @sg = create(:server_group, :name => 'Server Group 1', :servers => [@srv], :environments => [@env[1]])
      #@ic_ace[2][2][1].update_attribute(server_group_name, @sg.name)
      @ic_ace[2][2][1].update_attribute(:server_group, @sg)
    end

    after(:all) do
      InstalledComponent.delete_all
      ServerGroup.delete(@sg)
      Server.delete(@srv)
      ApplicationEnvironment.delete(@ae.flatten)
      ApplicationComponent.delete(@ac.flatten)
      Component.delete(@comp)
      Environment.delete(@env)
      App.delete(@app)
    end

    describe 'filter by default' do
      subject { described_class.filtered }
      it { should match_array(@ic_ace.flatten.compact) }
    end

    describe 'filter by app_id, component_id, environment_id' do
      subject { described_class.filtered(:app_id => @app[1].id,
                                         :component_id => @comp[1].id,
                                         :environment_id => @env[1].id) }
      it { should match_array([@ic_ace[1][1][1]]) }
    end

    describe 'filter by app_name, component_name, environment_name' do
      subject { described_class.filtered(:app_name => @app[2].name,
                                         :component_name => @comp[2].name,
                                         :environment_name => @env[2].name) }
      it { should match_array([@ic_ace[2][2][2]]) }
    end

    describe 'filter(empty) by app_id != app_name' do
      subject { described_class.filtered(:app_id => @app[1].id, :app_name => @app[2].name) }
      it { should be_empty }
    end

    describe 'filter(empty) by component_id != component_name' do
      subject { described_class.filtered(:component_id => @comp[1].id, :component_name => @comp[2].name) }
      it { should be_empty }
    end

    describe 'filter(empty) by environment_id != environment_name' do
      subject { described_class.filtered(:environment_id => @env[1].id, :environment_name => @env[2].name) }
      it { should be_empty }
    end

    describe 'filter by server_group_name' do
      subject { described_class.filtered(:server_group_name => 'Server Group 1') }
      it { should match_array([@ic_ace[2][2][1]]) }
    end

    describe 'filter(empty) by server_group_name' do
      subject { described_class.filtered(:server_group_name => 'Server Group 2') }
      it { should be_empty }
    end
  end

  protected

  def create_installed_component(options = nil)
    create(:installed_component, options)
  end

end

