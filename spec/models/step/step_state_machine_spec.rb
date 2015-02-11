require 'spec_helper'

describe Step do
  before { Notifier.stub(:delay).and_return(Notifier.send(:new)) }

  shared_examples 'mailer callbacks are triggered' do
    it ':ready_for_work' do
      Step.any_instance.should_receive(:send_mail_ready).and_call_original
      step.ready_for_work!
      step.should be_ready
    end

    it ':start' do
      Step.any_instance.stub(:startable_with_blade_password?).and_return(true)
      Step.any_instance.should_receive(:send_mail_start).and_call_original
      step.start!
      step.should be_in_process
    end

    it ':done' do
      Step.any_instance.stub(:completeable?).and_return(true)
      Step.any_instance.should_receive(:send_mail_complete).and_call_original
      step.done!
      step.should be_complete
    end

    it ':problem' do
      step.request.stub(:aasm_state).and_return('started')
      step.aasm_state = 'in_process'
      Step.any_instance.should_receive(:send_mail_problem).and_call_original
      step.problem!
      step.should be_problem
    end

    it ':block' do
      Step.any_instance.should_receive(:send_mail_block).and_call_original
      step.block!
      step.should be_blocked
    end
  end

  describe 'mailer events' do
    let(:request) do
      create(:request, notify_on_step_ready: true, notify_on_step_start: true,
                       notify_on_step_complete: true, notify_on_step_problem: true,
                       notify_on_step_block: true)
    end

    describe 'should skip notifications' do
      it_behaves_like 'mailer callbacks are triggered' do
        let(:step) { create(:step, request: request, suppress_notification: true) }
        before { Notifier.should_not_receive(:step_status_mail) }
      end
    end

    describe 'should not skip notifications' do
      it_behaves_like 'mailer callbacks are triggered' do
        let(:step) { create(:step, request: request, suppress_notification: false) }
        before { Notifier.any_instance.should_receive(:step_status_mail) }
      end
    end
  end
end
