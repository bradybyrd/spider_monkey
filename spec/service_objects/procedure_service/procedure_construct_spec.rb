require 'spec_helper'

describe ProcedureService::ProcedureConstruct do
  let(:step)            { build :step }
  let(:procedure_steps) { build_list :step, 2 }
  let(:construct)       { ProcedureService::ProcedureConstruct.new(step) }

  def initialization
    ProcedureService::ProcedureConstruct.new(step)
  end

  it 'changes the step property `procedure` to true when #initialize' do
    expect{initialization}.to change{step.procedure}.to(true)
  end


  it '#save_procedure without auditing' do
    step.should_receive :save_without_auditing
    construct.save_procedure
  end

  it '#build_steps' do
    construct.send(:build_steps, procedure_steps)
    expect(step.steps.size).to eq(2)
  end

  context 'with built steps' do
    let(:step) { build :step, steps: procedure_steps }

    it '#build_steps_script_arguments' do
      procedure_steps.each_with_index do |procedure_step, i|
        Step.should_receive(:build_script_arguments_for).with(step.steps[i], procedure_step)
      end
      construct.send(:build_steps_script_arguments, step.steps, procedure_steps)
    end
  end

  describe '#attributes_for_new_step' do
    let(:expected_attributes) { attrs = step.attributes; attrs.delete('id'); attrs['request_id'] = request_id; attrs }
    let(:request_id) { 3 }

    def attributes
      construct.send(:attributes_for_new_step, step, request_id)
    end

    it 'returns the right hash' do
      expect(attributes).to eq expected_attributes
    end
  end

  describe '#add_to_request' do
    before { construct.add_to_request(procedure_steps) }

    it 'saves the procedure' do
      expect(step).to be_persisted
    end

    it 'saves the procedure steps' do
      step.steps.reload.each do |step|
        expect(step).to be_persisted
      end
    end
  end

end