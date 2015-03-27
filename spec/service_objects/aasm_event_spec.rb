require 'spec_helper'

describe AasmEvent::ExecuteEvent do
  let(:object) { create(:request) }
  let(:executable_event) { AasmEvent::ExecuteEvent.new(object) }

  describe '#validate_aasm_event' do
    context 'validation success' do
      it 'returns no errors' do
        object.aasm_state = 'created'
        object.aasm_event = 'plan_it'
        executable_event.validate_aasm_event
        expect(object.errors[:aasm_event]).to be_blank
      end
    end

    context 'validate fails' do
      it 'returns error - not supported event' do
        object.aasm_state = 'created'
        object.aasm_event = 'some_event'
        supported_events = object.class.aasm.events.map(&:name).reject { |event_name| [:created].include?(event_name) }
        executable_event.validate_aasm_event
        result_error = ["was not included in supported events: #{supported_events.to_sentence}."]
        expect(object.errors[:aasm_event]).to eq(result_error)
      end
    end
  end

  describe '#run_aasm_event' do
    it 'change object aasm_state' do
      object.aasm_state = 'created'
      object.aasm_event = 'plan_it'
      executable_event.run_aasm_event
      expect(object).to be_planned
    end
  end

  describe '#get_supported_events' do
    it 'returns created' do
      supported_events = [:plan_it, :start, :problem_encountered, :resolve,
                          :put_on_hold, :cancel, :finish, :reopen, :soft_delete]
      expect(executable_event.get_supported_events).to eq(supported_events)
    end
  end

  describe '#rejected_events' do
    it 'returns key created' do
      expect(executable_event.rejected_events).to eq([:created])
    end
  end

  describe '#check_transition' do
    let(:event) { object.class.aasm.events.find{|event| event.name == object.aasm_event.to_sym} }

    context 'when can do transition' do
      it 'returns nil' do
        object.aasm_state = 'created'
        object.aasm_event = 'plan_it'
        expect(executable_event.check_transition(event)).to be_nil
      end
    end

    context 'when cannot do transition' do
      it 'add object errors' do
        object.aasm_state = 'created'
        object.aasm_event = 'start'
        executable_event.check_transition(event)
        result_error = ['was not a valid transition for current state: created.']
        expect(object.errors[:aasm_event]).to eq(result_error)
      end
    end
  end

  describe '#get_obj_command' do
    it 'returns command with !' do
      object.aasm_event = 'start'
      expect(executable_event.get_obj_command).to eq('start!')
    end
  end

  describe '#add_notes' do
    context 'when event note blank' do
      it 'returns nil' do
        executable_event.add_notes
        expect(object.log_comments).to be_nil
      end
    end

    context 'when event note present' do
      it 'create note for object' do
        object.aasm_event = 'start'
        object.aasm_event_note = 'start_notes'
        executable_event.add_notes
        expect(object.log_comments).to eq('[START] start_notes')
      end
    end
  end
end

describe AasmEvent::PlanExecuteEvent do
  let(:object) { create(:plan) }
  let(:executable_event) { AasmEvent::PlanExecuteEvent.new(object) }

  describe '#rejected_events' do
    it 'returns key created' do
      expect(executable_event.rejected_events).to eq([:created, :delete])
    end
  end
end

describe AasmEvent::StepExecuteEvent do
  let(:object) { create(:step) }
  let(:executable_event) { AasmEvent::StepExecuteEvent.new(object) }

  describe '#get_obj_command' do
    it 'returns command with !' do
      object.aasm_event = 'ready_for_work'
      expect(executable_event.get_obj_command).to eq('ready_for_work!')
    end

    it 'returns lets_start!' do
      object.aasm_event = 'start'
      expect(executable_event.get_obj_command).to eq('lets_start!')
    end

    it 'returns all_done!' do
      object.aasm_event = 'done'
      expect(executable_event.get_obj_command).to eq('all_done!')
    end
  end
end
