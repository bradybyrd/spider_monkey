class AddMissingIndexesFoundByLolDba < ActiveRecord::Migration
  def up
    add_index :package_properties, :property_id
    add_index :package_properties, [:package_id, :property_id]
    add_index :group_management, [:group_id, :manager_id]
    add_index :step_references, :step_id
    add_index :step_references, [:owner_object_id, :owner_object_type]
    add_index :scripts, :created_by
    add_index :team_group_app_env_roles, [:role_id, :team_group_id]
    add_index :plan_templates, :created_by
    add_index :apps_procedures, [:app_id, :procedure_id]
    add_index :procedures, :created_by
    add_index :package_references, :package_id
    add_index :package_references, :server_id
    add_index :job_runs, :automation_id
    add_index :job_runs, :user_id
    add_index :application_packages, [:app_id, :package_id]
    add_index :application_packages, :app_id
    add_index :application_packages, :package_id
    add_index :instance_references, :reference_id
    add_index :instance_references, :package_instance_id
    add_index :instance_references, :server_id
    add_index :application_components, [:app_id, :component_id]
    add_index :requests, :parent_request_id
    add_index :deployment_window_series, :created_by
    add_index :request_templates, :created_by
    add_index :package_instances, :package_id
  end

  def down
    remove_index :package_properties, column: :property_id
    remove_index :package_properties, column: [:package_id, :property_id]
    remove_index :group_management, column: [:group_id, :manager_id]
    remove_index :step_references, column: :step_id
    remove_index :step_references, column: [:owner_object_id, :owner_object_type]
    remove_index :scripts, column: :created_by
    remove_index :team_group_app_env_roles, column: [:role_id, :team_group_id]
    remove_index :plan_templates, column: :created_by
    remove_index :apps_procedures, column: [:app_id, :procedure_id]
    remove_index :procedures, column: :created_by
    remove_index :package_references, column: :package_id
    remove_index :package_references, column: :server_id
    remove_index :job_runs, column: :automation_id
    remove_index :job_runs, column: :user_id
    remove_index :application_packages, column: [:app_id, :package_id]
    remove_index :application_packages, column: :app_id
    remove_index :application_packages, column: :package_id
    remove_index :instance_references, column: :reference_id
    remove_index :instance_references, column: :package_instance_id
    remove_index :instance_references, column: :server_id
    remove_index :application_components, column: [:app_id, :component_id]
    remove_index :requests, column: :parent_request_id
    remove_index :deployment_window_series, column: :created_by
    remove_index :request_templates, column: :created_by
    remove_index :package_instances, column: :package_id
  end
end
