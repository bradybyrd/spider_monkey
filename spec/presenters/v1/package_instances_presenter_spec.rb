################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

require 'spec_helper'

describe V1::PackageInstancesPresenter do
  it 'serializes the PackageInstance to json' do
    package_instance = create(:package_instance)
    presenter = V1::PackageInstancesPresenter.new(package_instance)
    expect(presenter).to respond_to(:as_json)
  end
end

