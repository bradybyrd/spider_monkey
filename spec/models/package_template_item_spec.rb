################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe PackageTemplateItem do
  before(:each) do
    @package_template_item1 = PackageTemplateItem.new
  end

  describe 'associations' do

    it 'should belong to' do
      @package_template_item1.should belong_to(:component_template)
      @package_template_item1.should belong_to(:package_template)
    end

    it 'should have many' do
      @package_template_item1.should have_many(:package_template_components)
      @package_template_item1.should have_many(:application_components)
    end

  end

  describe 'validations' do

    it 'should validate presence of' do
      @package_template_item1.should validate_presence_of(:package_template_id)
      @package_template_item1.should validate_presence_of(:name)
      @package_template_item1.should validate_presence_of(:item_type)
    end

  end

end

