require "spec_helper"
include ApplicationHelper

describe PlansHelper do
  before(:each) do
    @request1 = create(:request_with_app)
    @app = @request1.apps.first
    @app_request = AppsRequest.create(:request_id => @request1.id, :app_id => @app.id)
    @plan_template = create(:plan_template)
    @plan = create(:plan, :plan_template=> @plan_template)
    @plan_stage = create(:plan_stage, :plan_template => @plan_template)
    @plan.stages << @plan_stage
    @plan_member = create(:plan_member, :plan => @plan, :stage => @plan_stage, :request => @request1)
  end

  it "#select_list_for_plans_templates" do
    select_list_for_plans_templates([@plan_template]).should include("#{@plan_template.name}")
  end

  it "select_list_for_members" do
    select_list_for_members().should eql("<select id=\"member_id\" name=\"member_id\"><option value=\"Select\">Select</option></select>")
  end

  describe "#request_color_code_for_stage" do
    it "returns 'round_box_lc_started'" do
      request_color_code_for_stage("started").should eql('round_box_lc_started')
    end

    it "returns 'round_box_lc_created'" do
      request_color_code_for_stage("created").should eql('round_box_lc_created')
    end

    it "returns 'round_box_lc_planned'" do
      request_color_code_for_stage("planned").should eql('round_box_lc_planned')
    end

    it "returns 'round_box_lc_problem'" do
      request_color_code_for_stage("problem").should eql('round_box_lc_problem')
    end

    it "returns 'round_box_lc_hold'" do
      request_color_code_for_stage("hold").should eql('round_box_lc_hold')
    end

    it "returns 'round_box_lc_cancelled'" do
      request_color_code_for_stage("cancelled").should eql('round_box_lc_cancelled')
    end

    it "returns 'round_box_lc_complete'" do
      request_color_code_for_stage("complete").should eql('round_box_lc_complete')
    end

    it "returns 'round_box_lc_deleted'" do
      request_color_code_for_stage("deleted").should eql('round_box_lc_deleted')
    end
  end

  describe "#request_color_code_for_label" do
    it "returns 'auto_started_Request'" do
      request_color_code_for_label("started").should eql('auto_started_Request')
    end

    it "returns 'auto_created_Request'" do
      request_color_code_for_label("created").should eql('auto_created_Request')
    end

    it "returns 'auto_planned_Request'" do
      request_color_code_for_label("planned").should eql('auto_planned_Request')
    end

    it "returns 'auto_problem_Request'" do
      request_color_code_for_label("problem").should eql('auto_problem_Request')
    end

    it "returns 'auto_hold_Request'" do
      request_color_code_for_label("hold").should eql('auto_hold_Request')
    end

    it "returns 'auto_cancelled_Request'" do
      request_color_code_for_label("cancelled").should eql('auto_cancelled_Request')
    end

    it "returns 'auto_complete_Request'" do
      request_color_code_for_label("complete").should eql('auto_complete_Request')
    end

    it "returns 'auto_deleted_Request'" do
      request_color_code_for_label("deleted").should eql('auto_deleted_Request')
    end
  end

  it "#selected_lifecyle_tab" do
    selected_lifecyle_tab('Continuous Integration','Continuous Integration').should eql("selected")
  end

  it "#my_date" do
    my_date("12/Dec/2013").should eql("12/12/2013")
  end

  it "#my_datetime" do
    my_datetime("12/Dec/2013 10 AM").should eql("12/12/2013 10:00 AM")
  end

  describe "#display_stage_icon" do
    it "returns 'A'" do
      display_stage_icon(true).should eql("A")
    end

    it "returns 'M'" do
      display_stage_icon(false).should eql("M")
    end
  end

  describe "#date_for_release" do
    it "returns plan date" do
      date_for_release(@plan).should eql(@plan.release_date)
    end

    it "returns today date" do
      @plan.release_date = ""
      date_for_release(@plan).should eql(Date.today)
    end
  end

  #TODO These methods do not use, you can delete tests

  # it "#multi_plan_template_options" do
  #   pending "multi_item template type don`t in use`"
  #   @plan_template.template_type = 'multi_item'
  #   multi_plan_template_options.should include(@plan_template)
  # end

  describe "#stage_timeframe" do
    it "returns date" do
      @request1.scheduled_at = "24/12/2013"
      @grouped_members = []
      @grouped_members[@plan_stage.id] = [@plan_member]
      stage_timeframe(@plan_stage, @grouped_members).should eql("Planned Start - 12/24/2013 ")
    end

    it "returns nothing" do
      Request.delete_all
      stage_timeframe(@plan_stage, nil, @plan).should be_nil
    end
  end

  #TODO These methods do not use, you can delete tests

  # it "#stage_plan_dates" do
  #   pending "don`t in use and doesn`t work correctly"
  #   @plan_date = create(:plan_stage_date, :plan => @plan,
  #                                         :plan_stage => @plan_stage,
  #                                         :start_date => '12/17/2013 10:15 AM',
  #                                         :end_date => '12/31/2013 10:15 AM')
  #   stage_plan_dates(@plan_stage).should eql("#{@plan_stage.start_date}")
  # end

  it "#release_calendar_options" do
    release_calendar_options.first.should eql(['Current year to end', "#{Date.today.beginning_of_month},#{Date.today.end_of_year}"])
  end

  #TODO These methods do not use, you can delete tests

  # it "#link_to_all_activities" do
  #   pending "don`t in use and doesn`t work correctly"
  #   @plan.activities << create(:activity)
  #   link_to_all_activities(@plan).should include(@plan.id)
  # end

  # it "#last_member_of_stage" do
  #   pending "don`t in use"
  # end

  it "#status_label" do
    status_label(@plan).should include("#{@plan.aasm.current_state}")
  end

  #TODO These methods do not use, you can delete tests

  # it "#get_tab_name" do
  #   pending "don`t in use and doesn`t work correctly"
  # end

  it "#label_value" do
    label_value('name1','val1').should eql("<span class='name_pair'>name1: </span><span class='value_pair'>val1")
  end

  it "#plan_environments_list" do
    @env = create(:environment)
    @plan.stub(:environments_for_app).and_return([@env])
    plan_environments_list(@plan, @app).should eql(@env.name)
  end

  it "#flowchart_stages_for_plan" do
    flowchart_stages_for_plan(@plan).should include(@plan_stage.name)
  end

  describe "#count_label" do
    it "returns nothing" do
      count_label().should eql("")
    end

    it "returns string" do
      count_label(2).should eql("(2)")
    end
  end

  it "#request_name_links_for_app" do
    request_name_links_for_app(@plan, @app.id).should eql("<a href=\"/requests/#{@request1.number}/edit\" title=\"#{@request1.name}\">#{@request1.number}</a>")
  end

  describe "#run_name_links_for_app" do
    before(:each) do
      @user = create(:old_user)
      @run = create(:run, :owner => @user, :requestor => @user, :plan => @plan)
    end

    it "returns links" do
      @run.plan_members << @plan_member
      run_name_links_for_app(@plan, @app.id).should include("#{plan_path(:id => @plan.id)}")
    end

    it "returns nothing" do
      run_name_links_for_app(@plan, -1).should eql(' - ')
    end
  end

  describe '#plan_label' do
    it "returns plan name" do
      helper.stub(:cannot?).and_return(false)
      helper.plan_label(@request1).should eql("#{@plan.name}: #{@plan_stage.name}")
    end

    it "includes lock icon" do
      helper.stub(:cannot?).and_return(true)
      expect(helper.plan_label(@request1)).to include 'icons/lock.png'
    end
  end

  it "#available_state_buttons_for_run" do
    @user = create(:old_user)
    @run = create(:run, :owner => @user, :requestor => @user, :plan => @plan)
    @run.plan_members << @plan_member
    allow(helper).to receive(:can?).and_return(true)

    helper.available_state_buttons_for_run(@run).should include('<input class="button" type="submit" value="Plan Run" /></div>')
  end

  describe "#parallel_toggle_image" do
    it "returns hourglass icon tag" do
      parallel_toggle_image(@plan_member).should include('icons/hourglass.png')
    end

    it "returns hourglass_go icon tag" do
      @plan_member2 = create(:plan_member, :plan => @plan, :stage => @plan_stage)
      @plan_member.stub(:higher_item).and_return(@plan_member2)
      @plan_member.stub(:lower_item).and_return(@plan_member2)
      @plan_member2.stub(:different_level_from_previous).and_return(false)
      parallel_toggle_image(@plan_member).should include('icons/hourglass_go.png')
    end

    it "returns arrow_down icon tag" do
      @plan_member.stub(:different_level_from_previous).and_return(false)
      parallel_toggle_image(@plan_member).should include('icons/arrow_down.png')
    end
  end

  it "#dates_for_env_app" do
    @env = create(:environment)
    @user = create(:old_user)
    @plan_date = PlanEnvAppDate.create(:plan_id => @plan.id,
                                       :environment_id => @env.id,
                                       :app_id => @app.id,
                                       :plan_template_id => @plan_template.id,
                                       :created_at => Time.now,
                                       :created_by => @user.id)
    dates_for_env_app(@env.id, @app.id, @plan.id).should eql(@plan_date)
  end

  describe '#requests_available_to_current_user' do
    it 'shows requests with environments which user has in his group' do
      application_with_environment = create :app, environments: [ create(:environment) ]
      helper.stub(:current_user).and_return(user_on_application(application_with_environment))
      stage = double :stage, id: 1
      request_with_assigned_environment = create :request, environment: application_with_environment.environments.first, apps: [ application_with_environment ]
      request_with_unassigned_environment = create :request_with_app
      grouped_members = { stage.id => [ double(:member, request: request_with_assigned_environment),
                                        double(:member, request: request_with_unassigned_environment) ] }

      requests = helper.requests_available_to_current_user(grouped_members, stage)

      expect(requests).to include request_with_assigned_environment
    end

    it 'does not show requests with environments which user does not have in his group' do
      application_with_environment = create :app, environments: [ create(:environment) ]
      helper.stub(:current_user).and_return(user_on_application(application_with_environment))
      stage = double :stage, id: 1
      request_with_assigned_environment = create :request, environment: application_with_environment.environments.first, apps: [ application_with_environment ]
      request_with_unassigned_environment = create :request_with_app
      grouped_members = { stage.id => [ double(:member, request: request_with_assigned_environment),
                                        double(:member, request: request_with_unassigned_environment) ] }

      requests = helper.requests_available_to_current_user(grouped_members, stage)

      expect(requests).not_to include request_with_unassigned_environment
    end

    def user_on_application(application)
      user = create(:user, :non_root, apps: [ application ])
      allow(user).to receive(:can?).with(:view_created_requests_list, an_instance_of(Request)).and_return(true)
      create(:team, groups: user.groups, apps: [application])
      user.update_assigned_apps
      user
    end
  end

  describe '#members_requests' do
    it 'excludes nil requests' do
      stage = double :stage, id: 1
      grouped_members = { stage.id => [ double(:member, request: double(:request)),
                                        double(:member, request: nil) ] }

      requests = helper.members_requests(grouped_members, stage)

      expect(requests).not_to include nil
    end
  end
end
