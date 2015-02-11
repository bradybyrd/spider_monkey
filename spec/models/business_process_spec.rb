
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe BusinessProcess do

  context '' do
    before(:each) do
      @business_process = BusinessProcess.new
    end

    let(:BusinessProcess_with_ArchivableModelHelpers) {
      BusinessProcess.new do
        include BusinessProcess::ArchivableModelHelpers
      end
    }

    it "should have many" do
      @business_process.should have_many(:requests)
      @business_process.should have_many(:apps_business_processes)
      @business_process.should have_many(:apps)
    end

    describe "validations" do
      before(:each) { create(:business_process) }
      it { @business_process.should validate_presence_of(:name) }
      it { @business_process.should validate_presence_of(:label_color) }
      it { @business_process.should validate_presence_of(:app_ids) }
      it { @business_process.should validate_uniqueness_of(:name) }
    end

    it "should have the scopes" do
      BusinessProcess.should respond_to(:name_order)
      BusinessProcess.should respond_to(:filter_by_name)
    end

    it "should have hashed constants" do
      BusinessProcess::ColorCodes.should be_a Hash
      BusinessProcess::HUMANIZED_ATTRIBUTES.should be_a Hash
    end
  end

  describe '#filtered' do

    before(:all) do
      BusinessProcess.delete_all
      User.current_user = create(:old_user)
      @bp1 = create_business_process()
      @bp2 = create_business_process(:name => 'Inactive Business Process')
      @bp2.archive
      @bp2.reload
      @bp3 = create_business_process(:name => 'Default Business Process')
      @active = [@bp1, @bp3]
      @inactive = [@bp2]
    end

    after(:all) do
      BusinessProcess.delete_all
    end

    it_behaves_like 'active/inactive filter' do

      it 'cumulative filter active by default' do
        result = described_class.filtered(:name => 'Default Business Process')
        result.should match_array([@bp3])
      end

      it 'empty cumulative filter active by default' do
        result = described_class.filtered(:name => @bp2.name)
        result.should be_empty
      end

      it 'cumulative filter inactive' do
        result = described_class.filtered(:archived => true, :name => @bp2.name)
        result.should match_array([@bp2])
      end
    end

  end

  protected

  def create_business_process(options = nil)
    create(:business_process, options)
  end

end