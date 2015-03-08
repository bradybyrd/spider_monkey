################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2015
# All Rights Reserved.
################################################################################
require 'csv'

module RequestCSV
  def generate_csv_report(start_date, end_date, calendar=nil)
    start_date = ActiveSupport::TimeWithZone.new(start_date.to_time, Time.zone)
    end_date = ActiveSupport::TimeWithZone.new(end_date.to_time, Time.zone)
    
    if calendar.present?
      request_ids = []
      requests = calendar.get_requests_between_dates(start_date, end_date)
      requests.each do |request|
        request_ids.push(request.id)
      end
      activity_logs = ActivityLog.scoped.extending(QueryHelper::WhereIn)
        .where_in('request_id', request_ids).order('created_at ASC, usec_created_at ASC').all
        .group_by { |log| log.request_id }
    else
      activity_logs = ActivityLog.all(conditions: {created_at: (start_date..end_date)}, order: 'created_at ASC, usec_created_at ASC').group_by { |log| log.request_id }
    end

    CSV.generate do |csv|
      csv << ['Request',                  'Process',                        'Application',             'Status',                   'Environment',
              'Step ID',                  'Time Status Initially Selected', 'Time Last Updated',       'Previous Status',          'Requestor',
              'Requestor Role',           'Requestor Group',                'Last Updated by',         'Updater Role',             'Updater Group', 
              'Release Tag',              'Req Scheduled Start Time',       'Req Target Complete',     'Req Actual Start Time',    'Step Number',
              'Component',                'Work Task',                       'Assigned To',             'Version',                  'Order',
              'Complete By',              'Estimated Time',                 'Notes',                   'Is Procedure?',            'Procedure Name',
              'Created to Planned',       'Planned to Scheduled',           'Start to Scheduled',      'Actual Start to Complete', 'Total Hold Time',
              'Hold Event Count',         'Total Problem Time',             'Problem Event Count',     'Locked to Ready',          'Ready to Started',
              'Step Run Time',            'Total Problem Time',             'Problem Event Count',     'Total Blocked Time',       'Blocked Event Count',
              'Note Count',               'Req Start Month',                'Req Start Week of Month', 'Req Start Day of Week',    'Step Start Month',    
              'Step Start Week of Month', 'Step Start Day of Week'
             ]

      activity_logs.each do |request_id, logs|
        request = Request.find_by_id(request_id)
        logs.each_with_index do |log, index|
          if log.activity =~ /^Step (\d+):/
            step_number = $1
            step = request.steps.find_by_position(step_number)
            next unless step

            csv << [request.number,
                    csv_name(request.business_process),
                    csv_names_sentence(request.apps),
                    "Step: #{csv_string(ActivityLog.extract_state(log.activity))}",
                    csv_name(request.environment),

                    step.id,
                    log.created_at.default_format,
                    '[Not tracked]',
                    csv_string(ActivityLog.extract_previous_state(logs, index)),
                    csv_name(request.user),

                    request.user.formatted_role,
                    csv_names_sentence(request.user.groups),
                    '[Not tracked]',
                    '[Not tracked]',
                    '[Not tracked]',

                    csv_name(request.release),
                    csv_time(request.scheduled_at),
                    csv_time(request.target_completion_at),
                    csv_time(request.started_at),
                    step.position,

                    csv_name(step.component),
                    csv_name(step.work_task),
                    csv_name(step.owner_id.present? ? step.owner : nil),
                    step.version_name,
                    '[Not Tracked]',

                    csv_time(step.complete_by),
                    step.estimate,
                    step.notes.map { |n| n.content },
                    step.procedure?,
                    step.parent && step.parent.name,

                    csv_duration(request, :created_at, :planned_at),
                    csv_duration(request, :planned_at, :scheduled_at),
                    csv_duration(request, :started_at, :scheduled_at),
                    csv_duration(request, :started_at, :completed_at),
                    csv_duration(ActivityLog.get_status_duration(logs, request: {status: :hold})),

                    ActivityLog.get_status_count(logs, request: {status: :hold}),
                    csv_duration(ActivityLog.get_status_duration(logs, request: {status: :problem})),
                    ActivityLog.get_status_count(logs, request: {status: :problem}),
                    csv_duration(step, :created_at, :ready_at),
                    csv_duration(step, :ready_at, :work_started_at),

                    csv_duration(step, :work_started_at, :work_finished_at),
                    csv_duration(ActivityLog.get_status_duration(logs, step: {status: :problem, number: step_number})),
                    ActivityLog.get_status_count(logs, step: {status: :problem, number: step_number}),
                    csv_duration(ActivityLog.get_status_duration(logs, step: {status: :blocked, number: step_number})),
                    ActivityLog.get_status_count(logs, step: {status: :blocked, number: step_number}),

                    step.notes.count,
                    csv_month(request.started_at),
                    csv_week_of_month(request.started_at),
                    csv_day_of_week(request.started_at),
                    csv_month(step.work_started_at),

                    csv_week_of_month(step.work_started_at),
                    csv_day_of_week(step.work_started_at)
                   ]
          else
            csv << [request.number,
                    csv_name(request.business_process),
                    csv_names_sentence(request.apps),
                    "Request: #{csv_string(ActivityLog.extract_state(log.activity))}",
                    csv_name(request.environment),

                    'N/A',
                    log.created_at.default_format,
                    '[Not tracked]',
                    csv_string(ActivityLog.extract_previous_state(logs, index)),
                    csv_name(request.user),

                    request.user.formatted_role,
                    csv_names_sentence(request.user.groups),
                    '[Not tracked]',
                    '[Not tracked]',
                    '[Not tracked]',

                    csv_name(request.release),
                    csv_time(request.scheduled_at),
                    csv_time(request.target_completion_at),
                    csv_time(request.started_at),
                    'N/A',

                    'N/A',
                    'N/A',
                    'N/A',
                    'N/A',
                    'N/A',

                    'N/A',
                    'N/A',
                    'N/A',
                    'N/A',
                    'N/A',

                    csv_duration(request, :created_at, :planned_at),
                    csv_duration(request, :planned_at, :scheduled_at),
                    csv_duration(request, :started_at, :scheduled_at),
                    csv_duration(request, :started_at, :completed_at),
                    csv_duration(ActivityLog.get_status_duration(logs, request: {status: :hold})),

                    ActivityLog.get_status_count(logs, request: {status: :hold}),
                    csv_duration(ActivityLog.get_status_duration(logs, request: {status: :problem})),
                    ActivityLog.get_status_count(logs, request: {status: :problem}),
                    'N/A',
                    'N/A',

                    'N/A',
                    'N/A',
                    'N/A',
                    'N/A',
                    'N/A',

                    'N/A',
                    csv_month(request.started_at),
                    csv_week_of_month(request.started_at),
                    csv_day_of_week(request.started_at),
                    'N/A',

                    'N/A',
                    'N/A'
                   ]
          end
        end
      end
    end
  end

private
  
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
    named_thing ? named_thing.name : '(None)'
  end

  def csv_names_sentence(named_things)
    return '(None)' if named_things.empty?

    named_things.map { |the_named| the_named.name }.to_sentence
  end

  def csv_string(string)
    string || 'N/A'
  end

  def csv_duration(*args)
    return 'N/A' if args.empty?

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

    time_string = seconds < 0 ? '-' : ''
    time_string << "#{(abs_val_seconds / 3600)}:"
    time_string << "#{(abs_val_seconds % 3600 / 60).to_s.rjust(2, '0')}:"
    time_string << "#{abs_val_seconds % 60}".rjust(2, '0')
  end

end
