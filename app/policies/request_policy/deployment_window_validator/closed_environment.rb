module RequestPolicy
  module DeploymentWindowValidator
    class ClosedEnvironment < Base
      attr_reader :request
      delegate :start, :finish, :errors, :deployment_window_event, :environment, to: :request

      def initialize(request, ignore_states)
        @request        = request
        @ignore_states  = ignore_states
      end

      def requires_dwe_dependencies?
        deployment_window_event.present?
      end

      def requires_deployment_window_event?
        environment.present? if request_started?
      end

      def deployment_window_event_suspended?
        deployment_window_event.suspended? if deployment_window_event
      end

      def check_if_valid_with_dwe
        dw_is_suspended!          if deployment_window_event_suspended?
        fits_not_to_allowing_dwe! if deployment_window_event && !fits_to_allowing_dwe? && !deployment_window_event_suspended?
      end

      def fits_to_allowing_dwe?
        deployment_window_event.start_at <= start && deployment_window_event.finish_at >= finish
      end

      def fits_not_to_allowing_dwe!
        errors.add(:base, I18n.t('request.deployment_window.fits_not_to_allowing_dwe'))
      end

      def dw_is_suspended!
        errors.add(:base, I18n.t('request.deployment_window.dw_is_suspended'))
      end

      def estimate_missing!
        errors.add(:base, I18n.t('request.deployment_window.closed_environment.estimate_missing'))
      end

      def scheduled_at_missing!
        errors.add(:base, I18n.t('request.deployment_window.closed_environment.scheduled_at_missing'))
      end
    end
  end
end