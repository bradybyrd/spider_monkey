require 'spec_helper'

describe UserDecorator do
  describe '#visible_recent_activity_requests' do
    it 'selects only visible requests' do
      requests = create_list(:request, 3)
      not_visible_request = requests[0]
      user = create :user
      user.stub(:can?).with(:view_created_requests_list, anything).and_return(true)
      user.stub(:can?).with(:view_created_requests_list, not_visible_request).and_return(false)
      resource = double :some_resource
      UserRecentActivityRequestsQuery.any_instance.stub(:double_recent_activity_requests).and_return(requests)

      recent_activity_requests = UserDecorator.new(user).visible_recent_activity_requests(resource)

      expect(recent_activity_requests).not_to include not_visible_request
    end
  end
end
