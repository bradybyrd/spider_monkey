################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class Interrogator

  attr_reader :command

  def initialize(command)
    @command = command
  end

  def respond
    case command
    when /request\-(\d+)(\s+)([a-z]+)/i
      describe_request($1, $3)
    else
      'Your command was not recognized'
    end
  end

  def describe_request(request_id, command_name)
    request = Request.find_by_number(request_id) rescue nil

    return "Unable to locate request #{request_id}" if request.nil?

    case command_name
    when 'status'
      <<-REQUEST_STATUS
      Request-#{request_id}
      ========================================================================================
      PROCESS: #{request.business_process.name}
      APPLICATION: #{request.app_name.join(", ")}
      STATUS: #{request.aasm.current_state.to_s.humanize}
      ENVIRONMENT: #{request.environment.name}
      REQUESTOR: #{request.user.last_name}, #{request.user.first_name}
      RELEASE: #{request.release.name if request.release}
      SCHEDULED TIME: #{request.scheduled_at.to_s(:datepicker) if request.scheduled_at}
      TARGET COMPLETE: #{request.target_completion_at.to_s(:datepicker) if request.target_completion_at}
      NOTES:
      #{request.notes}
      REQUEST_STATUS
    else
      "Unknown command given for request-#{request_id}"
    end
  end

end
