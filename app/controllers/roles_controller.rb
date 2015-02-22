require 'permission_manager'

class RolesController < ApplicationController
  include ControllerSoftDelete

  before_filter :find_role, only: [:edit, :update, :destroy, :deactivate]
  before_filter :prepare_search_params, only: [:index]

  def index
    @roles = Role.search(@search_params[:q])
    @roles_amount = @roles.active.count
    respond_to do |format|
      format.html {
        if request.xhr?
          if @roles.present?
            params[:scope].present? ? render(partial: 'list', locals: {scope: params[:scope].to_sym}) : render(partial: 'lists')
          else
            render partial: 'shared/blank_data_message', locals: { message: t('role.none') }
          end
        end
      }
      format.json { render json: @roles }
    end
  end

  def new
    @role = Role.new
    authorize!(:create, @role)
    @role.permissions = Permission.all
  end

  def edit
    authorize!(:edit, @role)
  end

  def create
    @role = Role.new(params[:role])
    authorize!(:create, @role)

    if @role.save
      redirect_to roles_path, notice: t('role.was_created')
    else
      render action: "new"
    end
  end

  def update
    # if all permissions are unchecked
    params[:role][:permission_ids] ||= []

    authorize!(:edit, @role)
    if @role.update_attributes(params[:role])
      #PermissionMap.instance.bulk_clean(@role.users)
      redirect_to roles_path, notice: t('role.was_updated')
    else
      render action: "edit"
    end
  end

  def deactivate
    authorize! :make_active_inactive, @role

    flash[:error] = t('role.deactivate_error') unless @role.deactivate!
    redirect_to roles_path
  end

  def destroy
    authorize!(:delete, @role)
    @role.destroy
    redirect_to roles_url
  end

  private

  def find_role
    @role = Role.find params[:id]
  rescue ActiveRecord::RecordNotFound
    flash[:error] = t('role.not_found')
    redirect_to :back
  end

  def prepare_search_params
    @search_params = MappedParams::Search.(session_scope, params.dup.deep_symbolize_keys, Role)
    prepare_scoped_params
  end

  def prepare_scoped_params
    @query_params = {}
    @sorter_params = {}
    scopes = params[:scope].present? ? [params[:scope].to_sym] : [:active, :inactive]
    scopes.each do |scope|
      @query_params[scope] = [MappedParams::Order, MappedParams::Page].inject(@search_params.dup) do |params, mod|
        mod.(session_scope(scope), params, Role)
      end
      @sorter_params[scope] = session_scope(scope)[:collection_manipulations]
    end
  end
end
