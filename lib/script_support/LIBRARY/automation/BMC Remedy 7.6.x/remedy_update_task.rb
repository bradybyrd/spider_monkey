###
# adapter_name:
#   name: Remedy Actor Adapter
#   required: yes
#   position: A1:B1
# task_id:
#   name: Task ID
#   required: yes
#   position: A2:B2
# task_name:
#   name: Task Name
#   position: A3:B3
# summary:
#   name: Summary
#   position: A4:B4
# notes:
#   name: Notes
#   position: A5:B5
# status:
#   name: Status
#   type: in-external-single-select
#   external_resource: remedy_task_statuses
#   position: D1:E1
# company:
#   name: Location Company
#   type: in-external-single-select
#   external_resource: remedy_customer_companies
#   position: D2:E2
# update_actual_start_date:
#   name: Update Actual Start Date?
#   type: in-list-single
#   list_pairs: No,No|Yes,Yes
#   position: D3:E3
# update_actual_end_date:
#   name: Update Actual End Date?
#   type: in-list-single
#   list_pairs: No,No|Yes,Yes
#   position: D4:E4
# Entries updated:
#   name: Entries updated
#   type: out-text
#   position: A1:B1
###

begin
  require 'yaml'
  require 'savon'
  require 'date'

  # Flag the script for direct execution
  params["direct_execute"] = true

  if [params["task_name"],params["summary"],params["notes"],params["status"],params["company"]].all? {|p| p.blank?} && params["update_actual_start_date"].eql?("No") && params["update_actual_end_date"].eql?("No")
    write_to("No change found. Please provide at least one field to update.")
  else
    filter_string = "'TaskID'"+"=\""+params["task_id"]+"\""

    ao_config = YAML.load(SS_integration_details)
    integration_password_dec = decrypt_string_with_prefix(SS_integration_password_enc)
    process_name = ":BRPM_Remedy_Change_Management:Update Remedy Entity"

    def seconds_since_epoch(time = Time.now)
      time = Time.parse(time) if time.is_a? String
      time.strftime("%s")
    end

    if params["task_id"].blank?
        write_to "Operation failed: Please specify a valid task id"
        exit(1)
    end

        namespaces = {
            "xmlns:soapenv" => "http://schemas.xmlsoap.org/soap/envelope/",
            "xmlns:soa" => "http://bmc.com/ao/xsd/2008/09/soa"
          }
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
                  xml.soa(:processName, process_name)
                  xml.soa(:parameters) do |xml|
                    xml.soa(:Input) do |xml|
                        xml.soa(:Parameter) do |xml|
                          xml.soa(:Name, "form name", "required" => "true")
                          xml.soa(:Value, "soa:type" => "xs:string") do |xml|
                             xml.soa(:Text,"TMS:TaskInterface")
                          end
                        end
                        xml.soa(:Parameter) do |xml|
                          xml.soa(:Name, "filter string", "required" => "true")
                          xml.soa(:Value, "soa:type" => "xs:string") do |xml|
                             xml.soa(:Text,filter_string)
                          end
                        end

                        xml.soa(:Parameter) do |xml|
                          xml.soa(:Name, "remedy actor adapter name")
                          xml.soa(:Value, "soa:type" => "xs:string") do |xml|
                            xml.soa(:Text, params["adapter_name"])
                          end
                        end

                        xml.soa(:Parameter) do |xml|
                          xml.soa(:Name, "fields xml", "required" => "true")
                          xml.soa(:Value, "soa:type" => "xs:anyType") do |xml|
                            xml.soa(:XmlDoc) do |xml|
                              xml.fields do |xml|
                                xml.field(params["task_name"], :name => "TaskName") unless params["task_name"].blank?
                                xml.field(params["summary"], :name => "Summary") unless params["summary"].blank?
                                xml.field(params["notes"], :name => "Notes") unless params["notes"].blank?
                                xml.field(params["status"], :name => "Status") unless params["status"].blank?
                                xml.field(params["company"], :name => "Location Company") unless params["company"].blank?
                                if params["update_actual_start_date"] && (params["update_actual_start_date"].eql?("Yes"))
                                  xml.field(seconds_since_epoch, :name => "Actual Start Date")
                                end
                                if params["update_actual_end_date"] && (params["update_actual_end_date"].eql?("Yes"))
                                  xml.field(seconds_since_epoch, :name => "Actual End Date")
                                end
                              end
                            end
                          end
                        end
                    end
                  end
                end
              end
            end
          end
        end
    write_to("===================Response=============================")
    completion_code = response.body[:execute_process_response][:output][:output][:parameter][0][:value][:xml_doc][:value]
    completion_string = response.body[:execute_process_response][:output][:output][:parameter][1][:value][:xml_doc][:value]
    if completion_code.to_i == 0
      count = response.body[:execute_process_response][:output][:output][:parameter][2][:value][:xml_doc][:result]
      write_to("Operation completed succesfully: Updated Entities: #{count}")
      pack_response "Entries updated", count
    else
      write_to("Operation failed: code: #{completion_code}, string: #{completion_string}")
    end
  end
rescue => e
  write_to("Operation failed: #{e.message}")
end
