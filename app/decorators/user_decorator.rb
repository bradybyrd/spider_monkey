class UserDecorator < Draper::Decorator
  def visible_recent_activity_requests(resource)
    requests = recent_activity_requests(resource)
    RequestApplicationEnvironmentPreloader.new(requests).preload
    requests.select { |request| !request.created? || object.can?(:view_created_requests_list, request) }
  end

  private

    def recent_activity_requests(resource)
      method_name = :"#{underscored_class_name(resource)}_recent_activity_requests"
      user_query.respond_to?(method_name) ? user_query.send(method_name, resource) : []
    end

    def user_query
      @user_query ||= UserRecentActivityRequestsQuery.new object
    end

    def underscored_class_name(resource)
      resource.class.name.demodulize.underscore
    end
end
