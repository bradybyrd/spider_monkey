module DeploymentWindow
  class SeriesConstruct
    attr_accessor :recurrent_changed, :non_recurrent_changed, :environments_changed
    attr_reader :series
    delegate :validator, :errors, to: :@series

    def initialize(params, series = nil)
      @series = series || DeploymentWindow::Series.new
      @params = params
      begin
        @series.attributes = @params[:deployment_window_series]
      rescue => ex
        @exception = ex
      end
      @recurrent = @params[:deployment_window_series][:recurrent]
    end

    def recurrent?
      @recurrent
    end

    def requests_present?
      @requests_present ||= @series.requests.any?
    end

    def create
      return false unless valid?
      @series.environment_names = environment_names
      @series.created_by = User.current_user.id if User.current_user
      if @series.save
        build_occurrences
        true
      end
    end

    def update
      return false unless valid?
      @series.environment_names = environment_names if environments_changed?
      if @series.save
        update_occurrences
        send_notification if requests_present?
        true
      end
    end

    def valid?
      if @exception
        validator.check_bad_date_format(@exception)
      else
        @series.valid?
        validator.check_dates_exist dates_existing
        validator.validate
      end
      @series.errors.none?
    end

    def self.restore_requests(series, stored_requests)
      request_preserver = DeploymentWindow::SeriesRequestPreserver.new(series)
      request_preserver.restore_requests stored_requests
    end

    private

      def environments_to_delete
        @series.environment_ids_old - @series.environment_ids_new
      end

      def environments_to_create
        @series.environment_ids_new - @series.environment_ids_old
      end

      def build_occurrences
        if recurrent?
          build_recurrent_occurrences
        else
          build_nonrecurrent_occurrences
        end
      end

      def update_occurrences
        if recurrent?
          update_recurrent_occurrences
        else
          update_nonrecurrent_occurrences if non_recurrent_changed? || environments_changed?
        end
      end

      def build_nonrecurrent_occurrences
        series_env_ids = @series.environment_ids
        if series_env_ids.nil?
          series_env_ids = Array.new
        end
        @series.occurrences.create(position: 1,
                                   start_at: @series.start_at,
                                   finish_at: @series.finish_at,
                                   environment_ids: series_env_ids,
                                   environment_names: @series.environment_names,
                                   name: @series.name,
                                   behavior: @series.behavior)
      end

      def build_recurrent_occurrences
        @series.lock!
        DeploymentWindow::SeriesBackgroundable.background.create_recurrent_occurrences(@series.id, @series.environment_ids)
      end

      def update_nonrecurrent_occurrences
        if non_recurrent_changed?
          @series.quick_delete_occurrences
          build_nonrecurrent_occurrences
        else
          occurrence = @series.occurrences.first
          DeploymentWindow::Event.where(occurrence_id: occurrence.id, environment_id: environments_to_delete).delete_all
          occurrence.environment_ids = environments_to_create
          occurrence.attributes = { position: 1,
                                    start_at: @series.start_at,
                                    finish_at: @series.finish_at,
                                    environment_names: @series.environment_names,
                                    name: @series.name,
                                    behavior: @series.behavior }
          occurrence.save
        end
      end

      def update_recurrent_occurrences
        if recurrent_changed?
          store_requests
          update_recurrent_occurrences_and_restore_requests
        elsif @series.environments_changed?
          update_recurrent_occurrences_environments
        end
      end

      def update_recurrent_occurrences_and_restore_requests
        @series.lock!
        DeploymentWindow::SeriesBackgroundable.background.recreate_recurrent_occurrences_and_restore_requests @series.id,
                                                                                         @series.environment_ids,
                                                                                         @series.stored_requests
      end

      def update_recurrent_occurrences_environments
        @series.lock!
        DeploymentWindow::SeriesBackgroundable.background.update_recurrent_occurrences_environments @series.id,
                                                                                            @series.environment_ids_to_create,
                                                                                            @series.environment_ids_to_delete
      end

      def store_requests
        request_preserver = DeploymentWindow::SeriesRequestPreserver.new @series
        request_preserver.store_requests
      end

      def send_notification
        @series.requests.each { |request| Notifier.delay.series_with_requests_update(request, @series) }
      end

      def non_recurrent_changed?
        @non_recurrent_changed ||= @series.non_recurrent_changed?
      end

      def recurrent_changed?
        @recurrent_changed ||= @series.recurrent_changed?
      end

      def environments_changed?
        @environments_changed ||= @series.environments_changed?
      end

      def environments
        Environment.where id: @series.environment_ids
      end

      def environment_names
        environments.order(:name).pluck(:name).join(', ')
      end

      # TODO: move it to series validator
      def dates_existing
        dates_existing = {}
        %w(start_at finish_at).map do |attr_name|
          # We don't have start_at(xi) params in case of REST
          if @params[:deployment_window_series].has_key?(:"#{attr_name}(1i)")
            valid = Date.valid_date? @params[:deployment_window_series][:"#{attr_name}(1i)"].to_i,
                                     @params[:deployment_window_series][:"#{attr_name}(2i)"].to_i,
                                     @params[:deployment_window_series][:"#{attr_name}(3i)"].to_i
          else
            valid = true
          end
          @series.send(:"#{attr_name}=", nil) unless valid
          dates_existing[:"#{attr_name}_invalid"] = !valid
        end
        dates_existing
      end
  end
end
