module MultipleEnvsRequestForm
  class << self

    def parse_env_ids_from_params(params)
      return [] unless params[:request].has_key?(:environment_ids)

      environment_ids = params[:request].delete(:environment_ids)
      environment_ids.split(',') if environment_ids.present?
    end

    def create_multiple_requests(request, environment_ids, params)
      environment_ids.drop(1).each { |env_id|
        params[:request][:environment_id] = env_id
        request.clone_request_with_dependencies(params)
      }
    end

    def instantiate_multiple_requests(request_template, environment_ids, params)
      form_params = params[:request].dup
      environment_ids.drop(1).each { |env_id|
        params[:request] = form_params.dup
        params[:request][:environment_id] = env_id
        request_template.instantiate_request(params)
      }
    end

    def no_one_environment?(req_params, environment_ids)
      req_params[:app_ids].present? && req_params[:environment_id].blank? && environment_ids.blank?
    end
  end
end
