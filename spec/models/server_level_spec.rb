################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ServerLevel do

  before(:all) do
    create(:server_level)
  end
  after(:all) { cleanup_models }

  before(:each) do
    @server_level = create(:server_level)
  end

  it { @server_level.should have_many(:server_aspects) }
  it { @server_level.should validate_presence_of(:name) }
  it { @server_level.should validate_uniqueness_of(:name) }

  describe '#has_server_aspects?' do
    before do
      @server_level.name = 'Virtual Servers'
      @server_level.save!
    end

    it 'should be true when it has saved server aspects associated with it' do
      @server_level.server_aspects << ServerAspect.create!(:name => 'aspect', :parent => ServerAspect.new)
      @server_level.has_server_aspects?.should be_truthy
    end

    it 'should be false when it has server aspects associated with it but none is saved' do
      @server_level.server_aspects << ServerAspect.new
      @server_level.server_aspects.should_not be_empty
      @server_level.has_server_aspects?.should be_falsey
    end

    it 'should be false when there are no server aspects' do
      @server_level.server_aspects.should be_empty
      @server_level.has_server_aspects?.should be_falsey
    end
  end

  describe '#potential_parents' do
    it 'should return all active servers and server groups when this server level is first' do
      @server_level.stub(:first?).and_return(true)
      Server.stub(:active).and_return('all active servers')
      ServerGroup.stub(:active).and_return(' and all active server groups')
      @server_level.potential_parents.should == 'all active servers and all active server groups'
    end

    it "should return the higher list item's server aspects and potential parents otherwise" do
      @server_level.stub(:first?).and_return(false)
      @server_level.stub(:higher_item).and_return(mock('higher level', :server_aspects => 'higher server aspects', :potential_parents => ' and potential parents'))
      @server_level.potential_parents.should == 'higher server aspects and potential parents'
    end
  end

  describe '#grouped_potential_parents' do
    it 'is an array of arrays grouping name-ordered servers/aspects by their levels' do
      server = create(:server)
      server_level = create(:server_level, name: 'Virtual Servers')
      server_aspect = create(:server_aspect, server_level: server_level, parent: server)
      server_aspect2 = create(:server_level)
      server.reload
      server_level.reload
      server_aspect.reload
      server_aspect2.reload
      pending 'failing randomly when running the whole test suite'
      expect(server_aspect2.grouped_potential_parents).to include ['Virtual Servers', [server_level]]
    end
  end

  describe '#underscored_name' do
    it 'should return the name fully underscored' do
      @server_level.name = 'The Name    Of the THING'
      @server_level.underscored_name.should == 'the_name_of_the_thing'
    end

    it 'should replace all non-word characters with underscores' do
      @server_level.name = 'Foo;  bar, hello!1'
      @server_level.underscored_name.should == 'foo_bar_hello_1'
    end
  end

end

