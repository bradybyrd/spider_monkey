module PropertyUpdater
  def edit_property_values
    @object = params[:object].camelize.constantize.find params[:id]
    # authorize! :edit, @object

    render :template => 'properties/edit_property_values', locals: { object: @object }, :layout => false
  end

  def update_property_values
    @object = params[:object].camelize.constantize.find params[:id]
    # authorize! :edit, @object

    params[:property_values].each do |property_id, new_value|
      Property.find(property_id).update_value_for_object(@object, new_value)
    end

    redirect_to instance_eval("edit_#{params[:object]}_path(#{params[:id]})")
  end
end
