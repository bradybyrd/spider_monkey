################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class ApplicationEnvironmentsController < ApplicationController
  before_filter :find_application
  before_filter :find_application_environment, :only => [:update, :edit, :show]
  include ApplicationHelper

  def index
    render :partial => "apps/default_environment.html", :locals => {:app => @app}
  end

  def add_remove
    authorize! :add_remove, ApplicationEnvironment.new

    environments = Environment.active.reorder('lower(name) ASC')
    render :partial => 'application_environments/add_remove', :locals => {:environments => environments, :app => @app}
  end

  def update
    @application_environment.update_attributes(params[:environment])

    render :partial => 'for_reorder', :locals => { :app => @app, :environment => @application_environment }
  end

  def update_all
    authorize! :add_remove, ApplicationEnvironment.new

    @app.environment_ids = params[:environment_ids] || []
    @app.save
    if params[:new_environments] && can?(:create, Environment.new)
      new_environment = Environment.create(params[:new_environments])
      new_environment_ids = new_environment.map(&:id).compact
    end

    environment_ids = [params[:environment_ids], new_environment_ids].flatten.compact.map(&:to_i)

    # To record in RecentActivity when new Envirmnment added to App.
    (environment_ids - @app.environment_ids).each do |environment_id|
      environment = Environment.find environment_id
        env_link = environment_link(environment)
        # environment.update_attribute(:updated_at, environment.updated_at)
        @app.application_environments.create(:environment_id => environment_id)
    end

    @app.reload
    @app.alpha_sort_envs if @app.a_sorting_envs
    #PermissionMap.instance.bulk_clean(@app.users)
    PermissionMap.instance.clean(current_user)

    render :partial => "apps/default_environment"
  end

  def edit
    render :partial => 'apps/application_environment_edit_row', :locals => {:app => @app, :application_environment => @application_environment}
  end

  def show
    render :partial => 'apps/application_environment_show_row', :locals => {:app => @app, :application_environment => @application_environment}
  end

  protected

    def find_application_environment
      @application_environment = ApplicationEnvironment.find_by_id_and_app_id(params[:id], @app.id)
    end
end
