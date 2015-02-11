################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

require 'spec_helper'

describe ExtendedAttribute do
  before do
    @extended_attribute = create(:extended_attribute)
  end
  it { @extended_attribute.should belong_to(:value_holder)}
  it { @extended_attribute.should validate_presence_of(:name) }
  it { @extended_attribute.should validate_uniqueness_of(:name).scoped_to(:value_holder_id, :value_holder_type) }
end

