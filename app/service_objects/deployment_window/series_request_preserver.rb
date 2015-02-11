module DeploymentWindow
  class SeriesRequestPreserver
    attr_reader :series

    def initialize(series)
      @series = series
    end

    # store requests for events that have not finished yet
    def store_requests
      occurrences             = occurrences_to_preserve_request
      series.stored_requests  = request_ids_in_a_hash(occurrences)
    end

    def restore_requests(stored_requests)
      Request.transaction do
        begin
          restore_requests!(stored_requests) if stored_requests
        rescue => e
          raise ActiveRecord::Rollback, "An error occurred when trying to restore request's deployment window. #{e.inspect}"
        end
      end
    end

    private

    # get occurrences that are not finished with their events
    # TODO: IF IT FAILS AT ORACLE -> `includes(:events)` IS THE REASON. NEED TO LOOK FOR MORE THAN 1000 ITEMS IN WHERE STATEMENTS FIX
    def occurrences_to_preserve_request
      series.occurrences.where('deployment_window_occurrences.finish_at > ?', Time.zone.now).
          joins(:events).where('deployment_window_events.environment_id IN (?)', series.environment_ids).includes(:events)
    end

    def events_to_preserve_request
      series.events.not_finished.where(environment_id: series.environment_ids)
    end

    def events_occurrences(occurrence_ids)
      DeploymentWindow::Occurrence.includes(:events).scoped.extending(QueryHelper::WhereIn).
          where_in(:id, occurrence_ids).order(:start_at)
    end

    # stored_requests: {1 => { 2 => [1,2], 10 => [3,4] }}
    def restore_requests!(stored_requests)
      stored_requests.each do |occurrence_relative_position, environment_requests|
        environment_requests.each do |environment_id, request_ids|
          next if request_ids.none?
          event_id = event_id_by(environment_id, occurrence_relative_position)
          assign_event_to_requests(request_ids, event_id) if event_id
        end
      end
    end

    def assign_event_to_requests(request_ids, event_id)
      requests = Request.scoped.extending(QueryHelper::WhereIn).where_in(:id, request_ids)
      requests.update_all(deployment_window_event_id: event_id)
    end

    # get event_id for certain environment id and occurrences which have not started yet
    def event_id_by(environment_id, occurrence_relative_position)
      series.events.not_started.by_environment(environment_id).order('deployment_window_events.start_at').
          pluck('deployment_window_events.id')[occurrence_relative_position]
    end

    # stores request ids per event's environment id per occurrence position in a hash
    # e.g. {1 => { 2 => [1,2], 10 => [3,4] }}
    def request_ids_in_a_hash(occurrences)
      requests = {}
      occurrences.each_with_index do |occurrence, occurrence_relative_position|
        requests[occurrence_relative_position] = occurrence.events.inject({}) do |request_ids_per_environment_ids, event|
          request_ids_per_environment_ids[event.environment_id] = event.requests.pluck(:id)
          request_ids_per_environment_ids
        end
      end

      requests
    end

  end
end