module RequestPolicy
  module DeploymentWindowValidator
    class Base
      attr_accessor :environment, :request
      attr_reader   :ignore_states, :validator_for_environment
      delegate      :created?, :planned?, :aasm_state_changed?, :started?, :deployment_window_event, :scheduled_at,
                    :estimate, to: :request

      def initialize(instance, options = {})
        @request                        = instance
        @ignore_states                  = options.fetch :ignore_states, false
        self.validator_for_environment  = request.environment
      end

      def check_deployment_window_event
        validator_for_environment.validate
      end

      protected

      def validate
        if requires_dwe_dependencies?
          check_for_dwe_dependencies
        end

        # if request on closed env has dwe
        if requires_deployment_window_event?
          deployment_window_event_missing! unless deployment_window_event
        end

        # if request on closed env fits into dwe in case request has estimate and scheduled_at
        # if request on opened env does not overlay with preventing dwe in case request has estimate and scheduled_at
        if estimate.present? && scheduled_at.present?
          validate_with_dwe if aasm_states_to_check
        end
      end

      # request state to perform validations for
      def aasm_states_to_check
        created? ||
            (planned? && !aasm_state_changed? ) || # exclude validation on transition from created to planned
            started? ||
            ignore_states
      end

      def request_started?
        started? || ignore_states
      end

      def check_for_dwe_dependencies
        estimate_missing!     unless estimate
        scheduled_at_missing! unless scheduled_at
      end

      def validate_with_dwe
        if request.environment.name == Environment::DEFAULT_NAME
          'skipping validations'
        else
          check_if_valid_with_dwe
        end
      end

      def deployment_window_event_missing!
        errors.add(:base, 'You are about to start a request that haven\'t passed validation on Deployment Windows. Request will not be started until you update Planned Start/Estimate/Deployment Window info')
      end

      private

      def validator_for_environment=(environment)
        if environment.closed?
          @validator_for_environment = ClosedEnvironment.new request, ignore_states
        elsif environment.opened?
          @validator_for_environment = OpenedEnvironment.new request, ignore_states
        end
      end

    end
  end
end