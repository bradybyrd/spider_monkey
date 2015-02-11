class TeamDecorator < ApplicationDecorator
  decorates :team

  delegate_all

  def link
    h.link_to object.name, h.edit_team_path(object)
  end

  def app_checkbox_hint(app)
    I18n.t('team.app_checkbox_disabled_hint') if object_policy.app_disabled?(app)
  end

  def group_checkbox_hint(group)
    I18n.t('team.group_checkbox_disabled_hint') if object_policy.group_disabled?(group)
  end

  private

  def object_policy
    object.team_policy
  end

end
