module PackageInstancesHelper
  def recent_activity_for(package_instance)
    package_instance.recent_activity.map do |request|
      link_request_if_accessible(request.number)
    end.to_sentence
  end

  def link_request_if_accessible(request_id)
    if (requests_inspectable?)
      link_to(request_id, request_path(request_id))
    elsif (requests_accessible?)
      request_id
    end
  end

  def requests_inspectable?
    can?(:inspect, Request.new)
  end

  def requests_accessible?
    can?(:view_requests_list, Request.new)
  end
end
