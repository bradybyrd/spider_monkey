################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

require 'spec_helper'

describe V1::AbstractPresenter do

  describe "presenter for single models" do

    before :each do
      @resource = create(:work_task)
      @presenter = V1::AbstractPresenter.new(@resource)
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

    #it 'by default it should equal the default model version of :to_json' do
    #  @presenter.to_json.should == @resource.to_json
    #end

    it 'by default it should equal the default model version of :as_json' do
      @presenter.as_json.should == @resource.as_json
    end

    it 'by default it should equal the default model version of :to_xml' do
      @presenter.to_xml.should == @resource.to_xml
    end

  end

  describe "presenter for collections" do

    before :each do
      3.times { create(:work_task) }
      @resource = WorkTask.all
      @presenter = V1::AbstractPresenter.new(@resource)
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

    #it 'by default it should equal the default model version of :to_json' do
    #  @presenter.to_json.should == @resource.to_json
    #end

    it 'by default it should equal the default model version of :as_json' do
      arr = Array.new
      @resource.each do |res_elem|
        arr.push(res_elem.as_json)
      end
      @presenter.as_json.should == arr
    end

    it 'by default it should equal the default model version of :to_xml' do
      @presenter.to_xml.should == @resource.to_xml
    end

  end
end
