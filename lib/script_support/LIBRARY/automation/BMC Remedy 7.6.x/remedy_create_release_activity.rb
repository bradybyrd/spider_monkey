###
# adapter_name:
#   name: Remedy Actor Adapter
#   required: yes
#   position: A1:B1
# release_id:
#   name: Release Id [Leave Blank to auto-pick from lifecycle]
#   position: A2:B2
# priority:
#   name: Priority
#   type: in-external-single-select
#   external_resource: remedy_release_activity_priorities
#   position: A3:B3
# summary:
#   name: Summary
#   required: yes
#   position: A4:B4
# notes:
#   name: Notes
#   position: A5:B5
# requestor_company:
#   name: Requestor Company
#   type: in-external-single-select
#   external_resource: remedy_customer_companies
#   required: yes
#   position: A6:B6
# location_company:
#   name: Location Company
#   type: in-external-single-select
#   external_resource: remedy_customer_companies
#   required: yes
#   position: A7:B7
# requestor_first_name:
#   name: Requestor First Name
#   required: yes
#   position: D1:E1
# requestor_last_name:
#   name: Requestor Last Name
#   required: yes
#   position: D2:E2
# assignee_company:
#   name: Assignee Company
#   type: in-external-single-select
#   external_resource: remedy_release_activity_support_companies
#   position: D3:E3
# assignee_organization:
#   name: Assignee Organization
#   type: in-external-single-select
#   external_resource: remedy_release_activity_support_organizations
#   position: D4:E4
# assignee_group:
#   name: Assignee Group
#   type: in-external-single-select
#   external_resource: remedy_release_activity_support_groups
#   position: D5:E5
# assignee_user:
#   name: Assignee User
#   type: in-external-single-select
#   external_resource: remedy_release_activity_support_users
#   position: D6:E6
# Activity created:
#   name: Activity created
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

  ao_config = YAML.load(SS_integration_details)
  integration_password_dec = decrypt_string_with_prefix(SS_integration_password_enc)
  process_name = ":BRPM_Remedy_Change_Management:Create Remedy Entity"

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
                    xml.soa(:Text, "AAS:ActivityInterface_Create")
                  end
                end

                xml.soa(:Parameter) do |xml|
                  xml.soa(:Name, "data fields", :required => true)
                  xml.soa(:Value, "soa:type" => "xs:anyType") do |xml|
                    xml.soa(:XmlDoc) do |xml|
                      xml.fields do |xml|
                        xml.field(params["summary"], :name => "Summary") unless params["summary"].blank?
                        xml.field(params["notes"], :name => "Notes") unless params["notes"].blank?
                        xml.field(params["priority"], :name => "Priority") unless params["priority"].blank?
                        xml.field(params["requestor_first_name"], :name => "First Name") unless params["requestor_first_name"].blank?
                        xml.field(params["requestor_last_name"], :name => "Last Name") unless params["requestor_last_name"].blank?
                        xml.field(params["requestor_company"], :name => "Company") unless params["requestor_company"].blank?
                        xml.field(params["location_company"], :name => "Location Company") unless params["location_company"].blank?
                        xml.field(params["release_id"], :name => "RootRequestID") unless params["release_id"].blank?
                        xml.field("MAINRELEASE", :name => "LookupKeyword")
                        xml.field(params["assignee_company"], :name => "ASCPY") unless params["assignee_company"].blank?
                        xml.field(params["assignee_organization"], :name => "ASORG") unless params["assignee_organization"].blank?
                        xml.field(params["assignee_group"], :name => "ASGRP") unless params["assignee_group"].blank?
                        xml.field(params["assignee_user"], :name => "ASASN") unless params["assignee_user"].blank?
                      end
                    end
                  end
                end

                xml.soa(:Parameter) do |xml|
                  xml.soa(:Name, "id field")
                  xml.soa(:Value, "soa:type" => "xs:string") do |xml|
                    xml.soa(:Text, "Activity ID")
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
    entity_id = response.body[:execute_process_response][:output][:output][:parameter][2][:value][:xml_doc][:result]
    write_to("Operation completed succesfully: entity id: #{entity_id}")
    pack_response "Activity created", entity_id
  else
    write_to("Operation failed: code: #{completion_code}, string: #{completion_string}")
  end
rescue => e
  write_to("Operation failed: #{e.message}")
end  
