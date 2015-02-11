################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

# This extends the definition in the acts_as_audited gem
class Audit < ActiveRecord::Base
  attr_accessible :action, :audited_changes, :comment, :auditable_id, :auditable_type,
                  :user_id, :user_type, :username, :version, :created_at, :associated_id,
                  :associated_type, :remote_address

  #Log = Logger.new(File.join(Rails.root, 'log', "#{Rails.env}.activity.log"))
  #after_create :write_log_file
  # after_create :log_entry_in_activity_logs, :if => Proc.new {|a| a[:audited_changes].respond_to?(:keys) ? a[:audited_changes].keys.include?('rescheduled') : false}
  after_create { |record|
    unless record.auditable_type == 'App'
      RequestActivity::AuditActivityMessage.new(record).log_modification
    end
  }
  
  def self.export_audit(app)
      exp_audit = Audit.new
      exp_audit.action = "export"
      exp_audit.user_type = "User"
      exp_audit.auditable_type = "App"
      exp_audit.user_id = User.current_user.id
      exp_audit.username = User.current_user.login
      exp_audit.version = 0
      exp_audit.audited_changes = "Exported application #{app.name}"
      exp_audit.save
  end

  def self.import_audit(app)
      imp_audit = Audit.new
      imp_audit.action = "import"
      imp_audit.user_type = "User"
      imp_audit.auditable_type = "App"
      imp_audit.user_id = User.current_user.id
      imp_audit.username = User.current_user.login
      imp_audit.version = 0
      imp_audit.audited_changes = "Imported application #{app.name}"
      imp_audit.save
  end

  private

  def write_log_file
    time = created_at.to_s(:audit)
    attrs = []
    attrs << ["User=\"#{user.name_for_index}\""] if user
    attrs << ["#{auditable_type}=#{auditable.to_param}"]
    attrs += audited_changes.map do |key, values|
      values = [values].flatten
      values = values.map do |value|
        value = value.to_formatted_s(:audit) if value.respond_to?(:to_formatted_s)
        value = value.blank? ? "[blank]" : "\"#{value}\""
      end
      value_string = values.first
      value_string << "=>#{values.last}" if values.size > 1
      "#{key}=#{value_string}"
    end
    attrs = attrs.join(', ')

    Log.info("#{time} INFO #{auditable_type}Events - #{attrs}")
  end

  def log_entry_in_activity_logs
    Thread.new do
      ActiveRecord::Base.connection_pool.with_connection do
        if self[:audited_changes]['rescheduled']
          log_me = self[:audited_changes]['rescheduled'].is_a?(TrueClass) ? self[:audited_changes]['rescheduled'] == true : self[:audited_changes]['rescheduled'][1] == true
          if log_me
            activity_log = ActivityLog.new
            activity_log.user_id = self.user_id
            activity_log.request_id = self.auditable_id
            activity_log.activity = 'Rescheduled'
            activity_log.save
          end
        end
      end
    end.join
  end

end
