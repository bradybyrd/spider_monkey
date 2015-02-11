class AddRequestNotificationTemplates < ActiveRecord::Migration
 def self.up
    connection.execute("SET IDENTITY_INSERT notification_templates ON") if MsSQLAdapter
    connection.execute(%{INSERT INTO notification_templates ( id, title, format, event, description, body, template, active, created_at, updated_at, subject )
                        VALUES ( '100010', 'Request Planned', 'text/html', 'request_planned', 'A request notification when a request is planned.',
                        '<p>Request: {{params.SS_request_url}} is planned.</p>
                        <p>ISSUES<br />
                          ==============================<br />
                          {{ params.default_support_email }}<br />
                          and we will respond as quickly as possible--usually within 1 hour between 8am <br />
                          and 5pm EST.</p>
                        <p>Thanks,</p>
                        <p>BRPM Admin</p>

                        ', null, '#{RPMTRUE}', #{DATE_NOW}, #{DATE_NOW}, 'Request {{params.SS_request_number}} is planned')});
    connection.execute(%{INSERT INTO notification_templates ( id, title, format, event, description, body, template, active, created_at, updated_at, subject )
                        VALUES ( '100011', 'Request Started', 'text/html', 'request_started', 'A request notification for started requests.',
                        '<p>Message: {{ params.SS_message }}</p>
                        <p>Request: {{params.SS_request_url}} is started</p>
                        <p>ISSUES<br />
                          ==============================<br />
                          {{ params.default_support_email }}<br />
                          and we will respond as quickly as possible--usually within 1 hour between 8am <br />
                          and 5pm EST.</p>
                        <p>Thanks,</p>
                        <p>BRPM Admin</p>

                        ', null, '#{RPMTRUE}', #{DATE_NOW}, #{DATE_NOW}, 'Request {{params.SS_request_number}} is started')});
    connection.execute(%{INSERT INTO notification_templates ( id, title, format, event, description, body, template, active, created_at, updated_at, subject )
                        VALUES ( '100012', 'Request In Problem', 'text/html', 'request_in_problem', 'A request notification for requests in problem.',
                        '<p>Request: {{params.SS_request_url}} is in problem.</p>
                        <p>ISSUES<br />
                          ==============================<br />
                          {{ params.default_support_email }}<br />
                          and we will respond as quickly as possible--usually within 1 hour between 8am <br />
                          and 5pm EST.</p>
                        <p>Thanks,</p>
                        <p>BRPM Admin</p>

                        ', null, '#{RPMTRUE}', #{DATE_NOW}, #{DATE_NOW}, 'Request {{params.SS_request_number}} is in problem')});
    connection.execute(%{INSERT INTO notification_templates ( id, title, format, event, description, body, template, active, created_at, updated_at, subject ) 
                        VALUES ( '100013', 'Request Resolved', 'text/html', 'request_resolved', 'A request notification when a request is resolved.',
                        '<p>Request: {{params.SS_request_url}} is resolved.</p>
                        <p>ISSUES<br />
                          ==============================<br />
                          {{ params.default_support_email }}<br />
                          and we will respond as quickly as possible--usually within 1 hour between 8am <br />
                          and 5pm EST.</p>
                        <p>Thanks,</p>
                        <p>BRPM Admin</p>

                        ', null, '#{RPMTRUE}', #{DATE_NOW}, #{DATE_NOW}, 'Request {{params.SS_request_number}} is resolved')});
    connection.execute(%{INSERT INTO notification_templates ( id, title, format, event, description, body, template, active, created_at, updated_at, subject ) 
                        VALUES ( '100014', 'Request On Hold', 'text/html', 'request_on_hold', 'A request notification for requests that have been put on hold.',
                        '<p>Message: {{ params.SS_message }}</p>
                        <p>Request: {{params.SS_request_url}} has been put on hold.</p>
                        <p>ISSUES<br />
                          ==============================<br />
                          {{ params.default_support_email }}<br />
                          and we will respond as quickly as possible--usually within 1 hour between 8am <br />
                          and 5pm EST.</p>
                        <p>Thanks,</p>
                        <p>BRPM Admin</p>

                        ', null, '#{RPMTRUE}', #{DATE_NOW}, #{DATE_NOW}, 'Request {{params.SS_request_number}} has been put on hold')});

    connection.execute("SET IDENTITY_INSERT notification_templates OFF") if MsSQLAdapter
  end

  def self.down
    connection.execute(%{delete from notification_templates where id IN (100010,100011,100012, 100013,100014)})
  end
end
