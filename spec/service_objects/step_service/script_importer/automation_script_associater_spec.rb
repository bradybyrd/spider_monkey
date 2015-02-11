require 'spec_helper'

describe StepService::ScriptImporter::AutomationScriptAssociater do
  let(:associater) { StepService::ScriptImporter::AutomationScriptAssociater }

  describe '#associate_imported_scripts' do
    it 'makes the step automatic' do
      step = build :step, manual: true
      script = create :script, name: 'Yupi', automation_category: 'General'
      script_attributes = {name: script.name, step_script_arguments: []}
      associater_instance = associater.new(step, script, script_attributes)

      associater_instance.associate_imported_scripts

      expect(step).to be_auto
    end

    it 'finds a script by name' do
      step = build :step
      script = create :script, name: 'Yupi', automation_category: 'General'
      script_attributes = {name: script.name, step_script_arguments: []}
      associater_instance = associater.new(step, script, script_attributes)

      associater_instance.associate_imported_scripts

      expect(associater_instance.script.id).to eq script.id
    end

    it 'assigns a script to a step' do
      step = build :step
      script = create :script, name: 'Yupi', automation_category: 'General'
      script_attributes = {name: script.name, step_script_arguments: []}
      associater_instance = associater.new(step, script, script_attributes)

      associater_instance.associate_imported_scripts

      expect(step.script.id).to eq script.id
      expect(step.script).to be_an_instance_of Script
    end

    it 'sets the script arguments value' do
      step = build :step
      script = create :script, name: 'Yupi', automation_category: 'General'
      script_argument_a = create :script_argument, argument: 'action 1', script: script
      script_argument_b = create :script_argument, argument: 'action 2', script: script
      script_attributes = {
          name: script.name,
          step_script_arguments: [
              {
                  value: [['echo I work... or not']],
                  script_argument_id: script_argument_a.id,
                  script_argument_type: 'ScriptArgument'
              },
              {
                  value: [['echo I definitely work']],
                  script_argument_id: script_argument_b.id,
                  script_argument_type: 'ScriptArgument'
              }
          ]
      }
      associater_instance = associater.new(step, script, script_attributes)

      associater_instance.associate_imported_scripts

      expect(step.step_script_arguments[0].value).to eq [['echo I work... or not']]
      expect(step.step_script_arguments[1].value).to eq [['echo I definitely work']]
    end

  end
end