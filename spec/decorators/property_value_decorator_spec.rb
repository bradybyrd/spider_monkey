require 'spec_helper'

describe PropertyValueDecorator do

  describe '#value' do
    it 'returns "-private-" as property_value value for private properties' do
      property = build_stubbed(:property, is_private: true)
      property_value = build_stubbed(:property_value, property: property)
      decorator = PropertyValueDecorator.new(property_value)

      expect(decorator.value).to eq private_property_value
    end

    it 'returns actual property_value value for non private property_value' do
      property = build_stubbed(:property, is_private: false)
      property_value = build_stubbed(:property_value, property: property, value: 'b a n a n a s')
      decorator = PropertyValueDecorator.new(property_value)

      expect(decorator.value).to eq 'b a n a n a s'
    end
  end

  def private_property_value
    I18n.t('property.private_value')
  end
end
