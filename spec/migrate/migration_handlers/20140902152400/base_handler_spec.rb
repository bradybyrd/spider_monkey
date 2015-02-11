require 'spec_helper'
require 'yaml'
require File.expand_path('../../../../../db/migration_handlers/20140902152400/base_handler', __FILE__)

describe BaseHandler do
  before do
    @handler = BaseHandler.new
  end

  describe "#to_role_name" do
    it "works properly" do
      @handler.to_role_name('deployment_coordinator').should == 'Coordinator'
      @handler.to_role_name('not_visible').should == 'Not Visible'
      @handler.to_role_name('user').should == 'User'
      @handler.to_role_name('requestor').should == 'Requestor'
      @handler.to_role_name('executor').should == 'Executor'
    end
  end

  describe "#to_old_role" do
    it "works properly" do
      @handler.to_old_role('Coordinator').should == 'deployment_coordinator'
      @handler.to_old_role('Not Visible').should == 'not_visible'
      @handler.to_old_role('User').should == 'user'
      @handler.to_old_role('Requestor').should == 'requestor'
      @handler.to_old_role('Executor').should == 'executor'
    end
  end
end