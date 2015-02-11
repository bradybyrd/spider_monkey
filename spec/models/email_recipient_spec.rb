################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

require 'spec_helper'

describe EmailRecipient do
  before(:each) do
    @email_recipient = EmailRecipient.new
  end

  describe "validations" do

    it { @email_recipient.should validate_presence_of(:request) }
    it { @email_recipient.should validate_presence_of(:recipient) }
  end

  describe "associations" do
    it { @email_recipient.should belong_to(:request) }
    it { @email_recipient.should belong_to(:recipient) }
  end

end

