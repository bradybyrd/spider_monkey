class AddRequestDwNotificationTemplate < ActiveRecord::Migration
  def self.up
    connection.execute("SET IDENTITY_INSERT notification_templates ON") if MsSQLAdapter
    connection.execute(%{
      INSERT INTO notification_templates ( id, title, format, event, description, body, template, active, created_at, updated_at, subject )
      VALUES (
        '100015',
        'Request not Started due to DW',
        'text/html',
        'request_failed_to_start_of_deployment_window',
        'A request notification when a request has failed to start because of Deployment Window validations.',
        '<p>Your request {{params.SS_request_number}} has failed to start because of certain reasons:</p>
<p>{{params.SS_message}}</p>

<span>Please verify the following parameters for the request :</span>
<ul>
  <li>Planned Start</li>
  <li>Estimate</li>
  <li>Deployment Window</li>
</ul>
<p>Request: {{params.SS_request_url}}</p>

<p>ISSUES<br />
  ==============================<br />
  {{ params.default_support_email }}<br />
  and we will respond as quickly as possible--usually within 1 hour between 8am <br />
  and 5pm EST.</p>
<p>Thanks,</p>
<p>BRPM Admin</p>',
        null, '#{RPMTRUE}', #{DATE_NOW}, #{DATE_NOW},
        'Request {{params.SS_request_number}} has failed to start because of Deployment Window validations'
      )
    });
    connection.execute("SET IDENTITY_INSERT notification_templates OFF") if MsSQLAdapter
  end

  def self.down
    connection.execute(%{delete from notification_templates where event= 'request_failed_to_start_of_deployment_window'})
  end
end
