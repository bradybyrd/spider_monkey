################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe PackageTemplateComponent do
  describe 'associations' do
    it 'should belong to' do
      @package_template_component = PackageTemplateComponent.create
      @package_template_component.should belong_to(:package_template_item)
      @package_template_component.should belong_to(:application_component)
    end
  end
end

