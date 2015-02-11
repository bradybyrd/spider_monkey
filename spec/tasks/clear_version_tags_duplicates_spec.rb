require 'spec_helper'
require 'rake'

describe 'Version Tags duplicates deletion' do
  let(:rake_task) { 'version_tags:clear_duplicates' }


  let!(:application) { create(:app) }
  let!(:installed_component) { create(:installed_component) }
  let(:attributes){ { name: '1', artifact_url: 'http://test.com', app: application, installed_component: installed_component } }

  let!(:version_tag) { create(:version_tag, attributes) }

  let!(:duplicated_version_tag) do
    tag = build(:version_tag, attributes)
    tag.save(validate: false)
    tag
  end

  let!(:step) { create(:step, version_tag: version_tag) }
  let!(:step_with_duplicated_tag) { create(:step, version_tag: duplicated_version_tag) }

  let(:run_rake_task) do
    Rake::Task[rake_task].reenable
    expect{ Rake.application.invoke_task(rake_task) }.to change(VersionTag, :count).by(-1)
    version_tag.should be_persisted
  end

  before do
    Rake.application.rake_require 'tasks/clear_version_tags_duplicates'
    Rake::Task.define_task(:environment)
  end

  it 'reassigns step of duplicate version tag to original version tag' do
    run_rake_task
    version_tag.reload.steps.should include step_with_duplicated_tag
  end

  it 'reassigns linked item of duplicate version tag to original version tag' do
    linked_item = create(:version_tag_linked_item, source_holder: duplicated_version_tag)
    version_tag.linked_items.should be_blank
    run_rake_task
    version_tag.reload.linked_items.should include linked_item
  end

  it 'reassigns duplicated target holder of linked item to original version tag to prevent relations on deleted duplicates' do
    linked_item = create(:version_tag_linked_item, source_holder: duplicated_version_tag, target_holder: duplicated_version_tag)
    version_tag.linked_version_tags.should be_blank
    run_rake_task
    version_tag.reload.linked_version_tags.should include version_tag
  end

  it 'reassigns property values from duplicate version tag to original' do
    property_value = create(:property_value, value_holder: duplicated_version_tag)
    version_tag.properties_values.should be_blank
    run_rake_task
    version_tag.reload.properties_values.should include property_value
  end
end
