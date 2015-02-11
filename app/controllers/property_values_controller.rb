class PropertyValuesController < ApplicationController
  def new
    @reference = Reference.find(params[:reference_id])
    @property_value = PropertyValue.new
    @properties = @reference.properties_that_can_be_overridden
    render layout: false
  end

  def edit
    @reference = Reference.find(params[:reference_id])
    @property_value = PropertyValue.find(params[:id])
    render layout: false
  end

  def update
    @reference = Reference.find(params[:reference_id])
    @property_value = PropertyValue.find(params[:id])
    @property_value.update_attributes!(property_value_params)
    redirect_to edit_package_reference_path(@reference.package, @reference),
      notice: 'Property value updated'
  end

  def create
    @reference = Reference.find(params[:reference_id])
    @property_value = @reference.property_values.new(property_value_params)
    @property_value.property_id = property_to_override
    @property_value.save!
    redirect_to edit_package_reference_path(@reference.package, @reference),
      notice: 'Property value overridden'
  end

  def destroy
    PropertyValue.destroy(params[:id])
    redirect_to :back, notice: 'Overridden property was deleted'
  end

  private

  def property_value_params
    params[:property_value].slice(:value)
  end

  def property_to_override
    params[:property_value][:property]
  end
end
