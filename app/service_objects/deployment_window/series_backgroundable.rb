module DeploymentWindow
  class SeriesBackgroundable
    include TorqueBox::Messaging::Backgroundable if defined? TorqueBox

    def self.create_recurrent_occurrences(series_id, environment_ids)
      safe_action(series_id) do |series|
        occurrences = get_occurrences series
        occurrences.each_with_index do |occurrence, i|
          series.occurrences.create(position: i + 1,
                                    start_at: occurrence.start_time,
                                    finish_at: occurrence.end_time,
                                    environment_ids: environment_ids,
                                    environment_names: series.environment_names,
                                    name: series.name,
                                    behavior: series.behavior)
        end
      end
    end

    def self.update_recurrent_occurrences_environments(series_id, environment_ids_to_create, environment_ids_to_delete)
      safe_action(series_id) do |series|
        series.delete_events_by_environment_ids(environment_ids_to_delete) if environment_ids_to_delete.any?

        series.occurrences.not_finished.each do |occurrence|
          occurrence.environment_ids = environment_ids_to_create
          occurrence.behavior = series.behavior
          occurrence.name = series.name
          occurrence.environment_names = series.environment_names
          occurrence.save!
        end if environment_ids_to_create.any?
      end
    end

    def self.recreate_recurrent_occurrences_and_restore_requests(series_id, series_environment_ids, series_stored_requests)
      safe_action(series_id) do |series|
        series.delete_occurrences_not_finished_and_their_events
        create_recurrent_occurrences series_id, series_environment_ids
        DeploymentWindow::SeriesConstruct.restore_requests series, series_stored_requests
      end
    end

    def self.get_occurrences(series)
      start_time  = series.start_at > Time.zone.now ? series.start_at : Time.zone.now
      finish_time = series.finish_at - series.schedule.duration
      occurrences = series.schedule.send(:find_occurrences, start_time - 1 , finish_time)
      occurrences
    end

    def self.find_series!(series_id)
      DeploymentWindow::Series.find(series_id, include: :occurrences)
    end

    def self.safe_action(series_id)
      begin
        ensure_timezone
        series = find_series! series_id
        yield(series) if block_given?
      rescue => e
        Rails.logger.error "Occurrence for Deployment Window Series id##{series_id} could not be generated. #{e.backtrace}"
      ensure
        series.unlock! if series
      end
    end

    def self.ensure_timezone
      Time.zone = GlobalSettings[:timezone] unless GlobalSettings[:timezone].nil?
    end

    def self.after_occurrences_create_callback(series_id)
      series = find_series! series_id
      series.after_occurrences_create
    end

    private_class_method :get_occurrences, :find_series!, :safe_action, :ensure_timezone
  end
end
