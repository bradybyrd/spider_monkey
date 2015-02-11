###
# business_justification:
#   name: Business Justification
#   external_resource: remedy_release_business_justifications
#   type: in-external-single-select
#   position: A1:B1
# status:
#   name: Status
#   external_resource: remedy_change_request_statuses
#   type: in-external-single-select
#   position: A2:B2
# urgency:
#   name: Urgency
#   external_resource: remedy_change_request_urgencies
#   type: in-external-single-select
#   position: A3:B3
# impact:
#   name: Impact
#   external_resource: remedy_change_request_impacts
#   type: in-external-single-select
#   position: A4:B4
###

def import_script_parameters
  { "render_as" => "Table",  "maps_to" => "Ticket"  }
end

# ResourceAutomations must be contained in an execute block
def execute(script_params, parent_id, offset, max_records)
  begin
    require 'rubygems'
    require 'savon'
    require 'yaml'
    require 'exceptions'

    # while not included in the library file, once the script is entered into 
    # BRPM and associated with a project server, there will be a block of text
    # injected into the script header that provides connection details from
    # the project server model associated with the script.  This can also be
    # manually entered or overridden here
    ao_config = YAML.load(SS_integration_details)
    integration_password_dec = decrypt_string_with_prefix(SS_integration_password_enc)
    process_name = ":BRPM_Remedy_Change_Management:Resource Automation"

    schema_name = 'CHG:ChangeInterface'
    qualification = ""
    join_str = ""

    unless script_params["business_justification"].blank?
      qualification = qualification + "'Business Justification' = #{script_params["business_justification"]}"
      join_str = " AND "
    end

    unless script_params["status"].blank?
      qualification = qualification + join_str + "'Change Request Status' = #{script_params["status"]}"
      join_str = " AND "
    end

    unless script_params["urgency"].blank?
      qualification = qualification + join_str + "'Urgency' = #{script_params["urgency"]}"
      join_str = " AND "
    end

    unless script_params["impact"].blank?
      qualification = qualification + join_str + "'Impact' = #{script_params["impact"]}"
      join_str = " AND "
    end

    unless script_params["company"].blank?
      qualification = qualification + join_str + "'Company' = \"#{script_params["company"]}\""
      join_str = " AND "
    end

    unless script_params["support_organization"].blank?
      qualification = qualification + join_str + "'Support Organization' = \"#{script_params["support_organization"]}\""
      join_str = " AND "
    end

    unless script_params["support_group"].blank?
      qualification = qualification + join_str + "'Support Group Name' = \"#{script_params["support_group"]}\""
      join_str = " AND "
    end

    unless script_params["location_company"].blank?
      qualification = qualification + join_str + "'Location Company' = \"#{script_params["location_company"]}\""
      join_str = " AND "
    end

    namespaces = {
      "xmlns:soapenv" => "http://schemas.xmlsoap.org/soap/envelope/",
      "xmlns:soa" => "http://bmc.com/ao/xsd/2008/09/soa"
    }

    # build and execute the request
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
                    xml.soa(:Name, "Schema Name", "required" => "true")
                    xml.soa(:Value, "soa:type" => "xs:string") do |xml|
                      xml.soa(:Text,schema_name)
                    end
                  end

                  xml.soa(:Parameter) do |xml|
                    xml.soa(:Name, "Qualification", "required" => "true")
                    xml.soa(:Value, "soa:type" => "xs:string") do |xml|
                      xml.soa(:Text, qualification)
                    end
                  end

                  xml.soa(:Parameter) do |xml|
                    xml.soa(:Name, "Fields", :required => true)
                    xml.soa(:Value, "soa:type" => "xs:anyType") do |xml|
                      xml.soa(:XmlDoc) do |xml|
                        xml.fields do |xml|
                          xml.field("Infrastructure Change ID")
                          xml.field("Change Request Status")
                          xml.field("ChangeRequestStatusString")
                          xml.field("Risk Level")
                          xml.field("Reason For Change")
                          xml.field("Actual Start Date")
                          xml.field("Requested Start Date")
                          xml.field("Scheduled Start Date")
                          xml.field("Company")
                          xml.field("Support Organization")
                          xml.field("Support Group Name")
                          xml.field("Priority")
                          xml.field("Urgency")
                          xml.field("Impact")
                          xml.field("Description")
                          xml.field("Location Company")
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
    
    # store the response as is -- with native field names -- in a results hash -- these will become extended attributes on the ticket
    response_hash = response.body[:execute_process_response][:output][:output][:parameter][:value][:xml_doc][:outage_collection][:outage]
    if response_hash.has_key?(:query_action_result)
      
      ############################ EXTENDED ATTRIBUTES MAPPING AREA ############################# 
      # now loop through the results and prepare a hash that accurately captures the foreign
      # ticketing systems field names and data values so these can be stored in the 
      # free form extended attributes section to provide arbitrary property value display
      # capabilities to BRPM ticket stubs, allowing users to see full information on each ticket
      extended_attributes = []
      if response_hash[:query_action_result][:entries][:metadata][:entry_count] != "0"
        arr = response_hash[:query_action_result][:entries][:entry]
        arr.each do |el|
          field_array = el[:field]
          h = {}
          h["Infrastructure Change ID"] = field_array[0] unless field_array[0].is_a? Hash
          h["Change Request Status"]  = field_array[1] unless field_array[1].is_a? Hash
          h["ChangeRequestStatusString"] = field_array[2] unless field_array[2].is_a? Hash
          h["Risk Level"] = field_array[3] unless field_array[3].is_a? Hash
          h["Reason For Change"] = field_array[4] unless field_array[4].is_a? Hash
          h["Actual Start Date"] = field_array[5] unless field_array[5].is_a? Hash
          h["Requested Start Date"] = field_array[6] unless field_array[6].is_a? Hash
          h["Scheduled Start Date"] = field_array[7] unless field_array[7].is_a? Hash
          h["Company"] = field_array[8] unless field_array[8].is_a? Hash
          h["Support Organization"] = field_array[9] unless field_array[9].is_a? Hash
          h["Support Group Name"] = field_array[10] unless field_array[10].is_a? Hash
          h["Priority"] = field_array[11] unless field_array[11].is_a? Hash
          h["Urgency"] = field_array[12] unless field_array[12].is_a? Hash
          h["Impact"] = field_array[13] unless field_array[13].is_a? Hash
          h["Description"] = field_array[14] unless field_array[14].is_a? Hash
          h["Location Company"] = field_array[15] unless field_array[15].is_a? Hash
          #puts h.inspect
          extended_attributes << h
        end
      end
      
      ############################ TICKET MAPPING AREA -- REQUIRED FOR MAPS_TO TICKET RESOURCE AUTOMATON 
      
      # we are going to expect an array here that fits the table control standard AND that can be mapped
      # to our ticket and extended attributes tabs.  For example, we must return an initial header element
      # and then data to match.  The unique id for the first column will not be shown on the table and 
      # is user to store selected values by check box on the table control. The foreign_id in the 2nd column
      # is often but not necessarily the same value as the ra_uniq_identifier since it is usually guaranteed to 
      # be unique by the remote ticketing system. 
      # {
      # :perPage => 5, 
      # :totalItems => 100, 
      # :data => 
      # [
      #   ["ra_uniq_identifier","Foreign Id","Name","Ticket Type", "Status", "Extended Attributes"],
      #   ["DE4444","DE4444","Backup database","Completed", ...],
      #   ["DE4445","DE4445","Update version file","In Progress", ...],
      #   ["DE4446","DE4446","Admin Approval","Waiting", ...],
      #   ["DE4447","DE4447","QA Approval","Waiting", ...]
      # ]
      results = []
      # add the mandatory header row
      results << ["ra_uniq_identifier","Foreign Id","Name","Ticket Type", "Status", "Extended Attributes"]
      # now loop through the results and prepare a hash that fits the maps_to Ticket requirements
      unless extended_attributes.blank?
        extended_attributes.each_with_index do |external_ticket, index|
          #initialize a row array, not a hash, compatible with tickets and the table control
          #note: order is essential here as these are not key value pairs, must match header order
          t_row = []
          # find and set the unique identifier for this row -- string or integer
          # might be ok to put in the row index if this is blank or non-unique
          t_row << external_ticket["Infrastructure Change ID"] || index
          # now set the ticket mapping fields required to turn this into a ticket model
          t_row <<  external_ticket["Infrastructure Change ID"] || "Foreign ID Missing: Using #{Time.now.to_s}"
          t_row << (external_ticket["Description"] || "Name Unavailable")[0..255]
          t_row << 'Infrastructure Change' # hard coded by integration type
          t_row << (external_ticket["ChangeRequestStatusString"] || "Status Unavailable")[0..255]
          t_row << external_ticket.to_json
          results << t_row
        end
      else
        # return just the headers and no subsequent values and rely on the control to say nothing was returned
      end
      
      
      # TODO: The AO adapter was not originally enabled to return total matching records and paginated results
      # so we are setting these values to the length of the returned records for compatibility
      paginated_results = { :perPage => extended_attributes.length, 
                            :totalItems => extended_attributes.length, 
                            :data => results }
      
      ############################ END TICKET MAPPING AREA #############################################
      
      # write the ticket data to the output file for record keeping and debugging
      write_to("#=== TICKET DATA ===#")
      write_to(paginated_results.to_yaml)
      write_to("#=== END TICKET DATA ===#")
      
      return paginated_results

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