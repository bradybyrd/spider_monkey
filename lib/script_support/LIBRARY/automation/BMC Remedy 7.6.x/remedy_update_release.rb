###
# adapter_name:
#   name: Remedy Actor Adapter
#   required: yes
#   position: A1:B1
# release_id:
#   name: Release Id [Leave Blank to auto-pick from lifecycle]
#   position: A2:B2
# summary:
#   name: Summary
#   position: A3:B3
# notes:
#   name: Notes
#   position: A4:B4
# business_justification:
#   name: Business Justification
#   type: in-external-single-select
#   external_resource: remedy_release_business_justifications
#   position: A5:B5
# impact:
#   name: Impact
#   type: in-external-single-select
#   external_resource: remedy_change_request_impacts
#   position: A6:B6
# urgency:
#   name: Urgency
#   type: in-external-single-select
#   external_resource: remedy_change_request_urgencies
#   position: A7:B7
# risk_level:
#   name: Risk Level
#   type: in-external-single-select
#   external_resource: remedy_release_risk_levels
#   position: D1:E1
# company:
#   name: Company
#   type: in-external-single-select
#   external_resource: remedy_customer_companies
#   position: D2:E2
# status:
#   name: Status
#   type: in-external-single-select
#   external_resource: remedy_release_statuses
#   position: D3:E3
# status_reason:
#   name: Status Reason
#   type: in-external-single-select
#   external_resource: remedy_release_status_reasons
#   position: D4:E4
# release_type:
#   name: Release Type
#   type: in-external-single-select
#   external_resource: remedy_release_release_types
#   position: D5:E5
# target_date:
#   name: Target Date
#   type: in-datetime
#   position: D6:E6
# completed_date:
#   name: Completed Date
#   type: in-datetime
#   position: D7:E7
# Entries updated:
#   name: Entries updated
#   type: out-text
#   position: A1:B1
###

begin
  require 'yaml'
  require 'savon'
  require 'date'
  require 'json'
  require 'rest-client'

  params["direct_execute"]=true

  if [params["release_id"],params["summary"],params["notes"],params["business_justification"],params["impact"],params["urgency"],params["risk_level"],params["milestone"],params["status"],params["status_reason"],params["release_type"],params["target_date"],params["completed_date"]].all? {|p| p.blank?}
    write_to("No change found. Please provide at least one field to update.")
  else
    ao_config = YAML.load(SS_integration_details)
    integration_password_dec = decrypt_string_with_prefix(SS_integration_password_enc)
    process_name = ":BRPM_Remedy_Change_Management:Update Remedy Entity"

    def seconds_since_epoch(time = Time.now)
      time = Time.parse(time) if time.is_a? String
      time.strftime("%s")
    end

    if params["release_id"].blank?
      unless params["request_plan_id"].blank?
        begin
          response = RestClient.get "#{params["SS_base_url"]}/v1/plans/#{params["request_plan_id"]}?token=#{params["SS_api_token"]}", :accept => :json
          plan = JSON.parse(response)
          params["release_id"] = plan["foreign_id"]
        rescue Exception => e
          write_to "Operation failed: Could not fetch plan details for #{params["request_plan_id"]}, error: #{e.message}"
          exit(1)
        end
      end

      if params["release_id"].blank?
        write_to("Operation failed: No valid release ticket id could be determined (or provided)")
        exit(1)
      end
    end

    namespaces = { "xmlns:soapenv" => "http://schemas.xmlsoap.org/soap/envelope/", "xmlns:soa" => "http://bmc.com/ao/xsd/2008/09/soa" }
    client = Savon.client(SS_integration_dns)
    response = client.request :execute_process do
      soap.xml do |xml|
        xml.soapenv(:Envelope, namespaces) do |xml|
          xml.soapenv(:Header) do |xml|
            xml.wsse(:Security, "soapenv:mustUnderstand" => "1", "xmlns:wsse" => "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd") do |xml|
              xml.wsse(:UsernameToken) do |xml|
                xml.wsse(:Username, SS_integration_username)
                xml.wsse(:Password, integration_password_dec, "Type" => "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordText")
              end
            end
          end
          xml.soapenv(:Body) do |xml|
            xml.soa(:executeProcess) do |xml|
              xml.soa(:gridName, ao_config["grid_name"])
              xml.soa(:moduleName, ao_config["module_name"])
              xml.soa(:processName, process_name)
              xml.soa(:parameters) do |xml|
                xml.soa(:Input) do |xml|

                  xml.soa(:Parameter) do |xml|
                    xml.soa(:Name, "form name", :required => true)
                    xml.soa(:Value, "soa:type" => "xs:string") do |xml|
                      xml.soa(:Text, "RMS:ReleaseInterface")
                    end
                  end

                  xml.soa(:Parameter) do |xml|
                    xml.soa(:Name, "filter string", :required => true)
                    xml.soa(:Value, "soa:type" => "xs:string") do |xml|
                      xml.soa(:Text, "'ReleaseID'=\"#{params["release_id"]}\"")
                    end
                  end

                  xml.soa(:Parameter) do |xml|
                    xml.soa(:Name, "fields xml", :required => true)
                    xml.soa(:Value, "soa:type" => "xs:anyType") do |xml|
                      xml.soa(:XmlDoc) do |xml|
                        xml.fields do |xml|
                          xml.field(params["release_id"], :name => "ReleaseID") unless params["release_id"].blank?
                          xml.field(params["summary"], :name => "Description") unless params["summary"].blank?
                          xml.field(params["notes"], :name => "Detailed Description") unless params["notes"].blank?
                          xml.field(params["business_justification"], :name => "Business Justification") unless params["business_justification"].blank?
                          xml.field(params["impact"], :name => "Impact") unless params["impact"].blank?
                          xml.field(params["urgency"], :name => "Urgency") unless params["urgency"].blank?
                          xml.field(params["risk_level"], :name => "Risk Level") unless params["risk_level"].blank?
                          xml.field(params["milestone"], :name => "z1D Milestone") unless params["milestone"].blank?
                          xml.field(params["status"], :name => "z1D Status") unless params["status"].blank?
                          xml.field(params["status_reason"], :name => "z1D Status Reason") unless params["status_reason"].blank?
                          xml.field(params["release_type"], :name => "Release Type") unless params["release_type"].blank?
                          xml.field(seconds_since_epoch(params["target_date"]), :name => "Target Date") unless params["target_date"].blank?
                          xml.field(seconds_since_epoch(params["completed_date"]), :name => "Completed Date") unless params["completed_date"].blank?
                        end
                      end
                    end
                  end

                  xml.soa(:Parameter) do |xml|
                    xml.soa(:Name, "remedy actor adapter name")
                    xml.soa(:Value, "soa:type" => "xs:string") do |xml|
                      xml.soa(:Text, params["adapter_name"])
                    end
                  end

                end
              end
            end
          end
        end
      end
    end

    write_to("------------ Output ----------------------")
    completion_code = response.body[:execute_process_response][:output][:output][:parameter][0][:value][:xml_doc][:value]
    completion_string = response.body[:execute_process_response][:output][:output][:parameter][1][:value][:xml_doc][:value]
    if completion_code.to_i == 0
      count = response.body[:execute_process_response][:output][:output][:parameter][2][:value][:xml_doc][:result]
      write_to("Operation completed succesfully: Entries updated: #{count}")
      pack_response "Entries updated", count
    else
      write_to("Operation failed: code: #{completion_code}, string: #{completion_string}")
    end
  end
rescue => e
  write_to("Operation failed: #{e.message}")
end
