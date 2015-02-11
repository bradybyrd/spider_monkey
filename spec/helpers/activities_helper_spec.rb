require "spec_helper"

describe ActivitiesHelper do
  context "#custom_value_name" do
    it "returns name_of_index" do
      @user = create(:old_user)
      helper.custom_value_name(@user).should eql("#{@user.last_name}, #{@user.first_name}")
    end

    it "returns name" do
      @step = create(:step)
      helper.custom_value_name(@step).should eql(@step.name)
    end

    it "returns obj" do
      @step = create(:step)
      @step.stub(:respond_to?).and_return(false)
      helper.custom_value_name(@step).should eql(@step)
    end
  end

  context "#custom_value_id" do
    before(:each) { @step = create(:step) }

    it "returns id" do
      helper.custom_value_id(@step).should eql(@step.id)
    end

    it "returns obj" do
      @step.stub(:is_a?).and_return(false)
      helper.custom_value_id(@step).should eql(@step)
    end
  end

  it "#currency_column_contents value" do
    helper.currency_column_contents('value').should eql("<div class=\"currency\">$&lt;div class=&quot;right&quot;&gt;0&lt;/div&gt;</div>")
  end

  describe '#widget_requests' do
    it 'shows requests with environments which user has in his group' do
      application_with_environment = create :app, environments: [ create(:environment) ]
      activity = create :activity
      request_with_assigned_environment = create_request_with_assigned_environment(activity, application_with_environment)
      create_request_with_unassigned_environment(activity)
      helper.stub(:current_user).and_return(user_on_application(application_with_environment))

      requests = helper.widget_requests(activity)

      expect(requests).to include request_with_assigned_environment
    end

    it 'does not show requests with environments which user does not have in his group' do
      application_with_environment = create :app, environments: [ create(:environment) ]
      activity = create :activity
      create_request_with_assigned_environment(activity, application_with_environment)
      request_with_unassigned_environment = create_request_with_unassigned_environment(activity)
      helper.stub(:current_user).and_return(user_on_application(application_with_environment))

      requests = helper.widget_requests(activity)

      expect(requests).not_to include request_with_unassigned_environment
    end

    def create_request_with_assigned_environment(activity, application_with_environment)
      create :request, environment: application_with_environment.environments.first, apps: [ application_with_environment ], activity_id: activity.id
    end

    def create_request_with_unassigned_environment(activity)
      create :request_with_app, activity_id: activity.id
    end

    def user_on_application(application)
      user = create(:user, :non_root, apps: [ application ])
      allow(user).to receive(:can?).with(:view_created_requests_list, an_instance_of(Request)).and_return(true)
      create(:team, groups: user.groups, apps: [application])
      user.update_assigned_apps
      user
    end
  end
end
