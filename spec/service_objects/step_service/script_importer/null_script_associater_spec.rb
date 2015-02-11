require 'spec_helper'

describe StepService::ScriptImporter::NullScriptAssociater do

  describe '#associate_imported_scripts' do
    it 'makes step manual' do
      step = build :step, manual: false

      StepService::ScriptImporter::NullScriptAssociater.new(step).associate_imported_scripts

      expect(step).to be_manual
    end
  end


end