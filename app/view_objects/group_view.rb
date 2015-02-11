class GroupView
  attr_reader :group

  def initialize(group)
    @group = group
  end

  def team_names
    group.teams.select('teams.name').collect{ |t| t.name }.join(', ')
  end

  def root
    group.root? ? I18n.t(:yup) : I18n.t(:nope)
  end

end