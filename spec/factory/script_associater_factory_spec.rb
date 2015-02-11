require 'spec_helper'

describe ScriptAssociaterFactory do
  describe '#instance' do
    it 'instantiates the NullScriptImporter if script automation category does not exist' do
      create(:script, name: 'ExistingScript', automation_category: 'SuperScripts')
      step = double(:step)
      associater_instance = double(:null_script_associater)
      script_attributes = {name: 'ExistingScript', automation_category: 'Non existing category'}

      allow(StepService::ScriptImporter::NullScriptAssociater).to receive(:new).and_return(associater_instance)

      expect(ScriptAssociaterFactory.new(step, script_attributes).instance).to eq associater_instance
    end

    it 'instantiates the NullScriptImporter if script does not exist' do
      create_automation_category('ExistingCategory')
      step = double(:step)
      associater_instance = double(:null_script_associater)
      script_attributes = {name: 'Non existing script name', automation_category: 'ExistingCategory'}

      allow(StepService::ScriptImporter::NullScriptAssociater).to receive(:new).and_return(associater_instance)

      expect(ScriptAssociaterFactory.new(step, script_attributes).instance).to eq associater_instance
    end

    it 'instantiates the AutomationScriptImporter if script type is not BladelogicScript' do
      create_automation_category('SuperScripts')
      create(:script, name: 'ExistingScript', automation_category: 'SuperScripts')
      step = double(:step)
      associater_instance = double(:automation_script_associater)
      script_attributes = {automation_category: 'SuperScripts', type: 'Not Bladelogic', name: 'ExistingScript'}

      allow(StepService::ScriptImporter::AutomationScriptAssociater).to receive(:new).and_return(associater_instance)

      expect(ScriptAssociaterFactory.new(step, script_attributes).instance).to eq associater_instance
    end

    it 'instantiates the BladelogicScriptImporter if script type is BladelogicScript' do
      create(:bladelogic_script, name: 'Yupi')
      step = double(:step)
      associater_instance = double(:bladelogic_script_associater)
      script_attributes = {name: 'Yupi',
                           type: 'BladelogicScript',
                           automation_category: 'BLA'}

      allow(GlobalSettings).to receive(:[]).with(:bladelogic_enabled).and_return(true)
      allow(StepService::ScriptImporter::BladelogicScriptAssociater).to receive(:new).and_return(associater_instance)

      expect(ScriptAssociaterFactory.new(step, script_attributes).instance).to eq associater_instance
    end

    def create_automation_category(automation_category)
      automation_list = create :list, name: 'AutomationCategory'
      create :list_item, value_text: automation_category, list: automation_list
    end
  end
end