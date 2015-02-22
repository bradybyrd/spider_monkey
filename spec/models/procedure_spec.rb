require 'spec_helper'


describe Procedure do

  context '' do
    before(:each) do
      @procedure = create(:procedure)
    end

    let(:Procedure_with_StepContainer) {
      Procedure.new do
        include Procedure::StepContainer
      end
    }

    let(:Procedure_with_ArchivableModelHelpers) {
      Procedure.new do
        include Procedure::ArchivableModelHelpers
      end
    }

    describe "associations" do
      it { should have_many(:steps) }
      it { should have_and_belong_to_many(:apps) }
    end

    describe "validations" do
      it { should validate_presence_of(:name) }
    end

    describe "named scopes" do
      it { Procedure.should respond_to(:filter_by_name)}
      it { Procedure.should respond_to(:with_app_id)}
    end
  end

  describe '#filtered' do

    before(:all) do

      Procedure.delete_all
      User.current_user = create(:old_user)
      @app = create(:app)
      @env = create(:environment)
      AssignedEnvironment.create!(:environment_id => @env.id, :assigned_app_id => @app.assigned_apps.first.id, :role => User.current_user.roles.first)
      @app2 = create(:app)
      @package1 = create_package()
      @app2.package_ids = [@package1.id]
      @app2.save

      @proc1 = create_procedure(:apps => [@app])
      @proc2 = create_procedure(:name => 'Test procedure 1')
      @proc3 = create_procedure(:apps => [@app], :name => 'Test procedure 2')
      @proc4 = create_procedure(:apps => [@app], :name => 'Test procedure 3')
      @proc4.archive
      @proc4.reload
      @proc5 = create_procedure(:apps => [@app2], :name => 'Test procedure 5')
      @active = [@proc1, @proc2, @proc3,@proc5]
      @inactive = [@proc4]
    end

    after(:all) do
      Procedure.delete_all
      App.delete(@app)
    end

    it_behaves_like 'active/inactive filter' do

      it 'cumulative filter by app_id' do
        result = described_class.filtered(:app_id => @app.id)
        result.should match_array([@proc1, @proc3])
      end

      it 'empty cumulative filter active by default' do
        result = described_class.filtered(:name => @proc4.name)
        result.should be_empty
      end

      it 'cumulative filter inactive' do
        result = described_class.filtered(:archived => true, :name => @proc4.name)
        result.should match_array([@proc4])
      end
    end

    describe "support packages" do
      it 'has available_package_ids with not packages' do
        @proc1.available_package_ids.should match_array([])
      end

      it 'has available_package_ids with packages' do
        @proc5.available_package_ids.should match_array([@package1.id])
      end

      it 'has_no_available_package_templates' do
        @proc5.has_no_available_package_templates?.should be_truthy
      end

    end


  end

  protected

  def create_procedure(options = nil)
    create(:procedure, options)
  end

  def create_package(options = nil)
    create(:package, options)
  end

end