###
# release_id:
#   name: Release Id
#   required: yes
#   position: A1:B1
# Release pulled:
#   name: Release pulled
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
  process_name = ":BRPM_Remedy_Change_Management:Create Release Plan In BRPM"

  if params["release_id"].blank?
    write_to("Operation failed: No valid release ticket id could be determined (or provided)")
    exit(1)
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
                  xml.soa(:Name, "inputevent", :required => true)
                  xml.soa(:Value, "soa:type" => "xs:anyType") do |xml|
                    xml.soa(:XmlDoc) do |xml|
                      xml.tag! 'adapter-event' do |xml|
                        xml.tag! 'form-name', 'RMS:Release'
                        xml.text("Release Planned:#{params["release_id"]}")
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

  write_to("------------ Output ----------------------")
  completion_code = response.body[:execute_process_response][:output][:output][:parameter][0][:value][:xml_doc][:value]
  completion_string = response.body[:execute_process_response][:output][:output][:parameter][1][:value][:xml_doc][:value]
  if completion_code.to_i == 0
    write_to("Operation completed succesfully")
    pack_response "Release pulled", params["release_id"]
  else
    write_to("Operation failed: code: #{completion_code}, string: #{completion_string}")
  end
rescue => e
  write_to("Operation failed: #{e.message}")
end
