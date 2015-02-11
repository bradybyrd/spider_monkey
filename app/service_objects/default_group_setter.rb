class DefaultGroupSetter
  attr_reader :group, :default_team

  def initialize(group)
    @group = group
  end

  def make_default_and_assign_to_default_team
    make_default
    assign_to_default_team
  end

  private
  def make_default
    group.insert_at 1
  end

  def assign_to_default_team
    if default_team
      default_team.add_group(group)
    end
  end

  def default_team
    @default_team ||= Team.default
  end

end