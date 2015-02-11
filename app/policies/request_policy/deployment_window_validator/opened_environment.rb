module RequestPolicy
  module DeploymentWindowValidator
    class OpenedEnvironment < Base
      attr_reader :request
      delegate :start, :finish, :errors, :deployment_window_event, :environment, to: :request

      def initialize(request, ignore_states)
        @request        = request
        @ignore_states  = ignore_states
      end

      def requires_dwe_dependencies?
        any_preventing_dwe_exists? && request_started?
      end

      def requires_deployment_window_event?
        false
      end

      # no deployment_window_event required
      def deployment_window_event_suspended?
        false
      end

      def any_preventing_dwe_exists?
        environment.deployment_window_events.not_suspended.not_archived.preventing.count > 0
      end

      def check_if_valid_with_dwe
        overlays_with_preventing_dwe! if overlays_with_preventing_dwe?
      end

      def overlays_with_preventing_dwe?
        count = DeploymentWindow::Event.
            where('deployment_window_events.start_at < ? and deployment_window_events.finish_at > ? ', finish, start).
            where(environment_id: environment.id).
            preventing.
            not_suspended.
            not_passed.
            not_archived.
            series_visible.
            count
        count > 0
      end

      def overlays_with_preventing_dwe!
        errors.add(:base, I18n.t('request.deployment_window.overlays_with_preventing_dwe', environment_name: request.environment.name))
      end

      def estimate_missing!
        errors.add(:base, I18n.t('request.deployment_window.opened_environment.estimate_missing'))
      end

      def scheduled_at_missing!
        errors.add(:base, I18n.t('request.deployment_window.opened_environment.scheduled_at_missing'))
      end
    end
  end
end
