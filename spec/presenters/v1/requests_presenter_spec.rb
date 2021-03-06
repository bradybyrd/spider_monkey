################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

require 'spec_helper'

describe V1::RequestsPresenter do

  before :each do
    @user = create(:user)
    User.stub(:current_user) { @user }
    3.times { create(:request) }
    @resource = Request.all
    @presenter = V1::RequestsPresenter.new(@resource)
  end

  it 'should not be nil' do
    @presenter.should_not be_nil
    @presenter.resource.should == @resource
  end

  #it 'should respond to :to_json' do
  #  expect { @presenter.to_json }.to_not raise_error
  #end

  it 'should respond to :as_json' do
    expect { @presenter.as_json }.to_not raise_error
  end

  it 'should respond to :to_xml' do
    expect { @presenter.to_xml }.to_not raise_error
  end

end
