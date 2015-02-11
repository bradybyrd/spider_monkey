class PropertyValueDecorator < ApplicationDecorator
  decorates :property_value

  def value
    object.property.private? ? I18n.t('property.private_value') : object.value
  end
end
