################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

require 'spec_helper'

describe ListView do
  describe '#description' do
    let(:list_numi) { build :list, is_hash: false, is_text: false }
    let(:list_text) { build :list, is_hash: false, is_text: true }
    let(:list_hash) { build :list, is_hash: true, is_text: false }

    it 'should return text description for numi like lists' do
      list_numi.view_object.description.should eq '* List accepts integers only.'
    end

    it 'should return text description for text like lists' do
      list_text.view_object.description.should eq '* List accepts any string.'
    end

    it 'should return text description for hash like lists' do
      list_hash.view_object.description.should eq '* List accepts unique string as title and integer as a value.'
    end

  end
end

