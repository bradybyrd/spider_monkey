require 'spec_helper'

describe JobRun do

  describe '#filtered' do

    before(:all) do
      JobRun.delete_all
      @user = create(:user)
      User.current_user = @user
      @step = create(:step)
      @jr1 = create_job_run(:job_type => 'automation', :status => 'complete', :run_key => 123, :process_id => 258, :automation_id => 888, :user_id => @user.id, :step_id => @step.id)
      @jr2 = create_job_run(:job_type => 'notification', :status => 'starting', :run_key => 555, :process_id => 333)
      User.current_user = nil
    end

    after(:all) do
      JobRun.delete_all
      Step.delete(@step)
      User.delete(@user)
    end

    describe 'filter by default' do
      subject { described_class.filtered }
      it { should match_array([@jr1, @jr2]) }
    end

    describe 'filter by automation_id, user_id, step_id' do
      subject { described_class.filtered(:automation_id => 888, :user_id => @user.id, :step_id => @step.id) }
      it { should match_array([@jr1]) }
    end

    describe 'filter by status, job_type, process_id' do
      subject { described_class.filtered(:status => 'starting', :job_type => 'notification', :process_id => 333) }
      it { should match_array([@jr2]) }
    end

    describe 'filter by currently_running, run_key' do
      subject { described_class.filtered(:currently_running => true, :run_key => 555) }
      it { should match_array([@jr2]) }
    end

    describe 'filter empty' do
      subject { described_class.filtered(:currently_running => true, :run_key => 123) }
      it { should be_empty }
    end
  end

  protected

  def create_job_run(options = nil)
    create(:job_run, options)
  end

end
