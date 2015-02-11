class ReferencesController < ApplicationController
  def new
    @reference = Reference.new
    authorize! :create, @reference
    @package = find_package
    @servers = accessible_servers
  end


  def destroy
    @reference = find_reference
    authorize! :delete, @reference
    @package = @reference.package
    @reference.destroy

    redirect_to edit_package_path(@package)
  end


  def create
    @package = find_package
    @reference = @package.references.new(reference_params)
    authorize! :create, @reference
    @servers = accessible_servers
    if @reference.save
      redirect_to edit_package_reference_path(@package, @reference)
    else
      render :new
    end
  end

  def update
    @reference = find_reference
    authorize! :edit, @reference
    @package = find_package
    @servers = accessible_servers
    if @reference.update_attributes(reference_params)
      redirect_to edit_package_path(@package)
    else
      render :edit
    end
  end

  def edit
    @reference = find_reference
    authorize! :edit, @reference
    @package = find_package
    @servers = accessible_servers
  end

  private

  def find_package
    Package.find(params[:package_id])
  end

  def find_reference
    @reference ||= Reference.find(params[:id])
  end

  def accessible_servers
    @reference.available_servers_for(current_user)
  end

  def reference_params
    params[:reference]
  end
end
