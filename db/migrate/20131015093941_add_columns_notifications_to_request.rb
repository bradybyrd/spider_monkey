class AddColumnsNotificationsToRequest < ActiveRecord::Migration
  def up
  	add_column :requests, :notify_on_request_planned, :boolean, default: false, null: false
  	add_column :requests, :notify_on_request_problem, :boolean, default: false, null: false
  	add_column :requests, :notify_on_request_resolved, :boolean, default: false, null: true
    add_column :requests, :notify_on_request_step_owners, :boolean, default: false, null: false
    add_column :requests, :notify_on_step_step_owners, :boolean, default: false, null: false
    add_column :requests, :notify_on_step_requestor_owner, :boolean, default: false, null: false
    add_column :requests, :notify_on_step_participiant, :boolean, default: false, null: false
    add_column :requests, :notify_on_request_participiant, :boolean, default: false, null: false
    add_column :requests, :notify_group_only, :boolean, default: true, null: false
  end
  def down
  	remove_column :requests, :notify_on_request_planned
    remove_column :requests, :notify_on_request_problem
  	remove_column :requests, :notify_on_request_resolved
  	remove_column :requests, :notify_on_request_step_owners
  	remove_column :requests, :notify_on_step_step_owners
  	remove_column :requests, :notify_on_step_requestor_owner
  	remove_column :requests, :notify_on_step_participiant
  	remove_column :requests, :notify_on_request_participiant
  	remove_column :requests, :notify_group_only
  end
end
