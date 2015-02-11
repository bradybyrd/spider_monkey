class RoleDecorator < ApplicationDecorator
  decorates :role

  delegate_all

  def group_expandable_links
    association_expandable_links(group_links)
  end

  def team_expandable_links
    association_expandable_links(team_links)
  end

  private

  def group_links
    if current_ability.can? :edit, Group.new
      object.groups.uniq.map{ |group| group.decorate.link }
    else
      object.groups.uniq.map { |group| group.name }
    end
  end

  def team_links
    object.teams.uniq.map{ |team| team.decorate.link }
  end

  def current_ability
    @current_ability ||= Ability.new(User.current_user)
  end
end
