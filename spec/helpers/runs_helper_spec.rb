require "spec_helper"

describe RunsHelper do
  let(:request) { create(:request) }
  let(:plan) { create(:plan) }
  let(:user) { create(:old_user) }
  let(:run) { create(:run, :plan => plan, :owner => user, :requestor => user, :start_at => Time.now) }

  describe "#show_alert_for_scheduling" do
    let!(:plan_member) { create(:plan_member, :plan => plan, :request => request, :run => run) }

    it "returns #FFBBBB" do
      request.scheduled_at = Time.now - 1.day
      helper.show_alert_for_scheduling(request).should eql("#FFBBBB")
    end

    it "returns nothing" do
      request.scheduled_at = Time.now
      helper.show_alert_for_scheduling(request).should eql("")
    end
  end

  describe "#disable_date_field_for_run?" do
    it "returns false" do
      helper.disable_date_field_for_run?(run).should eql(false)
    end

    it "returns true" do
      run.aasm_state = 'started'
      helper.disable_date_field_for_run?(run).should eql(true)
    end
  end

  describe "#disable_date_field_for_request?" do
    it "returns false" do
      helper.disable_date_field_for_request?(request, false).should eql(false)
    end

    it "returns true" do
      request.aasm_state = 'complete'
      helper.disable_date_field_for_request?(request, false).should eql(true)
    end
  end

  describe "#available_environments_for_request_menu" do
    let!(:plan_stage) { create(:plan_stage, :plan_template => plan.plan_template,
                                            :environment_type => create(:environment_type)) }
    let!(:plan_stage_instance) { create(:plan_stage_instance, :plan_stage => plan_stage,
                                                              :plan => plan) }
    let!(:environment) { create(:environment) }

    it "returns environment of request" do
      plan.stub(:is_constrained?).and_return(true)
      plan_stage_instance
      plan_stage_instance.stub(:allowable_environments_for_request).and_return([environment])
      helper.available_environments_for_request_menu(plan_stage_instance, request).should include(environment.name)
    end

    it "returns all environment" do
      app = create(:app)
      app.environments << environment
      request.apps << app
      helper.available_environments_for_request_menu(plan_stage_instance, request).should include(environment.name)
    end
  end

  it "#available_environments_select" do
    environment = create(:environment)
    helper.available_environments_select([environment], request).should include(environment.name)
  end
end