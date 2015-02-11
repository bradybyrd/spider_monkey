################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

require 'spec_helper'

describe Notifier do

  before(:all) do
    @user = create(:user)
  end

  before(:each) do
    Notifier.default_url_options = { :host => 'streamstep.dev'}
    GlobalSettings.instance.update_attributes!(:company_name => 'Bob Corp')
    User.stub(:current_user) { @user }
  end

  after(:all) do
    User.destroy_all
  end

  #
  # A test for the system message upon exceptions
  #
  describe '#deliver_exception_raised' do

    describe 'with template subject line' do
      before do
        exception = Exception.new("Sumthin' broked.")
        # reset the generic template to the exception body
        @template = mock_model(NotificationTemplate,
                                 :format => 'text/html',
                                 :subject => 'Exception raised at {{params.SS_company_name}} using template subject',
                                 :body => '<p>The following exception was raised at {{params.SS_company_name}}:</p> <br/> {% if params.SS_exception_message %} <p><strong>Message:</strong></p> <p>{{params.SS_exception_message}}</p> {% endif %} {% if params.SS_exception_backtrace %} <p><strong>Backtrace:</strong></p> <p>{{params.SS_exception_backtrace}}</p> {% endif %}'
                                 )
        NotificationTemplate.stub(:where).and_return [@template]
        @mail = Notifier.exception_raised(exception)
      end

      it 'should have a content type of text/html' do
        @mail.content_type.should include('text/html')
      end

      it 'should set the subject' do
        @mail.subject.should == 'Exception raised at Bob Corp using template subject'
      end

      it 'should have a body including the exception and the company name' do
        @mail.body.should include('broked.')
        @mail.body.should include('Bob Corp')
      end

      it "should be to #{DEFAULT_SUPPORT_EMAIL_ADDRESS}" do
        @mail.to.should include("#{DEFAULT_SUPPORT_EMAIL_ADDRESS}")
      end

      it 'should be from no-reply' do
        @mail.from.should include('no-reply@example.com')
      end
    end

    describe 'without template subject line' do
      before do
        exception = Exception.new("Sumthin' broked.")
        # reset the generic template to the exception body
        @template = mock_model(NotificationTemplate,
                                 :format => 'text/html',
                                 :subject => nil,
                                 :body => '<p>The following exception was raised at {{params.SS_company_name}}:</p> <br/> {% if params.SS_exception_message %} <p><strong>Message:</strong></p> <p>{{params.SS_exception_message}}</p> {% endif %} {% if params.SS_exception_backtrace %} <p><strong>Backtrace:</strong></p> <p>{{params.SS_exception_backtrace}}</p> {% endif %}'
                                 )
        NotificationTemplate.stub(:where).and_return [@template]
        @mail = Notifier.exception_raised(exception)
      end

      it 'should set the default subject' do
        @mail.subject.should == 'Exception raised at Bob Corp'
      end

    end
  end

  #
  # A set of nested tests that set up a user and related headers
  # and run the messages available for users
  #
  describe 'deliver user messages' do

    before do
      @user = mock_model(User, :email => 'e@mail.com', :login => 'bob_login', :password => 'secret', :first_name => 'Bob',
                         :last_name => 'Aaron', admin?: false, name: 'Aaron, Bob')
      @admin_user = mock_model(User, email: 'e@mail.com', login: 'bob_login', password: 'secret', first_name: 'Bob',
                               last_name: 'Taylor', admin?: true, name: 'Taylor, Bob')
      @user.stub(:headers_for_user).and_return({
        'SS_user_login' => @user.login,
        'SS_user_email' => @user.email,
        'SS_user_password' => @user.password,
        'SS_user_first_name' => @user.first_name
      })
    end

    describe '#deliver_user_created' do
      context 'with template' do
        describe 'subject line' do
          before do
            @template = mock_model(NotificationTemplate,
                                   :format => 'text/html',
                                   :subject => 'Welcome to BMC Release Lifecycle Management - {{ params.SS_user_first_name }} says my template',
                                   :body => 'Hi {{ params.SS_user_login }}, Login: {{ params.SS_user_login }} Password: {{ params.SS_user_password }} {{ params.SS_login_url }}' )
            NotificationTemplate.stub(:where).and_return [@template]
            @mail = Notifier.user_created(@user, @admin_user)
          end

          it 'has a content type of text/html' do
            @mail.content_type.should include('text/html')
          end

          it 'has a subject line that includes the user name' do
            @mail.subject.should include('Welcome to BMC Release Lifecycle Management - Bob says my template')
          end

          it 'has a body that includes username and password' do
            @mail.body.should include('bob_login')
            @mail.body.should include('secret')
          end

          it 'includes a link to the login url for the site' do
            @mail.body.should include('http://streamstep.dev')
          end
        end
      end

      context 'without template' do
        describe 'subject line' do
          before do
            @template = mock_model(NotificationTemplate,
                                   :format => 'text/html',
                                   :subject => nil,
                                   :body => 'Hi {{ params.SS_user_login }}, Login: {{ params.SS_user_login }} Password: {{ params.SS_user_password }} {{ params.SS_login_url }}' )
            NotificationTemplate.stub(:where).and_return [@template]
            @mail = Notifier.user_created(@user, @admin_user)
          end

          it 'includes the user name' do
            @mail.subject.should include('Welcome to BMC Release Process Management - Aaron, Bob')
          end

        end
      end
    end

    describe '#new_user_email_verification_failed' do
      context 'with a template subject line' do
        before(:each) do
          @template = mock_model(NotificationTemplate,
                                 :format => 'text/html',
                                 :subject => 'New user email notification failed',
                                 :body => 'Hi {{ params.SS_user_login }}, A user account for {{params.SS_user_first_name}},
{{params.SS_user_last_name}} has recently been created, but email notification failed:
NEW ACCOUNT
============
Account username is:
{{params.SS_user_login}}
{{params.SS_user_email}}
LOGGING IN TO BMC RELEASE PROCESS MANAGEMENT
==============================
{{params.SS_login_url}}
ISSUES
==============================
{{params.default_support_email}}
and we will respond as quickly as possible--usually within 1 hour between 8am
and 5pm EST.
Thanks,
BRPM Admin' )
          NotificationTemplate.stub(:where).and_return [@template]
          @mail = Notifier.new_user_email_verification_failed(@user, @admin_user)
        end

        it 'should have a content type of text/html' do
          @mail.content_type.should include('text/html')
        end

        it 'should have a body that includes username but not the password' do
          @mail.body.should include('bob_login')
          @mail.body.should_not include('secret')
        end

        it 'should include a link to the login url for the site' do
          @mail.body.should include('http://streamstep.dev')
        end

        it 'should include new user first_name' do
          @mail.body.should include('Bob')
        end

        it 'should include new user last_name' do
          @mail.body.should include('Bob')
        end

        it 'should include new user last_name' do
          @mail.body.should include('Bob')
        end

        it 'should have a subject line that indicates purpose of email' do
          @mail.subject.should include('New user email notification failed')
        end

      end
    end

    describe '#deliver_user_password_changed' do
      describe 'with a template subject line' do
        before do
          @template = mock_model(NotificationTemplate,
                                  :format => 'text/html',
                                  :subject => 'You have recently changed your password changed by template',
                                  :body => 'Hi {{ params.SS_user_login }}, Your account username is: {{params.SS_user_login}} {{params.SS_login_url}}')
          NotificationTemplate.stub(:where).and_return [@template]
          @mail = Notifier.password_changed(@user, @admin_user)
        end

        it 'should have a content type of text/html' do
          @mail.content_type.should include('text/html')
        end

        it 'should have a subject line that indicates purpose of email' do
          @mail.subject.should include('You have recently changed your password changed by template')
        end

        it 'should have a body that includes username but not the password' do
          @mail.body.should include('bob_login')
          @mail.body.should_not include('secret')
        end

        it 'should include a link to the login url for the site' do
          @mail.body.should include('http://streamstep.dev')
        end
      end

      describe 'without a template subject line' do
        before do
          @template = mock_model(NotificationTemplate,
                                  :format => 'text/html',
                                  :subject => nil,
                                  :body => 'Hi {{ params.SS_user_login }}, Your account username is: {{params.SS_user_login}} {{params.SS_login_url}}')
          NotificationTemplate.stub(:where).and_return [@template]
          @mail = Notifier.password_changed(@user, @admin_user)
        end

        it 'should have a subject line that indicates purpose of email' do
          @mail.subject.should include('You have recently changed your password')
        end

      end
    end

    describe '#deliver_user_password_reset' do

      describe 'with a template subject line' do
        before do
          @template = mock_model(NotificationTemplate,
                                    :format => 'text/html',
                                    :subject => 'You have recently requested to reset your account password made fancy by this template',
                                    :body => 'Hi {{ params.SS_user_login }}, Your account username is: {{params.SS_user_login}} Your account password is: {{params.SS_user_password}} {{params.SS_login_url}}')
          NotificationTemplate.stub(:where).and_return [@template]
          @mail = Notifier.password_reset(@user, @admin_user)
        end

        it 'should have a content type of text/html' do
          @mail.content_type.should include('text/html')
        end

        it 'should have a subject line that indicates purpose of email' do
          @mail.subject.should include('You have recently requested to reset your account password made fancy by this template')
        end

        it 'should have a body that includes username and initial password' do
          @mail.body.should include('bob_login')
          @mail.body.should include('secret')
        end

        it 'should include a link to the login url for the site' do
          @mail.body.should include('http://streamstep.dev')
        end
      end

      describe 'without a template subject line' do
        before do
          @template = mock_model(NotificationTemplate,
                                  :format => 'text/html',
                                  :subject => 'You have recently requested to reset your account password',
                                  :body => 'Hi {{ params.SS_user_login }}, Your account username is: {{params.SS_user_login}} Your account password is: {{params.SS_user_password}} {{params.SS_login_url}}')
          NotificationTemplate.stub(:where).and_return [@template]
          @mail = Notifier.password_reset(@user, @admin_user)
        end

        it 'should have a subject line that indicates purpose of email' do
          @mail.subject.should include('You have recently requested to reset your account password')
        end

      end
    end

    describe '#user_admin_created' do

      describe 'with a template subject line' do
        before do
          @template = mock_model(NotificationTemplate,
                                    :format => 'text/html',
                                    :subject => 'New remote user account added to BMC Release Lifecycle Management - {{ params.SS_user_login }} and special',
                                    :body => 'Hi {{ params.SS_user_login }}, Your account username is: {{params.SS_user_login}} Your account password is: {{params.SS_user_password}} {{params.SS_login_url}}')
          NotificationTemplate.stub(:where).and_return [@template]
          @mail = Notifier.user_admin_created(@user)
        end
        it 'should have a content type of text/html' do
          @mail.content_type.should include('text/html')
        end

        it 'should have a subject line that indicates purpose of email' do
          @mail.subject.should include('New remote user account added to BMC Release Lifecycle Management - bob_login and special')
        end

        it 'should have a body that includes username and initial password' do
          @mail.body.should include('bob_login')
          @mail.body.should include('secret')
        end

        it 'should include a link to the login url for the site' do
          @mail.body.should include('http://streamstep.dev')
        end
      end

      describe 'without a template subject line' do
        before do
          @template = mock_model(NotificationTemplate,
                                    :format => 'text/html',
                                    :subject => nil,
                                    :body => 'Hi {{ params.SS_user_login }}, Your account username is: {{params.SS_user_login}} Your account password is: {{params.SS_user_password}} {{params.SS_login_url}}')
          NotificationTemplate.stub(:where).and_return [@template]
          @mail = Notifier.user_admin_created(@user)
        end

        it 'should have a subject line that indicates purpose of email' do
          @mail.subject.should include('New remote user account added - bob_login')
        end

      end
    end
  end

  #
  # A set of nested tests that set up a request and related headers
  # and run the messages available for requests
  #
  describe 'deliver request messages' do

    before do
      @message = mock_model(Message, :body => 'This is the body of my message', :subject => 'Message Test Subject')
      @request = mock_model(Request, :name => 'Request Test Name', :mailing_list => DEFAULT_SUPPORT_EMAIL_ADDRESS, :number => 1, :description => 'Request test description', :planned_at => Time.now, :started_at => Time.now)
      @request.stub(:headers_for_request).and_return({
        'request_name' => @request.name.gsub("'","''"),
        'request_status' => 'Stubbed aasm.current_state.to_s',
        'request_plan_member_id' => 'Stubbed lc_member_id',
        'request_plan' => 'Stubbed plan',
        'request_plan_stage' => 'Stubbed plan_stage',
        'request_project' => 'Stubbed project',
        'request_started_at' => "#{@request.started_at}",
        'request_planned_at' => "#{@request.planned_at}",
        'request_owner' => 'Stubbed owner_name_for_index',
        'request_wiki_url' => 'Stubbed wiki_url',
        'request_requestor' => 'Stubbed requestor_name_for_index',
        'request_description' => @request.description.gsub("'","''"),
        'SS_request_number' => @request.number
      })
    end

    describe '#deliver_request_message' do

      before do
        @template = mock_model(NotificationTemplate,
                              :format => 'text/html',
                              :subject => nil,
                              :body => '<p>{{ message }}</p><p>Request: {{params.SS_request_url}}</p>')
        NotificationTemplate.stub(:where).and_return [@template]
        @mail = Notifier.request_message(@request, @message)
      end

      it 'should have a content type of text/html' do
        @mail.content_type.should include('text/html')
      end

      it 'should have a subject line that indicates purpose of email' do
        @mail.subject.should include('Message Test Subject')
      end

      it 'should have a body that includes body of message' do
        @mail.body.should include('This is the body of my message')
      end

      it "should include a link to the url for the request" do
        @mail.body.should include("http://streamstep.dev")
      end
    end

    describe "#deliver_request_completed" do

      pending "undefined method `request_completed' for Notifier:Class" do
        describe "with a templated subject" do
          before do
            @template = mock_model(NotificationTemplate,
                                :format => 'text/html',
                                :subject => "Request {{params.SS_request_number}} is complete and made custom",
                                :body => '<p>Request {{params.SS_request_number}}: {{params.request_name}} is complete.</p> <p>Request: {{params.SS_edit_request_url}}</p>')
            NotificationTemplate.stub(:first).and_return(@template)
            @mail = Notifier.request_completed(@request).deliver
          end

          it "should have a content type of text/html" do
            @mail.content_type.should include("text/html")
          end

          it "should have a subject line that indicates purpose of email" do
            pending do
              @mail.subject.should include("Request 1 is complete and made custom")
            end
          end

          it "should have a body that includes completion status" do
            @mail.body.should include("is complete")
          end

          it "should include a link to the url for the request" do
            @mail.body.should include("http://streamstep.dev")
          end
        end

        describe "without a templated subject" do
          before do
            @template = mock_model(NotificationTemplate,
                                :format => 'text/html',
                                :subject => nil,
                                :body => '<p>Request {{params.SS_request_number}}: {{params.request_name}} is complete.</p> <p>Request: {{params.SS_edit_request_url}}</p>')
            NotificationTemplate.stub(:first).and_return(@template)
            @mail = Notifier.request_completed(@request).deliver
          end

          it "should have a subject line that indicates purpose of email" do
            @mail.subject.should include("Request 1 is complete")
          end

        end
      end

    end

  end

  #
  # A set of nested tests that set up a step and related headers
  # and run the messages available for steps
  #
  describe "deliver step messages" do

    before do
      @note = "Test note for step"
      @user = create(:user, :email => "e@mail.com", :login => "bob_login", :first_name => 'Bob')
      @app = create(:app)
      @env = create(:environment)
      AssignedEnvironment.create!(:environment_id => @env.id, :assigned_app_id => @app.assigned_apps.first.id, :role => @user.roles.first)
      @request = create(:request,
        :name => 'Request Test Name',
        :description => "Request test description",
        :planned_at => Time.now,
        :started_at => Time.now,
        :user => @user,
        :app_ids => [@app.id],
        :environment_id => @env.id)
      @step = create(:step, :name => 'Test Step Name', :position => 1, :request => @request)
    end

    describe "#deliver_step_started" do

      pending "undefined method `step_started' for Notifier:Class" do
        describe "with a templated subject" do
          before do
            @template = mock_model(NotificationTemplate,
                                  :format => 'text/html',
                                  :subject => "Step {{params.step_number}} on Request {{params.SS_request_number}} has started including custom subject",
                                  :body => '<p>Step {{params.step_number}}: {{params.step_name}} on Request {{params.request_id}}: {{params.request_name}} has started.</p><p>Request: {{params.SS_edit_request_url}}</p>')
            NotificationTemplate.stub(:first).and_return(@template)
            @mail = Notifier.step_started(@step).deliver
          end

          it "should have a content type of text/html" do
            @mail.content_type.should include("text/html")
          end

          it "should have a subject line that indicates purpose of email" do
            pending do
              @mail.subject.should include("Step 1 on Request #{@request.number} has started including custom subject")
            end
          end

          it "should have a body that includes completion status" do
            @mail.body.should include("has started")
          end

          it "should include a link to the url for the request" do
            @mail.body.should include("http://streamstep.dev")
          end
        end

        describe "without a templated subject" do
          before do
            @template = mock_model(NotificationTemplate,
                                  :format => 'text/html',
                                  :subject => nil,
                                  :body => '<p>Step {{params.step_number}}: {{params.step_name}} on Request {{params.request_id}}: {{params.request_name}} has started.</p><p>Request: {{params.SS_edit_request_url}}</p>')
            NotificationTemplate.stub(:first).and_return(@template)
            @mail = Notifier.step_started(@step).deliver
          end

          it "should have a subject line that indicates purpose of email" do
            @mail.subject.should include("Step 1 on Request #{@request.number} has started")
          end

        end
      end
    end

    describe "#deliver_step_completed" do
      pending "undefined method `step_completed' for Notifier:Class" do
        describe "with a templated subject" do
          before do
            @template = mock_model(NotificationTemplate,
                                  :format => 'text/html',
                                  :subject => "Step {{params.step_number}} on Request {{params.SS_request_number}} is complete and templated for real",
                                  :body => '<p>Step {{params.step_number}}: {{params.step_name}} on Request {{params.request_id}}: {{params.request_name}} has completed.</p><p>Request: {{params.SS_edit_request_url}}</p>')
            NotificationTemplate.stub(:first).and_return(@template)
            @mail = Notifier.step_completed(@step).deliver
          end

          it "should have a content type of text/html" do
            @mail.content_type.should include("text/html")
          end

          it "should have a subject line that indicates purpose of email" do
            pending do
              @mail.subject.should include("Step 1 on Request #{@request.number} is complete and templated for real")
            end
          end

          it "should have a body that includes completion status" do
            pending do
              @mail.body.should include("has completed")
            end
          end

          it "should include a link to the url for the request" do
            @mail.body.should include("http://streamstep.dev")
          end
        end

        describe "without a templated subject" do
          before do
            @template = mock_model(NotificationTemplate,
                                  :format => 'text/html',
                                  :subject => nil,
                                  :body => '<p>Step {{params.step_number}}: {{params.step_name}} on Request {{params.request_id}}: {{params.request_name}} has completed.</p><p>Request: {{params.SS_edit_request_url}}</p>')
            NotificationTemplate.stub(:first).and_return(@template)
            @mail = Notifier.step_completed(@step).deliver
          end

          it "should have a subject line that indicates purpose of email" do
            @mail.subject.should include("Step 1 on Request #{@request.number} is complete")
          end

        end
      end
    end
  end

  describe 'series_with_requests_update' do
    let(:environment) { create(:environment) }
    let(:request) { create :request, environment: environment, deployment_window_event: series_with_events.events.first }
    let(:series) { create(:recurrent_deployment_window_series, :with_active_request, environment_ids: [environment.id]) }
    let(:series_with_events) { DeploymentWindow::SeriesConstruct.new({}, series).create; series }

    before(:each) do
      DeploymentWindow::SeriesConstruct.any_instance.stub(:dates_existing)
      @mail = Notifier.series_with_requests_update(request, series).deliver
    end

    it 'contains a subject line that indicates purpose of email' do
      @mail.subject.should include('Deployment Window Series updating.')
    end

    it 'contains a body that includes user name' do
      @mail.body.should include(request.user.name)
    end

    it 'contains a body that includes series name' do
      @mail.body.should include(series.name)
    end

    it 'contains a body that includes request number' do
      @mail.body.should include(request.number)
    end
  end

end
