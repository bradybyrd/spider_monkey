################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

require 'spec_helper'
include RequestService

describe RequestStarter do
  let(:request) { build :request }

  it 'should use RequestPureStarter by default' do
    expect(RequestStarter.new(request).instance_variable_get(:@starter).class).to eq RequestPureStarter
  end

  describe '#within' do
    it 'should switch starter' do
      RequestInRunStarter.any_instance.should_receive(:start_request!)
      RequestStarter.new(request).within(:run).start_request!
    end
  end
end

describe RequestInRunStarter do
  let(:request) { create :request }
  let(:starter) {
    starter = RequestStarter.new(request)
    starter.within(:run)
    starter
  }

  specify { starter.should respond_to(:start_request!) }

  describe '#start_request!' do
    context 'on request successful #start!' do
      before do
        request.stub(:start!).and_return true
      end

      it 'should call #start_request! on request' do
        request.should_receive :start!
        starter.start_request!
      end

      it 'should clear #automatically_start_errors' do
        request.automatically_start_errors = 'define FALSE TRUE'
        starter.start_request!
        expect(request.automatically_start_errors).to be_nil
      end
    end

    context 'on request unsuccessful #start!' do
      before do
        request.stub(:start!).and_return false
        request.stub(:notice_messages).and_return 'define TRUE FALSE'
      end

      it 'should save errors to request #automatically_start_errors' do
        RequestPolicy::DeploymentWindowValidator::OpenedEnvironment.any_instance.stub(:requires_dwe_dependencies?).and_return(true)
        expect{starter.start_request!}.to change{request.automatically_start_errors}
      end
    end

  end
end

describe RequestPureStarter do
  let(:request) { build :request }
  let(:starter) {
    starter = RequestStarter.new(request)
    starter.within(:request)
    starter
  }

  specify { starter.should respond_to(:start_request!) }

  it 'should call #start_request! on request' do
    request.should_receive :start!
    starter.start_request!
  end
end
