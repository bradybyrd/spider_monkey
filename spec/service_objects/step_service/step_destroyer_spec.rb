require 'spec_helper'

describe StepService::StepDestroyer do
  let(:step) { build :step }
  let(:procedure) { build :step, procedure: true }
  let(:destroyer) { StepService::StepDestroyer.new(step) }

  describe '#destroy_execution_condition' do
    let(:step) { create :step }
    let(:execution_condition) { mock 'execution_condition' }

    context 'with execution_condition present' do
      before { StepExecutionCondition.stub(:find_by_referenced_step_id) { execution_condition } }

      it 'does it successfully' do
        execution_condition.should_receive(:destroy)
        destroyer.destroy_execution_condition
      end
    end
  end

  describe '#destroy' do
    it 'is safe' do
      destroyer.should_receive :safe_destroy
      destroyer.destroy
    end

    it 'works without auditing step' do
      destroyer.step.should_receive :without_auditing
      destroyer.destroy
    end

    it 'works without specified callbacks' do
      destroyer.step.should_not_receive :stitch_package_template_id
      destroyer.step.should_not_receive :check_installed_component
      destroyer.step.should_not_receive :remove_execution_conditions
      destroyer.destroy
    end

    context 'with persisted step' do
      let(:step) { create :step }

      it 'works successfully' do
        destroyer.destroy
        expect(destroyer.step).to be_destroyed
      end
    end

    context 'when step is a procedure' do
      let(:destroyer) { StepService::StepDestroyer.new(procedure) }

      it '#destroy_execution_condition' do
        destroyer.step.stub(:without_auditing).and_return(true)
        destroyer.should_receive :destroy_execution_condition
        destroyer.destroy
      end
    end
  end

end
