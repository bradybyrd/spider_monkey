class RenameTeamsGroupToTeamGroup < ActiveRecord::Migration
  def up
    rename_table :teams_groups, :team_groups
  end

  def down
    rename_table :team_groups, :teams_groups
  end
end
