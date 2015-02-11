class AddAlphaSortEnvsAndCompsToApps < ActiveRecord::Migration
  def change
    add_column :apps, :a_sorting_envs, :boolean, default: false, null: false
    add_column :apps, :a_sorting_comps, :boolean, default: false, null: false
  end
end
