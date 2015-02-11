class RequestApplicationEnvironmentPreloader
  def initialize(requests)
    @requests = Array(requests)
    @application_environments_hash = {}
  end

  def preload
    preload_requests_application_environments if @requests.size > 0

    @requests
  end

  private

  def preload_requests_application_environments
    build_application_environments_hash
    fill_in_requests
  end

  def build_application_environments_hash
    requests_application_environments.each do |app_env|
      key = app_env_hash_key(app_env.app_id, app_env.environment_id)
      @application_environments_hash[key] = app_env
    end
  end

  def fill_in_requests
    @requests.each do |request|
      request.application_environments = request_application_environments(request)
    end
  end

  def request_application_environments(request)
    request.apps.map do |app|
      key = app_env_hash_key(app.id, request.environment_id)
      @application_environments_hash[key]
    end.compact
  end

  def requests_application_environments
    ApplicationEnvironment.
        where(app_id: request_app_ids).
        where(environment_id: request_env_ids)
  end

  def app_env_hash_key(app_id, environment_id)
    "#{app_id}_#{environment_id}"
  end

  def request_app_ids
    request_app_ids = []

    @requests.each do |request|
      request_app_ids |= request.apps.map(&:id)
    end

    request_app_ids
  end

  def request_env_ids
    @requests.map { |request| request.environment_id }.uniq
  end
end 