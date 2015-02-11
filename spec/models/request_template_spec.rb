require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')


describe RequestTemplate do

  context '' do

    before(:all) do
      @request_template = RequestTemplate.new
    end

    let(:RequestTemplate_with_ArchivableModelHelpers) {
      RequestTemplate.new do
        include RequestTemplate::ArchivableModelHelpers
      end
    }

    describe 'validations' do
      it { @request_template.should validate_presence_of(:name) }
      it { @request_template.should validate_presence_of(:request) }
    end

    describe 'named scopes' do
      it { RequestTemplate.should respond_to :sorted }
      it { RequestTemplate.should respond_to :by_app_id }
      it { RequestTemplate.should respond_to :by_environment_id }
      it { RequestTemplate.should respond_to :name_order }
      it { RequestTemplate.should respond_to :template_siblings }
      it { RequestTemplate.should respond_to :filter_by_name }
    end

    describe 'associations' do
      it { @request_template.should have_one(:request) }
      it { @request_template.should have_many(:apps).through(:request) }
      it { @request_template.should belong_to(:parent_template) }
      it { @request_template.should have_many(:plan_stages_request_templates) }
      it { @request_template.should have_many(:plan_stages).through(:plan_stages_request_templates) }
    end
  end

  describe '#automation_scripts_for_export' do
    it 'returns hash to be used in app presenter for export' do
      step_with_script = create(:step_with_script)
      request_with_automated_steps = create(:request, steps: [step_with_script])
      request_template = create(:request_template, request: request_with_automated_steps)

      expect(request_template.automation_scripts_for_export).
        to eq [script_for_app_export(step_with_script.script)]
    end

    def script_for_app_export(script)
      script.as_json(
        only: [:name, :description, :aasm_state, :content, :automation_type, :automation_category]
      )
    end
  end

  describe '#filtered' do

    before(:all) do
      RequestTemplate.delete_all

      @user   = create(:user)
      User.current_user = @user

      @env1 = create(:environment)
      @env2 = create(:environment)
      @app1 = create(:app)
      @app2 = create(:app)

      @app1.environments << @env1
      @app2.environments << @env2

      AssignedEnvironment.create!(environment_id: @env1.id, assigned_app_id: @app1.assigned_apps.first.id, role: @user.roles.first)
      AssignedEnvironment.create!(environment_id: @env2.id, assigned_app_id: @app2.assigned_apps.first.id, role: @user.roles.first)

      @request1 = create(:request, apps: [@app1], environment: @env1)
      @request2 = create(:request, apps: [@app2], environment: @env2)

      def create_request_template(options = nil)
        create(:request_template, options)
      end

      @rt1 = create_request_template(name: 'Request Template 1', request: @request1)
      @rt2 = create_request_template(name: 'Request Template 2', request: @request2)
      @rt2.archive
      @rt2.reload

      @active = [@rt1]
      @inactive = [@rt2]
    end

    after(:all) do
      RequestTemplate.delete_all
      Request.delete([@request1, @request2])
      User.delete(@user)
      App.delete([@app1, @app2])
      Environment.delete([@env1, @env2])
    end

    it_behaves_like 'active/inactive filter' do

      describe 'filter by name, app_id and environment_id' do
        subject { described_class.filtered(name: @rt1.name, app_id: @app1.id, environment_id: @env1.id) }
        it { should match_array([@rt1]) }
      end

      describe 'filter(inactive) by name, app_id and environment_id' do
        subject { described_class.filtered(archived: true, name: @rt2.name, app_id: @app2.id, environment_id: @env2.id) }
        it { should match_array([@rt2]) }
      end
    end
  end

  describe '#application_environments' do
    context 'when request is present' do
      it 'returns request application_environments' do
        request = double('Request')
        request_template = RequestTemplate.new
        allow(request_template).to receive(:request).and_return(request)

        expect(request).to receive(:application_environments)

        request_template.application_environments
      end
    end

    context 'when request is nil' do
      it 'returns all application_environments' do
        request_template = RequestTemplate.new
        allow(request_template).to receive(:request)

        expect(ApplicationEnvironment).to receive(:all)

        request_template.application_environments
      end
    end
  end

  describe '.templates_for' do
    let!(:app) { create :app, :with_installed_component }
    let(:environment) { app.environments.first }
    let!(:team) { create(:team, groups: user.groups, apps: [app]) }
    let!(:request) { create(:request, apps: [app], environment: environment) }
    let!(:request_template) { create(:request_template, request: request) }
    let!(:restricted_request) { create(:request_with_app, name: 'Restricted Request') }
    let!(:restricted_request_template) { create(:request_template, request: restricted_request) }
    let!(:user) { create(:user, :with_role_and_group ) }

    before { team.update_apps_users }

    it 'returns filtered request template' do
      expect(RequestTemplate.templates_for(user, app.id)).to include(request_template)
      expect(RequestTemplate.templates_for(user, app.id)).not_to include(restricted_request_template)
    end
  end


end
