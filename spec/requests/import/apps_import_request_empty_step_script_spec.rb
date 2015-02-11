require 'spec_helper'

describe '/v1/apps', import_export: true do
  before :each do
    @user = create(:user)
    create(:activity)
    create(:team, name: '[default]')
  end

  let(:base_url) { '/v1/apps' }
  let(:json_root) { :app }
  let(:xml_root) { 'app' }
  let(:import_root) { 'app_import/app' }
  let(:params) { {token: @user.api_key} }
  subject { response }

  describe 'import with app_import xml content' do
    let(:url) { "#{base_url}/?token=#{@user.api_key}" }
    before(:all) { enable_automations }

    it_behaves_like 'successful request', type: :xml, method: :post, status: 201 do
      app_name = 'SomeRelease'
      let(:added_app) { App.where(name: app_name).first || App.new }
      xml_file = File.open('spec/data/import_app_empty_step_script.xml', 'r')
      xml_content = xml_file.read
      let(:imported_hash) { Hash.from_xml(xml_content) }

      let(:params) { xml_content }

      subject { response.body }
      it { should have_xpath("#{xml_root}/id").with_text(added_app.id) }
      it { should have_xpath("#{xml_root}/name").with_text(added_app.name) }

      it 'has imported request templates' do
        imported_requests.each do |xml_req|
          request = Request.find_by_name(xml_req['name'])
          expect(request.name).to eq(xml_req['name'])
        end
      end

      it 'has imported request templates with steps' do
        imported_steps.each do |xml_step|
          step = Step.find_by_name(xml_step['name'])
          expect(step.name).to eq(xml_step['name'])
        end
      end

      it 'has imported request templates,steps with empty scripts' do
        imported_steps.each do |xml_step|
          expect(xml_step['step_script_arguments']).to be_empty
        end
      end

      it 'saved current user as owner of step with unspecified owner' do
        step = Step.find_by_name('no_owner')
        expect(step.owner).to eq(@user)
      end

      it 'saved current users group for step that has unknown owner group' do
        step = Step.find_by_name('bogus_group')
        expect(step.owner).to eq(@user.groups.first)
      end

    end
  end


  private

  def imported_steps
    imported_requests.flat_map do |request|
      request['steps']
    end
  end

  def imported_requests
    imported_hash['app_import']['app']['requests_for_export']
  end

end
