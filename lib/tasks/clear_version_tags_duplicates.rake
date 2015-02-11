namespace :version_tags do
  desc 'Cleans Version Tags table from duplicates and associates duplicated records associations with unique records'
  task clear_duplicates: :environment do
    puts 'Working...'

    grouped_version_tags = VersionTag.select('id, name, app_id, installed_component_id, artifact_url').where('installed_component_id IS NOT NULL').group_by do |version_tag|
                             [version_tag.name, version_tag.app_id, version_tag.installed_component_id, version_tag.artifact_url]
                           end

    grouped_version_tags.values.each do |duplicates|
      original_version_tag = duplicates.shift

      duplicates.each do |duplicate|
        duplicate.steps.update_all(version_tag_id: original_version_tag.id)
        duplicate.linked_items.where(target_holder_id: duplicate.id).update_all(target_holder_id: original_version_tag.id)
        duplicate.linked_items.update_all(source_holder_id: original_version_tag.id)
        duplicate.properties_values.joins(:property).update_all(value_holder_id: original_version_tag.id)
        puts "Duplicated Version Tag => id: #{duplicate.id}, name: #{duplicate.name} was deleted. Original id: #{original_version_tag.id}"
        duplicate.delete
      end
    end

    puts 'Done.'
  end
end
