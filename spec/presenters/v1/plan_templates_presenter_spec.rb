################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

require 'spec_helper'

describe V1::PlanTemplatesPresenter do

  before :each do
    3.times { create(:plan_template) }
    @resource = PlanTemplate.all
    @presenter = V1::PlanTemplatesPresenter.new(@resource)
  end

  it 'should not be nil' do
    @presenter.should_not be_nil
    @presenter.resource.should == @resource
  end

  it 'should respond to :as_json' do
    expect { @presenter.as_json }.to_not raise_error
  end

  it 'should respond to :to_xml' do
    expect { @presenter.to_xml }.to_not raise_error
  end

end
