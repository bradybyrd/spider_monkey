class InstanceReferencesController < ApplicationController
  include PropertyUpdater

  def destroy
    @instance_reference = find_instance_reference
    @instance_reference.destroy

    redirect_to edit_package_instance_path(@instance_reference.package_instance)
  end

  def edit
    @instance_reference = find_instance_reference
    redirect_to edit_package_instance_path(@instance_reference.package_instance)
  end

  private

  def find_instance_reference
    InstanceReference.find(params[:id])
  end
end
