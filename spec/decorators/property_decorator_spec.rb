require 'spec_helper'

describe PropertyDecorator do

  describe '#value' do
    it 'returns "-private-" as property value for private properties' do
      property = build_stubbed(:property, is_private: true)
      decorator = PropertyDecorator.new(property)

      expect(decorator.value).to eq private_property_value
    end

    it 'returns actual property value for non private property' do
      property = build_stubbed(:property, is_private: false, default_value: '* is bananas')
      decorator = PropertyDecorator.new(property)

      expect(decorator.value).to eq '* is bananas'
    end
  end

  def private_property_value
    I18n.t('property.private_value')
  end
end
