################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

module ServiceNow
  class ChangeRequest < Handsoap::Service

    # This is not used. But still keep it to avoid exception written in handsoap libraries
    endpoint :uri => 'https://demo.service-now.com/change_request.do?SOAP', :version => 1

    attr_accessor :project_server_id, :attrs, :operation

    def initialize(params={})
      params.keys.each { |k| self.send("#{k}=".to_sym, params[k]) if self.respond_to?(k.to_sym) }
    end

    def uri
      full_url
    end

    # Handle HTTP basic authentication
    def on_after_create_http_request(http_request)
      project_server
      # beware the missing chomp, it will make you cry....
      auth = Base64.encode64("#{user}:#{password}").chomp
      http_request.set_header('authorization', "Basic #{auth}")
    end

    # Register namespaces for request
    def on_create_document(doc)
      doc.alias "#{operation}", "http://www.service-now.com/change_request"
    end

    # Register namespaces for response
    def on_response_document(doc)
      doc.add_namespace "#{operation}", "http://www.service-now.com/change_request"
    end

    def project_server
      @project_server = ProjectServer.find(project_server_id)
    end

    def base_url
      @project_server.server_url
    end

    def full_url
      "#{base_url}/change_request.do?SOAP"
    end

    def user
      @project_server.username
    end

    def password
      @project_server.password
    end

    def delete!
      submit! == "1" ? attrs["sys_id"] : nil
    end

    def submit!
      project_server
      response = invoke("#{operation}") do |message|
        # Build the body of the SOAP envelope
        attrs.keys.each do |name|
          message.add(name, attrs[name])
        end
      end
      xpath = case operation
        when "insert"; "//SOAP-ENV:Envelope/SOAP-ENV:Body/insertResponse/sys_id"
        when "update"; "//SOAP-ENV:Envelope/SOAP-ENV:Body/updateResponse/sys_id"
        when "deleteRecord"; "//SOAP-ENV:Envelope/SOAP-ENV:Body/deleteRecordResponse/count"
      end
      return Nokogiri::XML(response.http_response.body).xpath(xpath).text
    end
  end
end

