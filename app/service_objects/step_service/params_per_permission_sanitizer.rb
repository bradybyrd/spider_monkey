module StepService
  class ParamsPerPermissionSanitizer

    attr_reader :params, :request, :user

    def initialize(params, request, user)
      @params = params
      @request = request
      @user = user
    end

    def clean_up_params!
      attributes_per_action.each do |action, attributes|
        sanitize_for_action!(action, attributes)
      end
    end

    private

    def sanitize_for_action!(action, attributes)
      params.except!(*attributes) if user.cannot?(action, request)
    end

    def attributes_per_action
      {
        select_step_component: [:component_id],
        select_step_package: [:package_id, :step_references],
        edit_step_component_versions: [:version, :own_version],
        select_step_instance: [:package_instance_id, :latest_package_instance, :create_new_package_instance]
      }
    end
  end
end
