################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

require 'spec_helper'

describe RequestFromEventPolicy do
  let(:request) { request = create :request }
  let(:valid_request) {
    request.stub(:valid?).and_return(true)
    request
  }
  let(:policy) { RequestFromEventPolicy.new valid_request }

  describe "#valid?" do
    it "should return false if application or estimate missed" do
      expect(policy.valid?).to eq false
    end

    it "should add application error to request" do
      policy.valid?
      expect(request.errors.messages[:base]).to include("Application can't be empty")
    end

    it "should add estimate error to request" do
      policy.valid?
      expect(request.errors.messages[:base]).to include("Estimate can't be empty")
    end

    context "valid" do
      let(:request) { create :request_with_app, estimate: 60 }
      it "should return true if application and estimate present" do
        expect(policy.valid?).to eq true
      end
    end
  end
end