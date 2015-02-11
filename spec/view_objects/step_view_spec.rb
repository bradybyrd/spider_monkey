require 'spec_helper'

describe StepView do
  let(:step)      { mock_model(Step) }
  let(:step_view) { StepView.new(step) }

  describe '#script_name' do
    it 'returns the script name' do
      script  = mock_model(Script, name: 'holy sh1')
      step.stub(:script) { script }

      expect(step_view.script_name).to eq 'holy sh1'
    end

    it 'returns "deleted script" if does not exist' do
      step.stub(:script) { nil }
      step_view = StepView.new(step)

      expect(step_view.script_name).to eq 'SCRIPT DELETED'
    end
  end

end
