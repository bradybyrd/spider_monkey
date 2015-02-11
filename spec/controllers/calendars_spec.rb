require "spec_helper"

describe CalendarsController, :type => :controller do
  describe "#month" do
    it 'renders template' do
      get :month, {:beginning_of_calendar => '10/12/2013'}
      response.should render_template('calendars/calendar')
    end

    context 'signed out' do
      it 'GET /calendars/dashboard/month' do
        User.stub(:admins).and_return([@user])
        sign_out @user

        get :month

        expect(response).to be_success
      end
    end

    it_behaves_like 'authorizable', controller_action: :month,
                                    ability_action: :view_calendar,
                                    subject: Request
  end

  describe "#day" do
    it 'renders template' do
      get :day, {:beginning_of_calendar => '10/12/2013'}
      response.should render_template('calendars/calendar')
    end

    context 'signed out' do
      it 'GET /calendars/dashboard/day' do
        User.stub(:admins).and_return([@user])
        sign_out @user

        get :day

        expect(response).to be_success
      end
    end

    it_behaves_like 'authorizable', controller_action: :day,
                                    ability_action: :view_calendar,
                                    subject: Request
  end

  describe "#week" do
    it 'renders template' do
      get :week, {:beginning_of_calendar => '10/12/2013'}
      response.should render_template('calendars/calendar')
    end

    context 'signed out' do
      it 'GET /calendars/dashboard/week' do
        User.stub(:admins).and_return([@user])
        sign_out @user

        get :week

        expect(response).to be_success
      end
    end

    it_behaves_like 'authorizable', controller_action: :week,
                                    ability_action: :view_calendar,
                                    subject: Request
  end

  describe "#rolling" do
    it 'renders template' do
      get :rolling, {:beginning_of_calendar => '10/12/2013'}
      response.should render_template('calendars/calendar')
    end

    context 'signed out' do
      it 'GET /calendars/dashboard/rolling' do
        User.stub(:admins).and_return([@user])
        sign_out @user

        get :rolling

        expect(response).to be_success
      end
    end

    it_behaves_like 'authorizable', controller_action: :rolling,
                                    ability_action: :view_calendar,
                                    subject: Request
  end

  describe "#upcoming_requests" do
    it do
      get :upcoming_requests, {:beginning_of_calendar => '10/12/2013'}
      response.should render_template('calendars/calendar')
    end

    it_behaves_like 'authorizable', controller_action: :upcoming_requests,
                                    ability_action: :view_calendar,
                                    subject: Request
  end

  it "redirects to" do
    get :rolling, {:beginning_of_calendar => '10/12/2013',
                   :display_format => 'day',
                   :for_dashboard => true}
    response.should redirect_to('/calendars/dashboard/day/10/12/2013')
  end

  specify "format_date with GlobalSettings" do
    GlobalSettings[:default_date_format].stub(:include?).and_return(true)
    get :rolling, {:beginning_of_calendar => '10-12-2013'}
  end

  specify "format_date without GlobalSettings" do
    get :rolling, {:beginning_of_calendar => '10-12-2013'}
  end

  it "#preserve_fiters" do
    get :rolling, {:beginning_of_calendar => '10-12-2013',
                   :clear_filter => true,
                   :filters => {:beginning_of_calendar => "01/10/2013",
                                :end_of_calendar => "12/10/2013"}}
    assigns(:filters).should include({:beginning_of_calendar => "01/10/2013",
                                      :end_of_calendar => "12/10/2013"})
  end

  specify "#calculate_date" do
    get :rolling, {:date_start => 10}
    assigns(:date).should eql(Date.strptime "10/01/#{Date.today.year}", '%m/%d/%Y')
  end

  it "renders partial calendar with plan" do
    @plan = create(:plan)
    xhr :get, :upcoming_requests, {:beginning_of_calendar => '10/12/2013',
                                   :plan_id => @plan.id}
    response.should render_template(:partial => "dashboard/self_services/_calendar.html")
  end

  it "renders template self_services" do
    get :upcoming_requests, {:beginning_of_calendar => '10/12/2013',
                             :for_dashboard => true}
    response.should render_template("dashboard/self_services")
  end

  it "renders template plans/calendar" do
    @plan = create(:plan)
    get :upcoming_requests, {:beginning_of_calendar => '10/12/2013',
                             :plan_id => @plan.id}
    response.should render_template("plans/calendar")
  end

  it "returns pdf" do
    get :rolling, {:beginning_of_calendar => '10/12/2013',
                   :pdf_type => 'pdf',
                   :export => true,
                   :format => 'pdf'}
    response.should render_template("calendars/pdf")
  end

  it "returns csv" do
    get :upcoming_requests, {:beginning_of_calendar => '10/12/2013',
                             :format => 'csv'}
    request.body.should_not be_nil
  end
end
