class GroupDeactivationPolicy
  attr_reader :group

  def initialize(group)
    @group = group
  end

  def can_be_deactivated?
    resources_have_more_than_one_active_group? && !name_is_root?
  end

  private

  def resources_have_more_than_one_active_group?
    resources.all? do |user|
      user.groups.active.count > 1
    end
  end

  def resources
    group.resources.includes(:groups)
  end

  def name_is_root?
    group.name == Group::ROOT_NAME
  end
end
