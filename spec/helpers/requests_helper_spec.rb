require "spec_helper"
include StepsHelper
include ApplicationHelper
include ActivitiesHelper
include ERB::Util
include InstalledComponentsHelper
include CanCan::Ability

describe RequestsHelper do
  before(:each) do
    @app = create(:app)
    @env = create(:environment)
    @app_env = create(:application_environment,
                      app: @app,
                      environment: @env)
    @request1 = create(:request, apps: [@app], environment: @env)
    @step1 = create(:step, request: @request1)
    @step2 = create(:step, request: @request1)
  end

  describe '#request_row_class' do
    it 'returns the request_row class with no view and a viewable request' do
      allow(self).to receive(:can?).with(:view_requests_list, :request).and_return(true)
      allow(self).to receive(:can?).with(:inspect, :request).and_return(false)

      expect(request_row_class(false, :request)).to eq "request_row"
    end

    it 'returns nothing if there is a view' do
      allow(self).to receive(:can?).with(:view_requests_list, :request).and_return(true)
      allow(self).to receive(:can?).with(:inspect, :request).and_return(false)

      expect(request_row_class(true, :request)).to be_empty
    end

    it 'returns nothing if the request is not viewable' do
      allow(self).to receive(:can?).with(:view_requests_list, :unviewable_request).and_return(false)
      allow(self).to receive(:can?).with(:inspect, :unviewable_request).and_return(false)

      expect(request_row_class(false, :unviewable_request)).to be_empty
    end

    it 'returns clickable if user has permissions to open a request' do
      allow(self).to receive(:can?).with(:view_requests_list, :request).and_return(true)
      allow(self).to receive(:can?).with(:inspect, :request).and_return(true)

      expect(request_row_class(false, :request)).to match 'clickable'
    end
  end

  it "#request_release_td" do
    request_release_td(@request1).should include("#{@request1.number}")
  end

  it "#sortable_th" do
    @filters = {:sort_scope => 'name', :sort_direction => 'ASC'}
    sortable_th('name').should eql("<th class=\" sortable ASC\" data-column=\"name\">name</th>")
  end

  it "#request_owner_td" do
    request_owner_td(@request1).should include("#{@request1.number}")
  end

  it "#request_requestor_td" do
    request_requestor_td(@request1).should include("#{@request1.number}")
  end

  it "#request_sort_data_attr" do
    request_sort_data_attr(@request1, :steps).should eql('data-steps="Step"')
  end

  it "#stringify_filters" do
    params[:display_format] = true
    @filters = {:sortable => 'ASC'}
    stringify_filters.should eql('?filters[sortable]=ASC&display_format=true')
  end

  it "#day_classes_for" do
    @calendar = {}
    day_classes_for(Date.current).should include('day today inactive')
  end

  it "#ordered_requests_for_day" do
    @request2 = create(:request, :created_at => Time.now + 1.day)
    ordered_requests_for_day([@request2,@request1]).should eql([@request1,@request2])
  end

  it "#steps_container" do
    request = create(:request)
    helper.instance_variable_set(:@request, request)
    allow(helper).to receive(:can?).and_return(true)
    allow(helper).to receive(:current_user).and_return(create(:old_user))

    helper.steps_container.should match(/div .* id="steps_container"/)
  end

  it "#steps_container_pdf" do
    User.stub(:current_user).and_return(create(:old_user))
    @request = create(:request)
    steps_container_pdf.should match(/div .* id="steps_container"/)
  end

  it "#attributes_for_step_container" do
    @request1.plan_it!
    @request1.start_request!
    params[:controller] = 'requests'
    attributes_for_step_container(@request1).should eql({ :class => 'auto_update', :update_with => request_steps_path(@request1)})
  end

  describe "#display_hour" do
    it "returns '12:00AM'" do
      display_hour(0).should eql("12:00AM")
    end

    it "returns '12:00PM'" do
      display_hour(12).should eql("12:00PM")
    end

    it "returns time after AM'" do
      display_hour(22).should eql("10:00PM")
    end

    it "returns time before PM'" do
      display_hour(3).should eql("3:00AM")
    end
  end

  describe "#request_category_available_for?" do
    it "returns true" do
      @category = create(:category)
      request_category_available_for?('problem').should eql(true)
    end

    it "returns false" do
      request_category_available_for?('start').should eql(false)
    end
  end

  describe "#request_edit_page_title_for" do
    it "returns request template name and number when request template is not present" do
      test_request = build(:request)
      allow(test_request).to receive(:number).and_return(42)
      request_edit_page_title_for(test_request).should include("#{test_request.number}")
      request_edit_page_title_for(test_request).should include("#{test_request.name}")
    end

    it "returns request template name when request template is present" do
      request_template = build(:request_template)
      test_request = build(:request, request_template: request_template)
      request_edit_page_title_for(test_request).should include("#{test_request.request_template.name}")
    end
  end

  describe "#lock_icon_for_requestor" do
    before(:each) do
      @user = create(:old_user)
      helper.stub(:current_user).and_return(@user)
      helper.stub(:can?).and_return(true)
    end

    it "returns image_tag" do
      @request1.plan_member.stage.stub(:requestor_access).and_return(false)
      helper.lock_icon_for_requestor(@request1).should eql("<img alt=\"Lock\" src=\"/assets/icons/lock.png\" /> ")
    end

    it "returns nothing" do
      helper.lock_icon_for_requestor(@request1).should eql(" ")
    end
  end

  describe "#request_edit_page_heading_for" do
    context "with request template" do
      let(:request) { create(:request) }

      it "returns request template name" do
        request_edit_page_heading_for(request).should include("Request: <span class='requestNumber'>#{request.number}")
      end
    end

    context "with request template" do
      let(:request_template) { create(:request_template) }
      let(:request) { create(:request, request_template: request_template) }

      it "returns request name" do
        request_edit_page_heading_for(request).should include("Request Template - #{request.request_template.name}")
      end

      it "returns link" do
        request_edit_page_heading_for(request).should include("Request Template - #{request_template.name}")
      end
    end
  end

  it "#request_date" do
    request_date(Time.now).should eql(Time.now.strftime(GlobalSettings[:default_date_format].match(/\S+/)[0]))
  end

  describe "#request_duration" do
    it "returns duration of complete" do
      @request2 = create(:request)
      @request2.plan_it!
      @request2.start_request!
      @request2.started_at = Time.now
      @request2.completed_at = Time.now + 5.hour
      request_duration(@request2).should eql('5:00 (hh:mm)')
    end

    it "returns estimate" do
      @request1.estimate = 600
      request_duration(@request1).should eql('10:00 (hh:mm)')
    end
  end

  it "#estimated_time_for_steps" do
    @step1.estimate = 300
    @step1.save
    @step2.estimate = 300
    @step2.save
    estimated_time_for_steps(@request1).should eql('10:00')
  end

  it "#total_time_for_steps" do
    @step1.estimate = 150
    @step2.estimate = 210
    @step1.save
    @step2.save
    total_time_for_steps(@request1).should eql('6:00')
  end

  it "#request_date_field" do
    request_date_field('300', 'display:true').should include('<div id="" style="display:true float:left;">')
  end

  it "#show_rescheduled_field_for" do
    show_rescheduled_field_for(@request1).should eql("display:none;")
  end

  describe "#class_for_rescheduled_field" do
    it "returns keys" do
      @request1.stub(:new_record?).and_return(false)
      class_for_rescheduled_field(@request1).should eql("new_record")
    end

    it "returns 'new_record'" do
      @request1.stub(:new_record?).and_return(true)
      class_for_rescheduled_field(@request1).should eql("new_record")
    end
  end

  describe "#last_deployed_at" do
    before(:each) { @component = create(:component) }

    specify "with installed component" do
      create_installed_component
      last_deployed_at(@request1, @component.id).should eql("Never")
    end

    it "returns error" do
      last_deployed_at(@request1, @component.id).should eql("Error")
    end
  end

  it "#get_current_installed_version" do
    create_installed_component
    get_current_installed_version(@request1, @component.id).should eql(@installed_component.version)
  end

  it "#request_info_for_rss" do
    request_info_for_rss(@request1).should include("#{@request1.number}")
  end

  describe "#latest_requests" do
    before(:each) do
      controller.stub(:can?).and_return(true)
    end

    it "returns links when there are links" do
      request = create(:request)
      allow(helper).to receive(:can?).and_return(true)

      expect(helper.latest_requests([request])).to include("<a href=\"/requests/#{request.number}\">#{request.number}</a>")
    end

    it "returns '-' when there are no links" do
      expect(helper.latest_requests([])).to eql('-')
    end
  end

  it "#format_to_sentence" do
    format_to_sentence([@request1.number,@request1.number]).should eql("#{@request1.number} and #{@request1.number}")
  end

  describe '#request_id_td' do
    before(:each) do
      user = create(:user)
      helper.stub(:current_user).and_return(user)
      helper.stub(:can?).and_return(true)
    end

    it 'generates link to request if user has permissions' do
      @request1.stub(:is_visible?).and_return(true)
      expect(helper.request_id_td(@request1, @request1.app_ids)).to include("<a href=\"/requests/#{@request1.number}\">")
    end

    it 'does not generate link to request unless user has permissions' do
      @request1.stub(:is_visible?).and_return(false)
      expect(helper.request_id_td(@request1, @request1.app_ids)).to include("<a href=\"#\">")
    end
  end

  it "#person_cell?" do
    @user = create(:old_user)
    helper.stub(:current_user).and_return(@user)
    @user.stub(:is_owner_or_requestor_of?).and_return(true)
    helper.person_cell?(@request1).should eql(" person_cell")
  end

  it "#person_cell_title" do
    @user = create(:old_user)
    helper.stub(:current_user).and_return(@user)
    @user.stub(:is_owner_or_requestor_of?).and_return(true)
    helper.person_cell_title(@request1).should eql('You are the Owner and/or Requestor')
  end

  it "#request_number_td" do
    request_number_td(@request1).should include("#{@request1.number}")
  end

  it "#request_name_td" do
    request_name_td(@request1).should include("#{@request1.name}")
  end

  it "#request_business_process_td" do
    @business_process = create(:business_process, apps: [@app])
    request = create(:request, business_process_id: @business_process.id)
    request_business_process_td(request).should include("#{@business_process.name}")
  end

  it "#request_app_td" do
    request_app_td(@request1).should include("#{@app.name}")
  end

  describe "#request_env_td" do
    it "returns environment label" do
      request_env_td(@request1).should include("#{@request1.environment_label}")
    end

    it "returns &nbsp;" do
      @request1.stub(:environment).and_return(nil)
      request_env_td(@request1).should include('&nbsp;')
    end
  end

  it "#request_scheduled_td" do
    @request1.scheduled_at = "17/12/2013"
    request_scheduled_td(@request1).should eql("<td class=\"date scheduled\">12/17/2013 12:00 AM</td>")
  end

  it "#request_duration_td" do
    @request1.started_at = Time.now
    @request1.completed_at = Time.now + 5.hour
    request_duration_td(@request1).should eql('<td>5h 0m 0s</td>')
  end

  it "#request_due_td" do
    @request1.target_completion_at = "17/12/2013"
    request_due_td(@request1).should eql("<td class=\"date\">12/17/2013 12:00 AM</td>")
  end

  it "#request_steps_td" do
    request_steps_td(@request1).should eql("<td style=\"text-align:center;\">#{@request1.steps.count}</td>")
  end

  it "#request_created_td" do
    request_created_td(@request1).should include("<td class=\"request_created_on\"")
  end

  it "#request_participants_td" do
    request_participants_td(@request1).should include("#{@request1.participant_names.first}")
  end

  context "#request_project_td" do
    it "returns activity name" do
      @activity = create(:activity)
      @request1.activity = @activity
      request_project_td(@request1).should include("<td title=\"#{@activity.name}\">#{@activity.name}</td>")
    end

    it "returns blank td" do
      pending "method don`t work correctly`"
      request_project_td(@request1).should eql("<td></td>")
    end
  end

  it "#request_package_contents_td" do
    @package_content = create(:package_content)
    @request1.package_contents << @package_content
    request_package_contents_td(@request1).should eql("<td title=\"#{@package_content.name}\">#{@package_content.name}</td>")
  end

  it "#request_started_at_td" do
    @request1.started_at = "18/12/2013"
    request_started_at_td(@request1).should eql("<td class=\"request_started_at\">12/18/2013 12:00 AM</td>")
  end

  it "#display_time" do
    display_time("186300").should eql('2d 3h 45m 0s')
  end

  it "#wrap_text" do
    wrap_text("text",2).should eql("te\nxt\n")
  end

  context '#component_select_tag' do
    let!(:some_user) { User.stub(:current_user).and_return(create(:old_user)) }
    it 'for manual step' do
      @request = create(:request)
      @step = create(:step, :request => @request)
      res = component_select_tag(@step)
      res.should include("id=\"step_component_id\"")
      res.should include("data-protect-automation=\"false\"")
      res.should include("<option value=''>Select</options>")
    end

    it 'for automation step with Protect Automation' do
      @request = create(:request)
      @step = create(:step, :request => @request)
      @step.stub(:auto?).and_return(true)
      @step.stub(:protect_automation?).and_return(true)
      res = component_select_tag(@step)
      res.should include("id=\"step_component_id\"")
      res.should include("data-protect-automation=\"true\"")
      res.should_not include("<option value=''>Select</options>")
    end
  end

  describe "#step_components_options" do
    before(:each) do
      helper.stub(:current_user).and_return(create(:old_user))
      User.stub(:current_user).and_return(create(:old_user))
      @request = create(:request)
      @request.apps << @app
      @step = create(:step, :request => @request)
      create_installed_component
      @request.environment_id = @env.id
    end

    it "returns step installed component" do
      @step.installed_component_id = @installed_component.id
      step_components_options(@request, @step).should include("#{@component.id}")
    end

    it "returns app installed component" do
      @step.app_id = @app.id
      @step.component = @component
      step_components_options(@request, @step).should include("#{@component.id}")
    end

    it "returns step component" do
      @step.component = @component
      step_components_options(@request, @step).should include("#{@component.id}")
    end

    it "returns option with component id" do
      step_components_options(@request, @step).should include("#{@component.id}")
    end

    it "return nothing" do
      @request.environment_id = '-1'
      step_components_options(@request, @step).should eql('')
    end

    it "returns app id" do
      step_components_options(@request, @step).should include("#{@app.id}")
    end
  end

  it "#check_installed_components" do
    create_installed_component
    check_installed_components(@app,@request1,@component).should be_truthy
  end

  it "#request_apps_environments" do
    request_apps_environments(@request1).should eql([@env])
  end

  it "#app_ids_for" do
    app_ids_for(@request1, @env).should eql("#{@app.id}")
  end

  describe '#enable_all_request_form_fields' do
    it 'returns true if request is new record' do
      request = build(:request)

      expect(helper.enable_all_request_form_fields(request)).to be_truthy
    end

    it 'returns true if user is root' do
      user = create(:user, :root)
      request = create :request
      allow(helper).to receive(:current_user).and_return(user)

      expect(helper.enable_all_request_form_fields(request)).to be_truthy
    end

    it 'returns true if user is request owner' do
      request = create(:request)
      allow(helper).to receive(:current_user).and_return(request.owner)

      expect(helper.enable_all_request_form_fields(request)).to be_truthy
    end

    it 'returns true if user is request requestor' do
      request = create(:request)
      allow(helper).to receive(:current_user).and_return(request.requestor)

      expect(helper.enable_all_request_form_fields(request)).to be_truthy
    end

    it 'returns false in other cases' do
      request = create(:request)
      user = create(:user, :non_root)
      allow(helper).to receive(:current_user).and_return(user)

      expect(helper.enable_all_request_form_fields(request)).to be_falsey
    end
  end

  describe "#disable_all_request_form_fields" do
    it 'calls #enable_all_request_form_fields and returns opposite' do
      request = build(:request)
      allow(helper).to receive(:enable_all_request_form_fields).and_return(false)

      expect(helper.disable_all_request_form_fields(request)).to be_truthy
    end
  end

  describe "#app_name_links" do
    it "returns app name as link" do
      helper.stub(:can?).and_return(true)
      expect(helper.app_name_links(@request1)).to eq("<a href=\"/apps/#{@app.id}/edit\">#{@app.name} </a>")
    end

    it "returns app name as text" do
      helper.stub(:can?).and_return(false)
      expect(helper.app_name_links(@request1).strip).to eq(@app.name)
    end
  end

  it "#params_for_currently_running_steps" do
    @selected_user = create(:old_user)
    @selected_group = create(:group)
    @should_user_include_groups = true
    @params = {:user_id => @selected_user.id,
               :group_id => @selected_group.id,
               :should_user_include_groups => true}
    params_for_currently_running_steps.should eql(@params)
  end

  it "#version_select" do
    helper.stub(:can?).and_return(true)
    create_installed_component
    @step1.stub(:installed_component).and_return(@installed_component)
    @vt = create(:version_tag)
    @installed_component.version_tags << @vt
    helper.version_select(@step1).should include("<option value=\"#{@vt.id}\">#{@vt.name}</option>")
  end

  describe "#step_colspan" do
    specify "0 columns" do
      step_colspan(0).should eql({:cols1=>3,:cols2=>4})
    end

    specify "5 columns" do
      step_colspan(5).should eql({:cols1=>3,:cols2=>3})
    end

    specify "4 columns" do
      step_colspan(4).should eql({:cols1=>2,:cols2=>3})
    end

    specify "3 columns" do
      step_colspan(3).should eql({:cols1=>2,:cols2=>2})
    end

    specify "2 columns" do
      step_colspan(2).should eql({:cols1=>1,:cols2=>2})
    end

    specify "1 column" do
      step_colspan(1).should eql({:cols1=>1,:cols2=>1})
    end
  end

  describe "#time_for_completion" do
    it "returns '--:--'" do
      time_for_completion(@request1).should eql("--:--")
    end

    it "returns time" do
      @request1.started_at = Time.now
      @request1.completed_at = Time.now + 5.hour
      time_for_completion(@request1).should eql("05:00")
    end
  end

  describe "#total_activity_time" do
    it "returns '--:--'" do
      total_activity_time(@request1).should eql("--:--")
    end

    it "returns time" do
      @request1.scheduled_at = Time.now
      @request1.target_completion_at = Time.now + 5.hour
      total_activity_time(@request1).should eql("05:00")
    end
  end

  it "#total_duration_for_request" do
    @step1.estimate = 150
    @step2.estimate = 210
    @step1.save
    @step2.save
    total_duration_for_request(@request1).should eql("6:00")
  end

  def create_installed_component
    @request1.environment_id = @env.id
    @component = create(:component)
    @app_component = create(:application_component,
                            :app => @app,
                            :component => @component)
    @installed_component = create(:installed_component,
                                  :application_environment => @app_env,
                                  :application_component => @app_component)
  end
end
