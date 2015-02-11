################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

class V1::AppsPresenter < V1::AbstractPresenter

  # creates a local accessor based on the passed symbol
  presents :apps

  private

  def resource_options
    if export_app
      build_apps_detailed_hash
    else
      apps_regular_hash
    end
  end

  def build_apps_detailed_hash
    resulting_hash = apps_detailed_hash

    if optional_components.include?(:servers)
      resulting_hash[:include][:environments][:include][:active_environment_servers] = environment_servers_hash
      resulting_hash[:include][:installed_components][:include][:servers] = { only: [:name] }
      resulting_hash[:include][:environments][:include][:active_server_groups][:include][:active_servers] = servers_hash
    end
    if export_request_templates?
      if export_automations?
        resulting_hash[:methods] = :requests_for_export_with_automations
      else
        resulting_hash[:methods] = :requests_for_export
      end
      resulting_hash[:include][:active_procedures] = procedures_hash
    end
    if optional_components.include?(:deployment_windows)
      resulting_hash[:include][:environments][:methods] = :active_deployment_window_series
    end
    resulting_hash
  end

  def export_request_templates?
    optional_components.include?(:req_templates)
  end

  def export_automations?
    export_request_templates? && optional_components.include?(:automations)
  end

  def apps_regular_hash
    { only: [:id, :name, :app_version, :active, :default, :created_at, :updated_at],
      include: {
        requests: { only: [:id, :name] },
        steps: { only: [:id, :name] },
        environments: { only: [:id, :name] },
        components: { only: [:id, :name] },
        installed_components: { only: [:id, :name, :environment_id, :component_id] },
        teams: { only: [:id, :name] },
        users: { only: [:id, :login, :email, :last_name, :first_name] },
        tickets: { only: [:id, :name, :foreign_id, :status, :ticket_type, :project_server_id] },
        routes: { only: [:id, :name, :route_type],
                  include: {
                    route_gates: { only: [:id, :description] }
                  }
        }
      }
    }
  end

  def procedures_hash
    { only: [:name, :aasm_state, :description],
      include: { steps: steps_hash } }
  end

  def apps_detailed_hash
    {
      only: [:name, :app_version, :active, :strict_plan_control, :a_sorting_envs, :a_sorting_comps],
      include: {
        components: components_hash,
        environments: environments_hash,
        active_packages: packages_hash,
        installed_components: installed_components_hash,
        active_routes: routes_hash,
        active_business_processes: business_processes_hash,
        version_tags: version_tags_hash,
        application_packages: { only: [],
          include: {
            property_values: { only: [:value], methods: [:name]},
              package: { only: [:name] }
          }
        }
      }
    }
  end

  def routes_hash
    { only: [:name, :route_type, :description],
      include: {
        route_gates: { only: [:description, :position, :different_level_from_previous],
                       include: {
                         environment: { only: [:name] }
                       }
        }
      }
    }
  end

  def components_hash
    {
      only: [:name, :active],
      include: { active_properties: { only: [:name, :default_value, :is_private, :active] }}
    }
  end

  def environments_hash
    { only: [:name, :active, :deployment_policy],
      include: {
        environment_type: { except: [:id, :archived_at, :created_at, :updated_at, :archive_number] },
        active_server_groups: { only: [:name, :description, :active],
                         include: {}}
      }
    }
  end

  def packages_hash
    { only: [:name, :instance_name_format, :next_instance_number],
      include: {
        properties: { only: [:name, :default_value, :is_private, :active] },
        references: { only: [:name, :resource_method, :uri],
                      include: {
                        property_values: { only: [:value], methods: [:name]},
                        server: { only: [], :methods => [:name]}
                      }
        },
        package_instances: { only: [:name],
                             include: {
                               property_values: { only: [:value], methods: [:name]},
                               instance_references: { only: [:name, :resource_method, :uri],
                                                      include: {
                                                        reference: { only: [:name] },
                                                        property_values: { only: [:value], methods: [:name]},
                                                        server: { only: [], methods: [:name]}
                                                      }
                               }
                             }
        }
      }
    }
  end

  def environment_servers_hash
    { only: [:name],
      include: {
        server: {only: [:name, :active, :dns, :ip_address, :os_platform],
                 include: {
                   properties: { only: [:name, :default_value, :is_private, :active] },
                   current_property_values: { only: [:value, :locked], methods: [:name]}
                 }
        }
      }
    }
  end

  def servers_hash
    { only: [:name, :active, :dns, :ip_address, :os_platform],
      include: {
        properties: { only: [:name, :default_value, :is_private, :active] },
        current_property_values: { only: [:value, :locked], methods: [:name] }
      }
    }
  end

  def business_processes_hash
    {
      only: [:name, :label_color]
    }
  end

  def installed_components_hash
    {
      except: [:id, :application_component_id, :application_environment_id, :reference_id,
               :created_at, :updated_at, :default_server_group_id],
      include: {
        find_properties: {only: [:value, :locked], methods: [:name] },
        server_group: { only: [:name] },
        server_aspects: server_aspects_hash,
        server_aspect_groups: server_aspect_groups_hash,
        application_component: {
          except: [:id, :app_id, :component_id, :created_at, :updated_at],
          include: { component: { only: [:name, :active] }
          }
        },
        application_environment: { only: [], methods: [:name] }
      }
    }
  end

  def server_aspects_hash
    {
      only: [:name, :parent_type, :description],
      include: {
        server_level: { only: [:name, :description],
                        include: {
                          properties: { only: [:name, :default_value, :is_private, :active] }
                        }
        },
        parent: { except: [:id, :created_at, :updated_at] },
        current_property_values: { only: [:value, :locked], methods: [:name]}
      }
    }
  end

  def server_aspect_groups_hash
    { only: [:name],
      include: {
        server_level: { only: [:name, :description],
                        include: {
                          properties: { only: [:name, :default_value, :is_private, :active] }
                        }
        },
        server_aspects: { only: [:name, :parent_type, :description],
                          include: {
                            parent: { except: [:id, :created_at, :updated_at] },
                            current_property_values: { only: [:value, :locked], methods: [:name]}
                          }
        }
      }
    }
  end

  def version_tags_hash
    { only: [:name, :artifact_url], methods: [:component_name,:environment_name] }
  end

  def steps_hash
    StepExportOptions.new(export_automations?).options
  end

  def is_app_export?
    export_app
  end

end
