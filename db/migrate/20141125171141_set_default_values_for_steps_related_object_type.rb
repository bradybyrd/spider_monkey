class SetDefaultValuesForStepsRelatedObjectType < ActiveRecord::Migration
  def up
    execute %q(UPDATE steps SET related_object_type = 'component' WHERE related_object_type = '' OR related_object_type IS NULL)
  end
end
