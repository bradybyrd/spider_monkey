require 'spec_helper'

describe StepService::ScriptImporter::BladelogicScriptAssociater do
  let(:associater) { StepService::ScriptImporter::BladelogicScriptAssociater }

  describe '#associate_imported_scripts' do
    it 'makes the step automatic' do
      step = build :step, manual: true
      script = create :bladelogic_script, name: 'Yupi'
      script_attributes = {name: script.name, step_script_arguments: []}
      associater_instance = associater.new(step, script, script_attributes)

      associater_instance.associate_imported_scripts

      expect(step).to be_auto
    end

    it 'finds a script by name' do
      step = build :step
      script = create :bladelogic_script, name: 'Yupi'
      script_attributes = {name: script.name, step_script_arguments: []}
      associater_instance = associater.new(step, script, script_attributes)

      associater_instance.associate_imported_scripts

      expect(associater_instance.script.id).to eq script.id
    end

    it 'assigns a found script to a step' do
      step = build :step
      script = create :bladelogic_script, name: 'Yupi'
      script_attributes = {name: script.name, step_script_arguments: []}
      associater_instance = associater.new(step, script, script_attributes)

      associater_instance.associate_imported_scripts

      expect(step.script.id).to eq script.id
      expect(step.script).to be_an_instance_of BladelogicScript
    end
  end


end