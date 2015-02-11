require 'spec_helper'

describe StepDecorator do

  describe '#component_name_formatted' do
    it 'returns non-break space for new step' do
      step = Step.new
      decorator = StepDecorator.new(step)

      expect(decorator.component_name_formatted).to eq('&nbsp;')
    end

    it 'returns package name when step has package assigned' do
      package = build_stubbed :package
      step = build_stubbed :step, package: package
      decorator = StepDecorator.new(step)

      expect(decorator.component_name_formatted).to eq(package.name)
    end
  end

end
