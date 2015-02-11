class EnvironmentImport

  attr_reader :deployment_windows

  def initialize(environments_hash, app)
    @deployment_windows = DeploymentWindow::SeriesImport.new
    @environments_hash = environments_hash
    @app = app
    @environments = environments
    add_envs_to_app
  end

  private

  def environments
    @environments_hash.map do |env_params|
      build_env(env_params)
    end.compact
  end

  def build_env(env_params)
    env = Environment.find_or_initialize_by_name(env_params['name'])
    env = build_env_params(env, env_params)
    env.save!
    @deployment_windows.add(env_params['active_deployment_window_series'], env)
    add_environment_servers(env_params['active_environment_servers'], env)
    env
  end

  def add_environment_servers(env_servers, env)
    if env_servers && env
      server_ids = EnvironmentServer.import_app(env_servers)
      add_servers_to_env(server_ids, env)
    end
  end

  def build_env_params(env, env_params)
    env.environment_type_id = build_env_type(env_params['environment_type'])
    env.server_group_ids = env.server_group_ids | ServerGroupImport.new(env_params['active_server_groups']).ids
    env.active = true
    env.default = false
    if policy_unchanged?(env, env_params)
      env.deployment_policy = env_params['deployment_policy']
    end
    env
  end

  def policy_unchanged?(env, env_params)
    env.new_record? || env_params['deployment_policy'] == env.deployment_policy
  end

  def build_env_type(env_type_params)
    if env_type_params
      env_type = EnvironmentType.import_app(env_type_params)
    end
    env_type.id if env_type
  end

  def add_envs_to_app
    (@environments.map(&:id) - @app.environment_ids).each do |environment_id|
      @app.application_environments.create(environment_id: environment_id)
    end
  end

  def add_servers_to_env(server_ids, env)
    if server_ids.any?
      (server_ids - env.server_ids).each do |server_id|
        env.environment_servers.create(server_id: server_id)
      end
    end
  end
end