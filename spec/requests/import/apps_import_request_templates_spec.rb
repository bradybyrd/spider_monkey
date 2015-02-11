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
      xml_file = File.open('spec/data/SomeRelease.xml', 'r')
      xml_content = xml_file.read
      let(:imported_hash) { Hash.from_xml(xml_content) }

      let(:params) { xml_content }

      subject { response.body }
      it { should have_xpath("#{xml_root}/id").with_text(added_app.id) }
      it { should have_xpath("#{xml_root}/name").with_text(added_app.name) }


      it 'has imported version-tags' do
        imported_version_tags.each do |xml_req|
            vt = VersionTag.find_by_name(xml_req['name'])
            expect(vt.name).to eq(xml_req['name'])
        end
      end

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

      it 'has imported request templates with steps,work task' do
        imported_steps.each do |xml_step|
          step = WorkTask.find_by_name(xml_step['work_task']['name'])
          expect(step.name).to eq(xml_step['work_task']['name'])
        end
      end

      it 'has imported request templates with steps,version_tag' do
        imported_steps.each do |xml_step|
          if xml_step.has_key?('component')
            version_tag = VersionTag.find_by_name(xml_step['component_version'])
            expect(version_tag.name).to eq(xml_step['component_version'])
          end
        end
      end

      it 'has imported request templates with steps,component' do
        imported_steps.each do |xml_step|
          if xml_step['component']['name']
            step = Component.find_by_name(xml_step['component']['name'])
            expect(step.name).to eq(xml_step['component']['name'])
          end
        end
      end

      it 'has imported request templates with steps,package' do
        imported_requests.each do |xml_req|
          xml_req['steps'].each do |xml_step|
            if xml_step['package']['name']
              step = Package.find_by_name(xml_step['package']['name'])
              expect(step.name).to eq(xml_step['package']['name'])
            end
          end
        end
      end

      it 'has imported request templates with releases' do
        imported_requests.each do |xml_req|
          release = Release.find_by_name(xml_req['release']['name'])
          expect(release.name).to eq(xml_req['release']['name'])
        end
      end

      it 'has imported request templates with business process' do
        imported_requests.each do |xml_req|
          businessprocess = BusinessProcess.find_by_name(xml_req['business_process']['name'])
          expect(businessprocess.name).to eq(xml_req['business_process']['name'])
        end
      end

      it 'has imported request templates with activity' do
        imported_requests.each do |xml_req|
          if xml_req['activity']
            activity = Activity.find_by_name(xml_req['activity']['name'])
            expect(activity.name).to eq(xml_req['activity']['name'])
          end
        end
      end

      it 'has imported request templates with phases and runtime phases' do
        imported_steps.each do |xml_step|
          step = Step.find_by_name(xml_step['name'])

          expect(step.phase.name).to eq(xml_step['phase']['name'])
          expect(step.phase.position).to eq(xml_step['phase']['position'])

          expect(step.runtime_phase.name).to eq(xml_step['runtime_phase']['name'])
          expect(step.runtime_phase.position).to eq(xml_step['runtime_phase']['position'])
        end
      end

      it 'has imported request templates,steps with properties for InstalledComponent' do
        imported_steps.each do |xml_step|
          xml_step['temporary_property_values'].each do |xml_tmp|
            tmp = TemporaryPropertyValue.find_by_value(xml_tmp['value'])
            expect(tmp.value).to eq(xml_tmp['value'])
          end
        end
      end

      it 'has imported request templates with automation scripts' do
        imported_scripts.each do |xml_script|
          script = Script.find_by_name xml_script['name']
          expect(script.name).to eq xml_script['name']
        end
      end

    end
  end

  describe 'import with app_import xml content' do
    let(:url) { "#{base_url}/?token=#{@user.api_key}" }

    it_behaves_like 'successful request', type: :xml, method: :post, status: 201 do
      app_name = 'SomeRelease1'
      let(:added_app) { App.where(name: app_name).first || App.new }
      xml_file = File.open('spec/data/import_app_with_no_automation.xml', 'r')
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

      it 'has imported request templates with no automation script' do
        imported_requests.each do |xml_req|
          request = Request.find_by_name(xml_req['name'])
          expect(Script.all).to be_empty
        end
      end

    end
  end

  private

  def imported_steps
    imported_requests.flat_map do |request|
      request['steps']
    end
  end

  def imported_scripts
    imported_requests.flat_map do |request|
      request['request_template']['automation_scripts_for_export']
    end.compact
  end

  def imported_requests
    imported_hash['app_import']['app']['requests_for_export']
  end

  def imported_version_tags
    imported_hash['app_import']['app']['version_tags']
  end

end
