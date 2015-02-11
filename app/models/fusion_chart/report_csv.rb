################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

require 'csv'

class FusionChart

  ORACLE_IN_LIMIT = 1000
  def self.generate_csv_report(request_ids)
    CSV.generate do |csv|
      csv << ['Request Number',           'Process',      'Application',          'Environment',
              'Created at',               'scheduled at', 'Target Completion at', 'Notes',       'State',
              'Completed at',             'Started at',   'Planned at',           'Deleted at',  'Description', 
              'Estimate',                 'Requestor',    'Is Auto Start',        'Wiki url',    'Owner',
              'Cancelled at'          
             ]
        request_ids.in_groups_of(ORACLE_IN_LIMIT,false) do |r_ids|
        requests = Request.includes(:apps,:business_process,:environment,:notes).find(r_ids)
        requests.each do |request|
          csv << [request.number,
                  csv_name(request.business_process),
                  csv_names_sentence(request.apps),
                  csv_name(request.environment),

                  # step.id,
                  csv_time(request.created_at),
                  csv_time(request.scheduled_at),
                  csv_time(request.target_completion_at),
                  request.notes,
                  request.aasm_state,
                  csv_time(request.completed_at),
                  csv_time(request.started_at),
                  csv_time(request.planned_at),
                  csv_time(request.deleted_at),
                  request.description,
                  request.estimate,
                  csv_name(User.find(request.requestor_id)),
                  request.auto_start,
                  request.wiki_url,
                  csv_name(User.find(request.owner_id)),
                  csv_time(request.cancelled_at)
          ]
        end
      end

    end
  end

private
  class << self
    def csv_time(time)
      time ? time.default_format : '(Never)'
    end

    def csv_day_of_week(time)
      if time
        "#{time.wday + 1} #{Date::ABBR_DAYNAMES[time.wday]}"
      else
        '(Never)'
      end
    end

    def csv_month(time)
      time ? time.strftime('%m %b') : '(Never)'
    end

    def csv_week_of_month(time)
      if time
        (5 - time.wday + time.day) / 7 + 1
      else
        '(Never)'
      end
    end

    def csv_name(named_thing)
      named_thing ? named_thing.name : "(None)"
    end

    def csv_names_sentence(named_things)
      return "(None)" if named_things.empty?

      named_things.map { |the_named| the_named.name }.to_sentence
    end

    def csv_string(string)
      string || "N/A"
    end

    def csv_duration(*args)
      return "N/A" if args.empty?

      case args.first
      when Request, Step
        model = args.first
        earlier = args[1]
        later   = args[2]
        return unless (model.send(earlier) && model.send(later) rescue false)

        seconds = (model.send(later) - model.send(earlier)).to_i
      else
        seconds = args.first.to_i
      end

      abs_val_seconds = seconds < 0 ? -seconds : seconds

      time_string = seconds < 0 ? "-" : ''
      time_string << "#{(abs_val_seconds / 3600)}:"
      time_string << "#{(abs_val_seconds % 3600 / 60).to_s.rjust(2, '0')}:"
      time_string << "#{abs_val_seconds % 60}".rjust(2, '0')
    end
  end
  
  
  end
