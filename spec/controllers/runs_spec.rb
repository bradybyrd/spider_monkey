require 'spec_helper'

describe RunsController, :type => :controller do
  before(:each) do
    @plan = create(:plan)
    @plan_stage = create(:plan_stage)
    @run = create(:run, :owner => @user,
                        :requestor => @user,
                        :plan => @plan)
    @request1 = create(:request)
    @plan_member = create(:plan_member, :plan => @plan, :stage => @plan_stage)
    @plan_member.request = @request1
  end

  it "#index" do
    get :index, {:plan_id => @plan.id,
                 :plan_stage_id => @plan_stage.id}
    assigns(:runs).should include(@run)
    response.should render_template('index')
  end

  it "#show" do
    get :show, {:plan_id => @plan.id,
                :plan_stage_id => @plan_stage.id,
                :id => @run.id}
    response.should render_template('show')
  end

  context "#new" do
    context "success" do
      specify "request_ids" do
        get :new, {:plan_id => @plan.id,
                   :plan_stage_id => @plan_stage.id,
                   :request_ids => [@request1.id]}
        response.should render_template('new')
      end

      specify "with all requests of plan stage" do
        xhr :get, :new, {:plan_id => @plan.id,
                         :plan_stage_id => @plan_stage.id}
        response.should render_template('new')
      end

      specify "clone run" do
        pending "TypeError: incompatible marshal file format (can't be read)"
        @plan_stage2 = create(:plan_stage)
        @request2 = create(:request)
        RequestTemplate.any_instance.stub(:create_request_for).and_return(@request2)
        @run2 = create(:run, :owner => @user,
                       :requestor => @user,
                       :plan => @plan, :request_ids => [@request2.id])
        @run2.plan_it!
        @run2.start!
        get :new, {:plan_id => @plan.id,
                   :plan_stage_id => @plan_stage.id,
                   :next_required_stage_id => @plan_stage2,
                   :run_to_clone_id => @run2}
      end
    end

    it "fails" do
      Run.stub(:new).and_return(false)
      get :new, {:plan_id => @plan.id,
                 :plan_stage_id => @plan_stage.id,
                 :request_ids => [@request1.id]}
      response.should redirect_to(plan_path(@plan))
    end
  end

  describe "#edit" do
    let(:valid_params) { { plan_id: @plan.id,
                           plan_stage_id: @plan_stage.id,
                           id: @run.id } }

    it do
      get :edit, valid_params
      response.should render_template('edit')
    end

    it_behaves_like 'authorizable', controller_action: :edit,
                                    ability_action: :edit_runs,
                                    subject: Plan do
                                      let(:params) { valid_params }
                                    end
  end

  context "#create" do
    before(:each) do
      @run_params = {:name => "Run1",
                     :owner_id => @user.id,
                     :requestor_id => @user.id,
                     :plan_id => @plan.id}
    end

    let(:valid_params) { { plan_id: @plan.id,
                           plan_stage_id: @plan_stage.id,
                           run: @run_params } }

    context "success" do
      it "redirects to plan path" do
        post :create, valid_params
        response.code.should eql('302')
      end

      it "ajax redirect" do
        xhr :post, :create, valid_params.merge({ request_planned_at_to_run_start_at: Time.now })
        response.should render_template('misc/redirect')
      end
    end

    context "fails" do
      before(:each) do
        Run.stub(:new).and_return(@run)
        @run.stub(:update_attributes).and_return(false)
      end

      it "renders action new" do
        post :create, valid_params
        response.should render_template('new')
      end

      it "shows validation errors" do
        xhr :post, :create, valid_params
        response.should render_template('misc/error_messages_for')
      end
    end

    it_behaves_like 'authorizable', controller_action: :create,
                                    ability_action: :create_run,
                                    subject: Plan do
                                      let(:params) { valid_params }
                                    end
  end

  context "#update" do
    let(:valid_params) { { id: @run.id,
                           plan_id: @plan.id,
                           plan_stage_id: @plan_stage.id,
                           request_planned_at_to_run_start_at: Time.now,
                           run: { name: "Run_changed" } } }

    context "success" do
      it "ajax redirect" do
        @run.plan_it!
        @run.start!
        @run.delete!
        xhr :put, :update, {:id => @run.id,
                            :plan_id => @plan.id,
                            :plan_stage_id => @plan_stage.id,
                            :run => {:name => "Run_changed"}}
        @run.reload
        @run.name.should eql("Run_changed")
        response.should render_template('misc/redirect')
      end

      it "redirects to plan path" do
        @time = Time.now
        put :update, {:id => @run.id,
                      :plan_id => @plan.id,
                      :plan_stage_id => @plan_stage.id,
                      :run => {:name => "Run_changed",
                               :start_at_date => @time.to_date,
                               :start_at_hour => @time.hour,
                               :start_at_minute => @time.min,
                               :start_at_meridian => @time.sec,
                               :end_at_date => @time.to_date,
                               :end_at_hour => @time.hour,
                               :end_at_minute => @time.min,
                               :end_at_meridian => @time.sec}}
        @run.reload
        @run.name.should eql("Run_changed")
        response.should redirect_to(plan_path( @plan, :run_id => @run.id ))
      end

      it "sets scheduled date" do
        pending "undefined method `except' for nil:NilClass"
        @plan_member = create(:plan_member, :request => create(:request))
        @run.plan_members << @plan_member
        @run.requests_planned_date = Time.now
        xhr :put, :update, valid_params
        @run.reload
      end
    end

    context "fails" do
      before(:each) do
        Run.stub(:find).and_return(@run)
        @run.stub(:update_attributes).and_return(false)
      end

      it "renders action edit" do
        put :update, {:id => @run.id,
                      :plan_id => @plan.id,
                      :plan_stage_id => @plan_stage.id,
                      :run => {:name => "Run_changed"}}
        response.should render_template('edit')
      end

      it "shows validation errors" do
        xhr :put, :update, {:id => @run.id,
                            :plan_id => @plan.id,
                            :plan_stage_id => @plan_stage.id,
                            :run => {:name => "Run_changed"}}
        response.should render_template('misc/error_messages_for')
      end
    end

    it_behaves_like 'authorizable', controller_action: :update,
                                    ability_action: :edit_runs,
                                    http_method: :put,
                                    subject: Plan do
                                      let(:params) { valid_params }
                                    end

    it_behaves_like 'authorizable', controller_action: :update,
                                    ability_action: :plan_run,
                                    http_method: :put,
                                    subject: Plan do
                                      let(:params) { valid_params }
                                    end

    it_behaves_like 'authorizable', controller_action: :update,
                                    ability_action: :start_run,
                                    http_method: :put,
                                    subject: Plan do
                                      let(:params) { valid_params }
                                    end

    it_behaves_like 'authorizable', controller_action: :update,
                                    ability_action: :hold_run,
                                    http_method: :put,
                                    subject: Plan do
                                      let(:params) { valid_params }
                                    end

    it_behaves_like 'authorizable', controller_action: :update,
                                    ability_action: :cancel_run,
                                    http_method: :put,
                                    subject: Plan do
                                      let(:params) { valid_params }
                                    end

    it_behaves_like 'authorizable', controller_action: :update,
                                    ability_action: :delete_run,
                                    http_method: :put,
                                    subject: Plan do
                                      let(:params) { valid_params }
                                    end
  end

  it "#destroy" do
    delete :destroy, {:plan_id => @plan.id,
                             :plan_stage_id => @plan_stage.id,
                             :id => @run.id}
    response.should redirect_to(plan_url(@plan))
  end

  context "#select_run_for_ammendment" do
    let(:valid_params) { { plan_id: @plan.id,
                           plan_stage_id: @plan_stage.id,
                           request_ids: [@request1.id] } }

    it "success" do
      post :select_run_for_ammendment, valid_params
      response.should render_template('select_run_for_ammendment')
    end

    it "fails" do
      @runs = [@run]
      Run.stub(:by_plan_and_stage).and_return(@runs)
      @runs.stub(:mutable).and_return(@runs)
      @runs.stub(:map).and_return(false)
      post :select_run_for_ammendment, {:plan_id => @plan.id,
                                        :plan_stage_id => @plan_stage.id}
      response.should redirect_to(plan_path(@plan))
    end

    it_behaves_like 'authorizable', controller_action: :select_run_for_ammendment,
                                    ability_action: :add_to_run,
                                    http_method: :post,
                                    subject: Plan do
                                      let(:params) { valid_params }
                                    end
  end

  context "#add_requests" do
    context "success" do
      before(:each) { RequestTemplate.any_instance.stub(:create_request_for).and_return(@request1) }
      it "ajax redirect" do
        xhr :post, :add_requests, {:run_id => @run.id,
                                   :plan_id => @plan.id,
                                   :plan_stage_id => @plan_stage.id}
        response.should render_template('misc/redirect')
      end

      it "redirects to run path" do
        expect{post :add_requests, {:run_id => @run.id,
                                    :plan_id => @plan.id,
                                    :plan_stage_id => @plan_stage.id,
                                    :request_ids => [@request1.id]}
              }.to change(@run.requests, :count).by(1)
        response.should redirect_to(plan_path( @plan, :run_id => @run.id ))
      end
    end

    it "fails" do
      Run.stub(:find).and_return(@run)
      @run.stub(:update_attributes).and_return(false)
      post :add_requests, {:run_id => @run.id,
                           :plan_id => @plan.id,
                           :plan_stage_id => @plan_stage.id}
      response.should redirect_to(plan_path(@plan))
    end
  end

  context "#drop" do
    let(:valid_params) { { run_id: @run.id,
                           plan_id: @plan.id,
                           plan_stage_id: @plan_stage.id,
                           request_ids: [@request1.id] } }

    it "success" do
      post :drop, valid_params
      response.should redirect_to(plan_path(@plan, :run_id => @run.id))
    end

    it "fails" do
      post :drop, {:plan_id => @plan.id,
                   :plan_stage_id => @plan_stage.id}
      response.should redirect_to(plan_path(@plan))
    end

    context 'without permission' do
      include_context 'mocked abilities', :cannot, :drop_from_run, Plan

      it 'renders access denied message' do
        post :drop, valid_params

        expect(flash[:error]).to include(access_denied_message)
      end

      def access_denied_message
        I18n.t(:'activerecord.errors.no_access_to_view_page')
      end
    end

    context 'with permission' do
      include_context 'mocked abilities', :can, :drop_from_run, Plan

      it 'renders dropped successfully message' do
        post :drop, valid_params

        expect(flash[:notice]).to include(dropped_successfully_message)
      end

      def dropped_successfully_message
        I18n.t('run.notices.dropped_successfully')
      end
    end

  end

  context "#reorder_members" do
    let(:valid_params) { { id: @run.id,
                           plan_id: @plan.id,
                           plan_stage_id: @plan_stage.id } }

    it "renders action" do
      get :reorder_members, valid_params
      response.should render_template("reorder_members")
    end

    it "redirects to plan path" do
      Run.stub(:find).and_return(@run)
      @run.stub(:blank?).and_return(true)
      get :reorder_members, valid_params
      response.should redirect_to(plan_path(@plan))
    end

    it_behaves_like 'authorizable', controller_action: :reorder_members,
                                    ability_action: :reorder_run,
                                    subject: Plan do
                                      let(:params) { valid_params }
                                    end
  end

  describe "#update_member_order" do
    let(:valid_params) { { id: @run.id,
                           plan_id: @plan.id,
                           plan_stage_id: @plan_stage.id,
                           plan_member_id: @plan_member.id,
                           plan_member: { position: 2 } } }

    it do
      put :update_member_order, valid_params
      @plan_member.reload
      @plan_member.position.should eql(2)
      response.should render_template(:partial => '_for_reorder')
    end

    it_behaves_like 'authorizable', controller_action: :update_member_order,
                                    ability_action: :reorder_run,
                                    http_method: :put,
                                    subject: Plan do
                                      let(:params) { valid_params }
                                    end
  end

  it "#version_conflict_report" do
    get :version_conflict_report, {:id => @run.id,
                                   :plan_id => @plan.id,
                                   :plan_stage_id => @plan_stage.id}
    response.should render_template("runs/version_conflict_report")
  end

  describe '#start' do
    it_behaves_like 'authorizable', controller_action: :start,
                                    ability_action: :start_run,
                                    http_method: :put,
                                    subject: Plan do
                                      let(:params) { { plan_id: @plan.id,
                                                       id: @run.id } }
                                    end
  end
end
