/*
 Navicat Premium Data Transfer

 Source Server         : local_pg
 Source Server Type    : PostgreSQL
 Source Server Version : 90004
 Source Host           : localhost
 Source Database       : brpm_develop_2_5
 Source Schema         : public

 Target Server Type    : PostgreSQL
 Target Server Version : 90004
 File Encoding         : utf-8

 Date: 03/24/2012 12:29:36 PM
*/

-- ----------------------------
--  Table structure for "notification_templates"
-- ----------------------------
DROP TABLE IF EXISTS "notification_templates";
CREATE TABLE "notification_templates" (
	"id" int4 NOT NULL DEFAULT nextval('notification_templates_id_seq'::regclass),
	"title" varchar(255) NOT NULL,
	"format" varchar(255) NOT NULL DEFAULT 'email_text'::character varying,
	"event" varchar(255) NOT NULL,
	"description" text,
	"body" text,
	"template" text,
	"active" bool NOT NULL DEFAULT false,
	"created_at" timestamp(6) NULL,
	"updated_at" timestamp(6) NULL,
	"subject" varchar(255)
)
WITH (OIDS=FALSE);
ALTER TABLE "notification_templates" OWNER TO "brpm_user";

-- ----------------------------
--  Records of "notification_templates"
-- ----------------------------
BEGIN;
INSERT INTO "notification_templates" VALUES ('1', 'Exception Raised', 'text/html', 'exception_raised', 'A system notification for application exceptions.', '<p>The following exception was raised at {{params.SS_company_name}}:</p> <br/>
{% if params.SS_exception_message %}
<p><strong>Message:</strong></p>
<p>{{params.SS_exception_message}}</p>
{% endif %}
{% if params.SS_exception_backtrace %}
<p><strong>Backtrace:</strong></p>
<p>{{params.SS_exception_backtrace}}</p>
{% endif %}
<p>LOGGING IN TO BMC RELEASE PROCESS MANAGEMENT<br />
  ==============================<br />
  {{ params.SS_login_url }}<br />
</p>

', null, 't', '2012-02-28 21:12:23.045', '2012-02-28 21:12:23.045', 'Exception raised at {{params.SS_company_name}}');
INSERT INTO "notification_templates" VALUES ('2', 'Login', 'text/html', 'login', 'A user notification when user requests their login.', '<p>Hi {{ params.SS_user_first_name }},</p>
<p>You have recently requested User ID.</p>
<p>YOUR ACCOUNT<br />
  ============<br />
  Your account username is:<br />
{{ params.SS_user_login }}</p>
<p>KEEP THIS EMAIL<br />
  ===============<br />
  This email contains important information about your account <br />
  so you''ll want to keep it for future reference should you have any<br />
  questions.<br />
</p>

<p>LOGGING IN TO BMC RELEASE PROCESS MANAGEMENT<br />
  ==============================<br />
  {{ params.SS_login_url }}<br />
</p>

<p>ISSUES<br />
  ==============================<br />
  {{ params.default_support_email }}<br />
  and we will respond as quickly as possible--usually within 1 hour between 8am <br />
  and 5pm EST.</p>
<p>Thanks,</p>
<p>BRPM Admin</p>

', null, 't', '2012-02-28 21:12:23.065', '2012-02-28 21:12:23.065', 'Login requested for {{ params.SS_user_login }}');
INSERT INTO "notification_templates" VALUES ('3', 'Password Reset', 'text/html', 'password_reset', 'A user notification when user resets their account password.', '<p>Hi {{ params.SS_user_first_name }},</p>
<p>You have recently requested to reset your account password</p>
<p>YOUR ACCOUNT<br />
  ============<br />
  Your account username is:<br />
{{ params.SS_user_login }}</p>
  Your initial account password is:<br />
{{ params.SS_user_password }}</p>
<p>If you did not request to reset your password, please <br>
contact your system administrator so that the security <br>
of your account may be confirmed.</p>
<p>KEEP THIS EMAIL<br />
  ===============<br />
  This email contains important information about your account <br />
  so you''ll want to keep it for future reference should you have any<br />
  questions.<br />
</p>

<p>LOGGING IN TO BMC RELEASE PROCESS MANAGEMENT<br />
  ==============================<br />
  {{ params.SS_login_url }}<br />
</p>

<p>ISSUES<br />
  ==============================<br />
  {{ params.default_support_email }}<br />
  and we will respond as quickly as possible--usually within 1 hour between 8am <br />
  and 5pm EST.</p>
<p>Thanks,</p>
<p>BRPM Admin</p>

', null, 't', '2012-02-28 21:12:23.086', '2012-02-28 21:12:23.098', 'Your password has been reset');
INSERT INTO "notification_templates" VALUES ('4', 'User Created', 'text/html', 'user_created', 'A user notification when user is created.', '<p>Hi {{ params.SS_user_first_name }},</p>
<p>You have recently requested to reset your account password:</p>
<p>YOUR ACCOUNT<br />
  ============<br />
  Your account username is:<br />
{{ params.SS_user_login }}</p>
  Your initial account password is:<br />
{{ params.SS_user_password }}</p>
<p>This password is temporary; you will be asked to change it on first login.</p>
<p>KEEP THIS EMAIL<br />
  ===============<br />
  This email contains important information about your account <br />
  so you''ll want to keep it for future reference should you have any<br />
  questions.<br />
</p>

<p>LOGGING IN TO BMC RELEASE PROCESS MANAGEMENT<br />
  ==============================<br />
  {{ params.SS_login_url }}<br />
</p>

<p>ISSUES<br />
  ==============================<br />
  {{ params.default_support_email }}<br />
  and we will respond as quickly as possible--usually within 1 hour between 8am <br />
  and 5pm EST.</p>
<p>Thanks,</p>
<p>BRPM Admin</p>

', null, 't', '2012-02-28 21:12:23.116', '2012-02-28 21:12:23.116', 'Welcome to BMC Release Process Management - {{ params.SS_user_first_name }}');
INSERT INTO "notification_templates" VALUES ('5', 'Request Message', 'text/html', 'request_message', 'A request notification when user sends a comment to another user.', '<p>{{ message }}</p>
<p>Request: {{params.SS_request_url}}</p>
<p>ISSUES<br />
  ==============================<br />
  {{ params.default_support_email }}<br />
  and we will respond as quickly as possible--usually within 1 hour between 8am <br />
  and 5pm EST.</p>
<p>Thanks,</p>
<p>BRPM Admin</p>

', null, 't', '2012-02-28 21:12:23.124', '2012-02-28 21:12:23.124', null);
INSERT INTO "notification_templates" VALUES ('6', 'Request Completed', 'text/html', 'request_completed', 'A request notification when a request has completed.', '<p>Request {{params.SS_request_number}}: {{params.request_name}} is complete.</p>
<p>Request: {{params.SS_edit_request_url}}</p>
<p>ISSUES<br />
  ==============================<br />
  {{ params.default_support_email }}<br />
  and we will respond as quickly as possible--usually within 1 hour between 8am <br />
  and 5pm EST.</p>
<p>Thanks,</p>
<p>BRPM Admin</p>

', null, 't', '2012-02-28 21:12:23.137', '2012-02-28 21:12:23.137', 'Request {{params.SS_request_number}} is complete');
INSERT INTO "notification_templates" VALUES ('7', 'Step Started', 'text/html', 'step_started', 'A step notification when a step has started.', '<p>Step {{params.step_number}}: "{{params.step_name}}" on 
Request {{params.request_id}}: {{params.request_name}} 
has started.</p>
<p>Request: {{params.SS_edit_request_url}}</p>
<p>ISSUES<br />
  ==============================<br />
  {{ params.default_support_email }}<br />
  and we will respond as quickly as possible--usually within 1 hour between 8am <br />
  and 5pm EST.</p>
<p>Thanks,</p>
<p>BRPM Admin</p>

', null, 't', '2012-02-28 21:12:23.151', '2012-02-28 21:12:23.151', 'Step {{params.step_position}} on Request {{params.SS_request_number}} has started');
INSERT INTO "notification_templates" VALUES ('8', 'Step Completed', 'text/html', 'step_completed', 'A step notification when a step has completed.', '<p>Step {{params.step_number}}: "{{params.step_name}}" on 
Request {{params.request_id}}: {{params.request_name}} 
is complete.</p>
<p>Request: {{params.SS_edit_request_url}}</p>
<p>ISSUES<br />
  ==============================<br />
  {{ params.default_support_email }}<br />
  and we will respond as quickly as possible--usually within 1 hour between 8am <br />
  and 5pm EST.</p>
<p>Thanks,</p>
<p>BRPM Admin</p>

', null, 't', '2012-02-28 21:12:23.16', '2012-02-28 21:12:23.16', 'Step {{params.step_position}} on Request {{params.SS_request_number}} is complete');
INSERT INTO "notification_templates" VALUES ('9', 'Step Problem', 'text/html', 'step_problem', 'A step notification when a step has a problem.', '<p>Step {{params.step_number}}: "{{params.step_name}}" on 
Request {{params.request_id}}: {{params.request_name}} 
has been marked ''Problem'':</p>
{% if note %}
  <p>Message: {{note}}</p>
{% endif %}
<p>Request: {{params.SS_edit_request_url}}</p>
<p>ISSUES<br />
  ==============================<br />
  {{ params.default_support_email }}<br />
  and we will respond as quickly as possible--usually within 1 hour between 8am <br />
  and 5pm EST.</p>
<p>Thanks,</p>
<p>BRPM Admin</p>

', null, 't', '2012-02-28 21:12:23.182', '2012-02-28 21:12:23.182', 'Step {{params.step_position}} on Request {{params.SS_request_number}} has a problem');
INSERT INTO "notification_templates" VALUES ('10', 'Step Blocked', 'text/html', 'step_blocked', 'A step notification when a step is blocked.', '<p>Step {{params.step_number}}: "{{params.step_name}}" on 
Request {{params.request_id}}: {{params.request_name}} 
has been marked ''Blocked'':</p>
{% if note %}
  <p>Message: {{note}}</p>
{% endif %}
<p>Request: {{params.SS_edit_request_url}}</p>
<p>ISSUES<br />
  ==============================<br />
  {{ params.default_support_email }}<br />
  and we will respond as quickly as possible--usually within 1 hour between 8am <br />
  and 5pm EST.</p>
<p>Thanks,</p>
<p>BRPM Admin</p>

', null, 't', '2012-02-28 21:12:23.189', '2012-02-28 21:12:23.189', 'Step {{params.step_position}} on Request {{params.SS_request_number}} is blocked');
INSERT INTO "notification_templates" VALUES ('11', 'User Admin Created', 'text/html', 'user_admin_created', 'A user notification when user is created from ldap or single sign-on.', '<p>Dear BRPM Admin,</p>
<p>A new account was added from a remote or single sign-on service.</p>
<p>NEW ACCOUNT<br />
  ============<br />
  Account username is:<br />
{{ params.SS_user_login }}</p>
<p>The user has a temporary name, email, and password upon first creation. 
They will be prompted to add details upon their first login.</p>
<p>The account currently has no rights. Please assign these users 
  appropriate roles and permissions.</p>
<p>KEEP THIS EMAIL<br />
  ===============<br />
  This email contains important information about your account <br />
  so you''ll want to keep it for future reference should you have any<br />
  questions.<br />
</p>

<p>LOGGING IN TO BMC RELEASE PROCESS MANAGEMENT<br />
  ==============================<br />
  {{ params.SS_login_url }}<br />
</p>

<p>ISSUES<br />
  ==============================<br />
  {{ params.default_support_email }}<br />
  and we will respond as quickly as possible--usually within 1 hour between 8am <br />
  and 5pm EST.</p>
<p>Thanks,</p>
<p>BRPM Admin</p>

', null, 't', '2012-02-28 21:12:23.201', '2012-02-28 21:12:23.201', 'New remote user account added to BMC Release Process Management - {{ params.SS_user_login }}');
COMMIT;

-- ----------------------------
--  Primary key structure for table "notification_templates"
-- ----------------------------
ALTER TABLE "notification_templates" ADD CONSTRAINT "notification_templates_pkey" PRIMARY KEY ("id") NOT DEFERRABLE INITIALLY IMMEDIATE;

-- ----------------------------
--  Indexes structure for table "notification_templates"
-- ----------------------------
CREATE INDEX "i_nt_event" ON "notification_templates" USING btree(event ASC NULLS LAST);
CREATE INDEX "i_nt_method" ON "notification_templates" USING btree(format ASC NULLS LAST);
CREATE INDEX "i_nt_title" ON "notification_templates" USING btree(title ASC NULLS LAST);

