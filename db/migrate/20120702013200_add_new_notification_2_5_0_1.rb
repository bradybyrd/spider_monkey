################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

class AddNewNotification2501 < ActiveRecord::Migration
  def self.up
    add_column :requests, :notify_on_step_problem, :boolean
    add_column :requests, :notify_on_step_ready, :boolean
    add_column :requests, :notify_on_request_cancel, :boolean
    connection.execute("SET IDENTITY_INSERT notification_templates ON") if MsSQLAdapter
    connection.execute(%{INSERT INTO notification_templates ( id, title, format, event, description, body, template, active, created_at, updated_at, subject ) 
                        VALUES ( '100000', 'Request Cancelled', 'text/html', 'request_cancelled', 'A request notification when a request is cancelled.', '<p>Request {{params.SS_request_number}}: {{params.request_name}} is cancelled.</p>
<p>Request: {{params.SS_edit_request_url}}</p>
<p>Thanks,</p>
<p>BRPM Admin</p>

', null, '#{RPMTRUE}', #{DATE_NOW}, #{DATE_NOW}, 'Request {{params.SS_request_number}} is cancelled')});
    connection.execute(%{INSERT INTO notification_templates ( id, title, format, event, description, body, template, active, created_at, updated_at, subject ) 
                         VALUES ( '100001', 'Step Ready', 'text/html', 'step_ready', 'A step notification when a step has ready.', '<p>Step {{params.step_number}}: "{{params.step_name}}" on 
Request {{params.request_id}}: {{params.request_name}} 
is ready.</p>
<p>Request: {{params.SS_edit_request_url}}</p>
<p>ISSUES<br />
  ==============================<br />
  {{ params.default_support_email }}<br />
  and we will respond as quickly as possible--usually within 1 hour between 8am <br />
  and 5pm EST.</p>
<p>Thanks,</p>
<p>BRPM Admin</p>

', null, '#{RPMTRUE}', #{DATE_NOW}, #{DATE_NOW}, 'Step {{params.step_position}} on Request {{params.SS_request_number}} is Ready')});
    connection.execute("SET IDENTITY_INSERT notification_templates OFF") if MsSQLAdapter
  end

  def self.down
    remove_column :requests, :notify_on_step_problem
    remove_column :requests, :notify_on_step_ready
    remove_column :requests, :notify_on_request_cancel
    connection.execute(%{delete from notification_templates where event= 'request_cancelled'})
    connection.execute(%{delete from notification_templates where event= 'step_ready'})
  end
end
