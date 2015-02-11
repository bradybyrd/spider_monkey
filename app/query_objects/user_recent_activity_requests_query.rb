class UserRecentActivityRequestsQuery
  attr_reader :user
  private :user

  def initialize(user=User.current_user)
    @user = user
  end

  def server_recent_activity_requests(server)
    user.requests
        .functional
        .with_server_id(server.id)
        .in_most_recent_order
        .all
        .uniq
  end

  def environment_recent_activity_requests(environment)
    user.requests
        .functional
        .with_env_id(environment.id)
        .in_most_recent_order
  end

  def application_recent_activity_requests(application)
    user.requests
        .functional
        .with_app_id(application.id)
        .include_apps
        .in_most_recent_order
  end
  alias_method :app_recent_activity_requests, :application_recent_activity_requests
end
