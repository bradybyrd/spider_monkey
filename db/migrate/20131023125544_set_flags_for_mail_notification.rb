class SetFlagsForMailNotification < ActiveRecord::Migration
  def up
    Request.update_all( notify_on_request_step_owners: true,
                        notify_on_step_step_owners: true,
                        notify_on_step_requestor_owner: false,
                        notify_on_step_participiant: true,
                        notify_on_request_participiant: true,
                        notify_group_only: false )
  end

  def down
    Request.update_all( notify_on_request_step_owners: true,
                        notify_on_step_step_owners: true,
                        notify_on_step_requestor_owner: false,
                        notify_on_step_participiant: true,
                        notify_on_request_participiant: true,
                        notify_group_only: false )
  end
end
