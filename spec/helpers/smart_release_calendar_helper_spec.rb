require "spec_helper"

describe SmartReleaseCalendarHelper do
  let(:app) { create(:app) }
  let(:request) { create(:request) }
  let(:business_process) { create(:business_process) }

  it "#show_request" do
    request.apps = [app]
    helper.stub(:request_calendar_content).and_return('content')
    helper.show_request(request).should include("class=\"app1")
  end

  describe "#request_calendar_content" do
    before(:each) do
      request.apps = [app]
      helper.stub(:user_signed_in?).and_return(false)
      helper.stub(:current_user).and_return(create(:user, :non_root))
    end

    context "returns content with" do
      it "business_process_name" do
        GlobalSettings[:calendar_preferences] = "business_process_name"
        request.business_process = business_process
        helper.request_calendar_content(request).should include("#{business_process.name}")
      end

      it "release_name" do
        GlobalSettings[:calendar_preferences] = "release_name"
        request.release = create(:release)
        helper.request_calendar_content(request).should include("#{request.release.name}")
      end

      it "app_name" do
        GlobalSettings[:calendar_preferences] = "app_name"
        helper.request_calendar_content(request).should include("#{app.name}")
      end

      it "environment_name" do
        GlobalSettings[:calendar_preferences] = "environment_name"
        request.environment = create(:environment)
        helper.request_calendar_content(request).should include("#{request.environment.name}")
      end

      it "package_content_tags" do
        GlobalSettings[:calendar_preferences] = "package_content_tags"
        request.request_package_contents.create(:package_content_id => create(:package_content).id)
        PackageContent.update_abbreviations!
        helper.request_calendar_content(request).should include("<br/>#{request.package_content_tags}")
      end

      it "lifecyle_name" do
        GlobalSettings[:calendar_preferences] = "lifecyle_name"
        request.stub(:plan).and_return(create(:plan))
        helper.request_calendar_content(request).should include("#{request.plan.name}")
      end

      it "project_name" do
        GlobalSettings[:calendar_preferences] = "project_name"
        request.activity = create(:activity)
        helper.request_calendar_content(request).should include("#{request.activity.name}")
      end

      it "associated_servers" do
        GlobalSettings[:calendar_preferences] = "associated_servers"
        request.stub(:associated_servers).and_return(create(:server).name)
        helper.request_calendar_content(request).should include("#{request.associated_servers}")
      end

      it "rescheduled" do
        GlobalSettings[:calendar_preferences] = "rescheduled"
        request.stub(:rescheduled?).and_return(true)
        helper.request_calendar_content(request).should include("Rescheduled: Yes")
      end

      it "estimate" do
        GlobalSettings[:calendar_preferences] = "estimate"
        request.estimate = 3600
        helper.request_calendar_content(request).should include("Estimate: 60:00 (hh:mm)")
      end

      it "team" do
        GlobalSettings[:calendar_preferences] = "team"
        team = create(:team)
        request.apps.stub(:map).and_return([team])
        helper.request_calendar_content(request).should include("#{team.name}")
      end

      it "aasm.current_state" do
        GlobalSettings[:calendar_preferences] = "aasm.current_state"
        helper.request_calendar_content(request).should include("#{request.aasm.current_state}")
      end

      it "time_source" do
        GlobalSettings[:calendar_preferences] = ""
        request.stub(:calendar_ready?).and_return(true)
        request.started_at = Time.now
        request.save
        helper.request_calendar_content(request).should include("Started: #{request.started_at.to_s(:time_only)}")
      end
    end
  end

  it "#style_for_process" do
    helper.style_for_process(business_process).should eql(business_process.label_color)
  end

  describe "#conditional_truncate" do
    it "returns value" do
      helper.conditional_truncate('v'*21, true).should eql('v'*17+'...')
    end

    it "returns ..." do
      helper.conditional_truncate('val', false).should eql('val')
    end
  end
end
