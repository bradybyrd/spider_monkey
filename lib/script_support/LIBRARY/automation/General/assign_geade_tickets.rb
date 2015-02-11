require 'json'
require 'rest-client'

params["direct_execute"] = true

# Set fail overs if not in xml
default_integration_id = 1
default_ticket_type = "Geade"
#
# First try to load and parse the data file for the request
#
unless params["SS_output_dir"]
  write_to "Command_Failed - Cannot locate data file to work upon"
  return 1
end

request_data_file_dir = File.dirname(params["SS_output_dir"])
request_data_file = "#{request_data_file_dir}/request_data.json"

json = File.read(request_data_file)
request_data = JSON.parse(json)

#
# Iterate over each event and process it
#
unless request_data["events"] && request_data["events"]["event"]
  write_to "Command_Failed - Could not locate any events"
  return 1
end

release_date_to_plan_id = {}

request_data["events"]["event"].each do | evt |
  if evt["release_date"].nil? && evt["releaseId"].nil?
    write_to "Release date or Id not specified for event: #{evt.inspect}, skipping it"
    next
  end

  plan_id = evt["releaseId"]
  if plan_id.nil?
    #
    # First do a cache lookup to see if we already have a plan id corresponding to ticket
    #
    unless release_date_to_plan_id.include?(evt["release_date"])
      #
      # Find out the plan corresponding to the event
      #
      begin
        response = RestClient.get "#{params["SS_base_url"]}/v1/plans?token=#{params["SS_api_token"]}&filters[release_date]=#{evt["release_date"].strip}", :accept => :json 
        plans = JSON.parse(response)

        if plans.count > 1
          write_to "Warning: multiple plans found corresponding to release date: #{evt["release_date"]}, skipping event: #{evt["eventId"]}"
          next
        end
    
        release_date_to_plan_id[evt["release_date"]] = plans.first["plan"]["id"].to_s
      rescue Exception => e
        write_to "Warning: Could not find plan corresponding to release date: #{evt["release_date"]}, skipping event: #{evt["eventId"]}, error: #{e.message}"
        next
      end
    end
    plan_id = release_date_to_plan_id[evt["release_date"]]
  end

  #
  # Now create a ticket hash from the event information
  #
  ticket = {}
  ticket["foreign_id"] = evt["eventId"] unless evt["eventId"].nil?
  ticket["name"] = evt["summary"] unless evt["summary"].nil?
  ticket["status"] = evt["status"] unless evt["status"].nil?
  ticket["project_server_id"] = evt["project_server_id"] unless evt["project_server_id"].nil?
  ticket["ticket_type"] = evt["ticket_type"] unless evt["ticket_type"].nil?
  ticket["plan_ids"] = plan_id
  ticket["find_application"] = evt["applicationId"] unless evt["applicationId"].nil?
  
  linked_ticket_ids = []
  unless evt["linkedEventIds"].nil?
    unless evt["linkedEventIds"]["linkedEventId"].nil?
      evt["linkedEventIds"]["linkedEventId"].each do | le |
        begin
          response = RestClient.get "#{params["SS_base_url"]}/v1/tickets?token=#{params["SS_api_token"]}&filters[foreign_id]=#{le.strip}", :accept => :json
          parsed_response = JSON.parse(response)        
          fetched_ticket = parsed_response.first["ticket"]
          linked_ticket_id = fetched_ticket["id"].to_s
          linked_ticket_ids.push(linked_ticket_id)
        rescue Exception => e
          if e.message.strip =~ /^404/
            write_to "Warning: Ticket #{le} not found, so cannot attach to ticket #{evt["eventId"]}"
          else
            write_to "Warning: Could not query ticket: #{le}, error: #{e.message}, so cannot attach to ticket #{evt["eventId"]}"
          end
        end
      end
    end
  end
  ticket["related_ticket_ids"] = linked_ticket_ids unless linked_ticket_ids.empty?

  extended_attributes = Array.new
  unless evt["severity"].nil?
    severity = {}
    severity["name"] = "severity"
    severity["value_text"] = evt["severity"]
    extended_attributes.push(severity)
  end

  unless evt["description"].nil?
     description = {}
     description["name"] = "description"
     description["value_text"] = evt["description"]
     extended_attributes.push(description)
  end

  #
  # First check if the ticket exists
  #
  ticket_id = nil
  begin
    url = "#{params["SS_base_url"]}/v1/tickets?token=#{params["SS_api_token"]}&filters[foreign_id]=#{evt["eventId"].strip}"
    write_to "Fetching url: #{url}"
    response = RestClient.get url, :accept => :json 
    parsed_response = JSON.parse(response)
    # Looks like ticket exists
    fetched_ticket = parsed_response.first["ticket"]
    ticket_id = fetched_ticket["id"].to_s
    if fetched_ticket["extended_attributes"]
      fetched_ticket["extended_attributes"].each do | curr_attr |
        extended_attributes.each do | new_attr |
          if curr_attr["name"].eql?(new_attr["name"])
             new_attr["id"] = curr_attr["id"]
          end
        end
      end
    end
  rescue Exception => e
    unless e.message.strip =~ /^404/
      write_to "Warning: Could not query ticket: #{evt["eventId"]}, error: #{e.message}"
      next
    end
  end

  unless extended_attributes.nil? || extended_attributes.empty?
    ticket["extended_attributes_attributes"] = extended_attributes
  end
  
  data = {}
  data["ticket"] = ticket
  data["token"] = params["SS_api_token"]


  if ticket_id.nil? 
    #
    # Ticket does not exist
    #
    begin
      url = "#{params["SS_base_url"]}/v1/tickets"
      write_to "Fetching url: #{url}"
      write_to "Post Data: #{data.to_json.inspect}"
      response = RestClient.post url, data.to_json, :content_type => :json, :accept => :json
      parsed_response = JSON.parse(response)
      write_to "------------- Ticket created successfully --------------"
      write_to parsed_response.inspect
      write_to "--------------------------------------------------------"
    rescue Exception => e
      write_to "Error: Could not create ticket: #{evt["eventId"]}, error: #{e.message}"
      next
    end
  else
    #
    # Update ticket information
    #
    begin
      url = "#{params["SS_base_url"]}/v1/tickets/#{ticket_id}"
      write_to "Fetching url: #{url}"
      write_to "Post Data: #{data.to_json.inspect}"
      response = RestClient.put url, data.to_json, :content_type => :json, :accept => :json
      parsed_response = JSON.parse(response)
      write_to "------------- Ticket updated successfully --------------"
      write_to parsed_response.inspect
      write_to "--------------------------------------------------------"
    rescue Exception => e
      write_to "Error: Could not update ticket: #{evt["eventId"]}, error: #{e.message}"
      next
    end
  end
end
