require "spec_helper"

describe DashboardHelper do
  context "#request_filter_options" do
    specify "model == User" do
      @user = create(:old_user)
      helper.request_filter_options(User, nil, 'first_name').should include("#{@user.id}")
    end

    specify "model == Environment" do
      @env = create(:environment)
      helper.request_filter_options(Environment, nil).should include("#{@env.id}")
    end

    specify "model == Array" do
      @envs = 5.times.collect{ create(:environment) }
      @result = helper.request_filter_options(@envs, nil)
      @envs.each{ |el| @result.should include("#{el.id}") }
    end
  end

  context "#whose_requests" do
    it "returns 'Requests'" do
      @show_all = true
      helper.whose_requests.should eql('Requests')
    end

    it "returns 'My Requests'" do
      helper.stub(:params).and_return({:for_dashboard => true})
      helper.whose_requests.should eql('My Requests')
    end
  end

  context "#class_per_page_path" do
    it "returns 'current'" do
      helper.class_per_page_path("calendar").should eql('current')
    end

    it "returns nothing" do
      helper.class_per_page_path("requests").should eql('')
    end
  end

  context "#partial_as_per_page_path" do
    specify "promotions" do
      @page_path = '/promotion_requests/'
      helper.partial_as_per_page_path.should eql('promotions')
    end

    specify "requests" do
      @page_path = '/my-dashboard/'
      helper.partial_as_per_page_path.should eql("requests")
    end

    specify "currently_running_steps" do
      @page_path = '/dashboard/'
      helper.partial_as_per_page_path.should eql("currently_running_steps")
    end

    specify "currently_running_steps" do
      @page_path = '/currently_running/'
      helper.partial_as_per_page_path.should eql("currently_running_steps")
    end

    specify "calendar" do
      @page_path = '/calendars/'
      helper.partial_as_per_page_path.should eql("calendar")
    end
  end

  context "#find_releases" do
    it "returns release name" do
      helper.stub(:can?).and_return(true)
      @app = create(:app)
      @release = create(:release)
      @request1 = create(:request, :release => @release)
      @app_request = create(:apps_request, :app => @app, :request => @request1)
      @plan = create(:plan, :plan_template => create(:plan_template), :release => @release)
      @plan_member = create(:plan_member, :plan => @plan, :request => @request1)
      helper.find_releases([@request1], @app).should include(@release.name)
    end

    it "returns '-'" do
      helper.find_releases([]).should eql('-')
    end
  end

  it "#request_list_preferences" do
    helper.stub(:current_user).and_return(create(:old_user))
    helper.request_list_preferences.length.should eql(0)
  end

  it "#plan_run_select_list_with_stage" do
    helper.stub(:current_user).and_return(create(:old_user))
    @plan = create(:plan)
    helper.plan_run_select_list_with_stage.should eql("")
  end
end
