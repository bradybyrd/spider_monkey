class PropertyDecorator < ApplicationDecorator
  decorates :property

  def value
    object.private? ? I18n.t('property.private_value') : object.default_value
  end
end
