class AddUserProfileUpdatedNotificationFailedNotificationTemplate < ActiveRecord::Migration
  def self.up
    connection.execute("SET IDENTITY_INSERT notification_templates ON") if MsSQLAdapter
    connection.execute(%{
      INSERT INTO notification_templates ( id, title, format, event, description, body, template, active, created_at, updated_at, subject )
      VALUES (
        '100017',
        'User profile updated email notification failed',
        'text/html',
        'user_profile_updated_notification_failed',
        'A system notification for email notification failed if user password was changed',
        'Hi BRPM Admin,<br /><br />
         Profile information for {{params.SS_user_first_name}}, {{params.SS_user_last_name}} has been successfuly updated, but email notification failed:<br /><br />
         NEW ACCOUNT<br />
         ============<br />
         Account username is:<br />
         {{params.SS_user_login}}<br /><br />
         {{params.SS_user_email}}<br /><br />
         KEEP THIS EMAIL<br />
         ===============<br />
         This email contains important information about your account<br />
         so you will want to keep it for future reference should you have any<br />
         questions.<br /><br />
         LOGGING IN TO BMC RELEASE PROCESS MANAGEMENT<br />
         ==============================<br />
         {{params.SS_login_url}}<br /><br />
         ISSUES<br />
         ==============================<br />
         {{params.default_support_email}}<br />
         and we will respond as quickly as possible--usually within 1 hour between 8am<br />
         and 5pm EST.<br /><br />
         Thanks,<br /><br />
         BRPM Admin<br />',
        null, '#{RPMTRUE}', #{DATE_NOW}, #{DATE_NOW},
        'User profile updated email notification failed'
      )
    });
    connection.execute("SET IDENTITY_INSERT notification_templates OFF") if MsSQLAdapter
  end

  def self.down
    connection.execute(%{delete from notification_templates where event= 'user_profile_updated_notification_failed'})
  end
end
