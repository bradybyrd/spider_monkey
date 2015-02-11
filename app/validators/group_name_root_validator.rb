class GroupNameRootValidator < ActiveModel::Validator
  def validate(record)
    if record.name == options[:name] || record.name_was == options[:name]
      is_always_root(record, options[:name])
      contains_at_least_one_resource(record, options[:name])
      name_has_not_changed(record, options[:name])
    end
  end

  private

  def is_always_root(record, name)
    record.errors.add(:base, I18n.t(:'group.errors.cannot_be_made_non_root', name: name)) unless record.root?
  end

  def contains_at_least_one_resource(record, name)
    record.errors.add(:base, I18n.t(:'group.errors.should_contain_at_lease_one_user', name: name)) if record.resources.none?
  end

  def name_has_not_changed(record, name)
    record.errors.add(:base, I18n.t(:'group.errors.name_cannot_be_changed', name: name)) unless record.name == name
  end

end