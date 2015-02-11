class PermissionsPerEnvironmentValidator < ActiveModel::Validator
  def validate(record)
    action = record.new_record? ? :create : :edit
    if record.check_permissions && User.current_user.cannot?(action, record)
      record.errors.add(:base, I18n.t('permissions.action_not_permitted', action: action, subject: record.class.to_s.underscore.humanize))
    end
  end
end
