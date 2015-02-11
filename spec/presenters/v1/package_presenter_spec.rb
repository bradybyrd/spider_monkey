################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

require 'spec_helper'

describe V1::PackagePresenter do
  it 'serializes the PackageInstance to json' do
    package = create(:package)
    application = create(:app)
    reference   = create(:reference)
    package.applications << application
    package.references << reference

    package_presenter = V1::PackagePresenter.new(package)

    package_json = package_presenter.as_json
    expect(package_json).to respond_to(:as_json)
    expect(package_json[:applications][0]["name"]).to eql(application.name)
    expect(package_json[:references][0]["name"]).to eql(reference.name)
  end
end

