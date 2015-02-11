################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

require File.dirname(__FILE__) + '/../../spec_helper'

describe Request do
  before(:each) do
    #Notifier.stub(:delay).and_return(double('null object').as_null_object)
    @dest_mock = mock("destination")
    @dest_mock.stub(:publish).and_return(true)
    EventableStompletBinder.stub(:fetch).and_return(@dest_mock)
  end

  describe ".import" do
    describe "handle Deployment Windows while Export/Import requests" do
      let(:event) { create :deployment_window_event, :with_allow_series }
      let(:request){ create :request_with_app }
      let(:request_with_event) { create :request_with_app, deployment_window_event_id: event.id, estimate: 60, scheduled_at: event.start_at }
      let(:xml) {request.as_export_xml}
      let(:xml_with_event) {request_with_event.as_export_xml}

      pending "Can't mass-assign protected attributes: parent_request_id\n rank 3" do
        it "should import xml without deployment window" do
          xml_without_event = xml.sub(/<deployment-window-event-id.+\/deployment-window-event-id>/, '')
          expect(Request.import(xml_without_event)).to be_a_kind_of(Numeric)
        end

        it "should import xml with deployment window" do
          request_num = Request.import(xml_with_event)
          expect(Request.find_by_number(request_num).deployment_window_event).to eq event
        end

        it "should set event to nill if deployment window does not exist " do
          xml = xml_with_event
          event.destroy
          request_num = Request.import(xml)
          expect(Request.find_by_number(request_num).deployment_window_event_id).to be_nil
        end
      end
    end
  end
end
