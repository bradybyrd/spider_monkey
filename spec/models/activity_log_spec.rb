require 'spec_helper'

describe ActivityLog do

  context '' do

    before(:each) do
      @activity_log = ActivityLog.new
    end

    describe "validations" do
      it { @activity_log.should validate_presence_of(:request) }
      it { @activity_log.should validate_presence_of(:user) }
      it { @activity_log.should validate_presence_of(:activity) }
    end

    it "should belong to" do
      @activity_log.should belong_to(:request)
      @activity_log.should belong_to(:user)
      @activity_log.should belong_to(:step)
    end

    describe "scopes" do
      it "should have the scopes" do
        ActivityLog.should respond_to(:filter_by_user_id)
        ActivityLog.should respond_to(:filter_by_request_id)
        ActivityLog.should respond_to(:filter_by_step_id)
        ActivityLog.should respond_to(:filter_by_type)
        ActivityLog.should respond_to(:get_problems_of)
        ActivityLog.should respond_to(:recent_activity_for)
      end
    end
  end

  describe '#filtered' do

    before(:all) do
      ActivityLog.delete_all

      ActivityLog.define_singleton_method(:inscribe) { |source_model, who_did_it, from_state, to_state, log_type, comments = nil| }
      ActivityLog.define_singleton_method(:log_event_with_user_readable_format) { |who_did_it, record| }
      #Audit.define_singleton_method(:log_entry_in_activity_logs) { }

      @cur_user = create(:user)
      @user_2 = create(:user)
      @user_1 = create(:user)

      User.current_user = @cur_user

      @request_1 = create(:request)
      @request_2 = create(:request)

      @step = create(:step)

      @al_1 = create_activity_log(:activity => 'ActivityLog #1', :user => @user_1, :request => @request_1, :type => 'aaa')
      @al_2 = create_activity_log(:activity => 'ActivityLog #2', :user => @user_1, :request => @request_2, :step => @step, :type => 'bbb')
      @al_3 = create_activity_log(:activity => 'ActivityLog #3', :user => @user_2, :request => @request_1, :step => @step)
      @al_4 = create_activity_log(:activity => 'ActivityLog #4', :user => @user_2, :request => @request_2)
    end

    after(:all) do
      ActivityLog.delete_all
      Step.delete(@step)
      Request.delete([@request_1, @request_2])
      User.delete([@cur_user, @user_1, @user_2])
    end

    describe 'filter by default' do
      subject { described_class.filtered() }
      it { should match_array([@al_1, @al_2, @al_3, @al_4]) }
    end

    describe 'filter by type' do
      subject { described_class.filtered(:type => 'aaa') }
      it { should match_array([@al_1]) }
    end

    describe 'filter by request_id' do
      subject { described_class.filtered(:request_id => @request_2.id) }
      it { should match_array([@al_2, @al_4]) }
    end

    describe 'filter by user_id' do
      subject { described_class.filtered(:user_id => @user_1.id) }
      it { should match_array([@al_1, @al_2]) }
    end

    describe 'filter by step_id' do
      subject { described_class.filtered(:step_id => @step.id) }
      it { should match_array([@al_2, @al_3]) }
    end

    describe 'filter by type, request_id, user_id, step_id' do
      subject { described_class.filtered(:type => 'bbb',
                                         :request_id => @request_2.id,
                                         :user_id => @user_1.id,
                                         :step_id => @step.id) }
      it { should match_array([@al_2]) }
    end

    describe 'filter (empty) by type, request_id, user_id, step_id' do
      subject { described_class.filtered(:type => 'xxx',
                                         :request_id => @request_1.id,
                                         :user_id => @user_2.id,
                                         :step_id => @step.id) }
      it { should be_empty }
    end
  end

  protected

  def create_activity_log(options = nil)
    create(:activity_log, options)
  end

end
