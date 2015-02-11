require 'spec_helper'

describe IntegrationProject do
  before(:each) do
    @integration_project = IntegrationProject.new
  end

  let(:IntegrationProject_with_SoftDelete) {
    IntegrationProject.new do
      include IntegrationProject::SoftDelete
    end
  }

  it { @integration_project.should validate_presence_of(:name) }

  it 'should have associations' do
    @integration_project.should belong_to(:project_server)
    @integration_project.should have_many(:releases)
    @integration_project.should have_many(:release_content_items)
  end

  it 'should have the scopes' do
    IntegrationProject.should respond_to(:active)
    IntegrationProject.should respond_to(:inactive)
    IntegrationProject.should respond_to(:name_order)
  end

  it { @integration_project.release_names.should == @integration_project.releases.map(&:name) }
end
             