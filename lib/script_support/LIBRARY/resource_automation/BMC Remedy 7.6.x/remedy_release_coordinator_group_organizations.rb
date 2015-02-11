###
# adapter_name:
#   name: Remedy Actor Adapter
#   required: yes
# coordinator_group_company:
#   name: Coordinator Company
#   type: in-external-single-select
#   external_resource: remedy_release_coordinator_group_companies
#   required: yes
###

def execute(script_params, parent_id, offset, max_records)
  begin
    require 'rubygems'
    require 'savon'
    require 'yaml'
    require 'exceptions'

    ao_config = YAML.load(SS_integration_details)
    integration_password_dec = decrypt_string_with_prefix(SS_integration_password_enc)
    process_name = ":BRPM_Remedy_Change_Management:Resource Automation"       

    schema_name = 'CTM:SupportGroupFuncRoleLookUp'
    qualification = "(('FunctionalRole' = \"Release Coordinator\") OR ('FunctionalRole' = \"Release Manager\")) AND ('Assignment Availability' = \"Yes\") AND ('Status-SGR' = \"Enabled\") AND ('Status-SGP' = \"Enabled\") AND ('Company' = \"#{script_params['coordinator_group_company']}\")"
    field = 'Support Organization'
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
              xml.soa(:moduleName, ao_config["module_name"])
              xml.soa(:processName, process_name)
              xml.soa(:parameters) do |xml|
                xml.soa(:Input) do |xml|

                  xml.soa(:Parameter) do |xml|
                    xml.soa(:Name, "Remedy Adapter Name", "required" => "true")
                    xml.soa(:Value, "soa:type" => "xs:string") do |xml|             
                      xml.soa(:Text, script_params['adapter_name'])
                    end
                  end

                  xml.soa(:Parameter) do |xml|
                    xml.soa(:Name, "Schema Name", "required" => "true")
                    xml.soa(:Value, "soa:type" => "xs:string") do |xml|             
                      xml.soa(:Text,schema_name)
                    end
                  end

                  xml.soa(:Parameter) do |xml|
                    xml.soa(:Name, "Qualification", "required" => "true")
                    xml.soa(:Value, "soa:type" => "xs:string") do |xml|             
                      xml.soa(:Text,qualification)
                    end
                  end

                  xml.soa(:Parameter) do |xml|
                    xml.soa(:Name, "Fields", :required => true)
                    xml.soa(:Value, "soa:type" => "xs:anyType") do |xml|
                      xml.soa(:XmlDoc) do |xml|
                        xml.fields do |xml|
                          xml.field(field)
                        end
                      end
                    end
                  end

                  xml.soa(:Parameter) do |xml|
                    xml.soa(:Name, "Item Type", "required" => "true")
                    xml.soa(:Value, "soa:type" => "xs:string") do |xml|             
                      xml.soa(:Text,'outage')
                    end
                  end                                        

                end
              end
            end
          end
        end
      end
    end
    response_hash = response.body[:execute_process_response][:output][:output][:parameter][:value][:xml_doc][:outage_collection][:outage] 
    if response_hash.has_key?(:query_action_result)    
      result = [{'Select' => ''}]
      if response_hash[:query_action_result][:entries][:metadata][:entry_count] != "0"
        arr = response_hash[:query_action_result][:entries][:entry]
        if arr.is_a? Array
          arr.each do |el|
            result << {el[:field] => el[:field]}   
          end
        else
          result << {arr[:field] => arr[:field]}
        end
      end
      result.uniq
    else
      raise Exceptions::ResourceAutomationError.new(102), response_hash[:response_data][:metadata][:error]
    end 
  rescue => e
    if e.class.to_s.eql?('Errno::ECONNREFUSED')
      raise Exceptions::ResourceAutomationError.new(100), e.message
    elsif e.message.include?('Authentication of Username Password Token Failed')
      raise Exceptions::ResourceAutomationError.new(101), e.message
    elsif e.class.to_s.eql?('Exceptions::ResourceAutomationError')
      raise e
    else
      raise Exceptions::ResourceAutomationError.new(103), e.message
    end
  end     
end