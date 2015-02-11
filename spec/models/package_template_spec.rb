################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

require 'spec_helper'

describe PackageTemplate do

  before(:each) do
    User.current_user = User.find_by_login('admin')
    @app1 = create(:app)
  end

  describe 'validations' do
    it 'validates presence of' do
      @package_template1 = create(:package_template, :app_id => @app1.id, :name => 'pt001', :version => 0)
      @package_template1.should be_valid
      @package_template1.should validate_presence_of(:app_id)
      @package_template1.should validate_presence_of(:name)
      @package_template1.should validate_presence_of(:version)

    end

  end

  describe 'associations' do
    it 'belongs to' do
      @package_template1 = create(:package_template, :app_id => @app1.id, :name => 'pt003', :version => 0)
      @package_template1.should belong_to(:app)
    end

    it 'has many' do
      @package_template1 = create(:package_template, :app_id => @app1.id, :name => 'pt004', :version => 0)
      @package_template1.should have_many(:package_template_items)
      @package_template1.should have_many(:steps)
    end


  end

end

