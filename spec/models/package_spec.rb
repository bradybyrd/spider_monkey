require 'spec_helper'

describe Package do

  context '' do
    before(:each) do
      User.current_user = User.find_by_login("admin")
      @business_package = Package.new
      @comp1 = create(:package)
    end

    describe "validations" do
      it { @comp1.should validate_presence_of(:name) }
      it { @comp1.should validate_uniqueness_of(:name)}
      it { @comp1.should validate_presence_of(:next_instance_number) }
      it { @comp1.should validate_presence_of(:instance_name_format) }
      it { @comp1.should validate_numericality_of(:next_instance_number) }
    end

    describe "attribute normalizations" do
      it { should normalize_attribute(:name).from('  Hello  ').to('Hello') }
    end


    describe "associations" do
      it "should have many" do
        @comp1.should have_many(:package_properties)
        @comp1.should have_many(:properties)
      end
    end
  end


  describe '#filtered' do

    before(:all) do

      Package.delete_all
      @app = create(:app, :name => 'Default App')
      @prop = create(:property, :name => 'test_property')

      @comp1 = create_package(:name => 'Package 1')
      @comp2 = create_package(:name => 'Package 2')
      @comp2a = create_package(:name => 'Package 2a', :active => false)
      @comp3 = create_package(:name => 'Package 3', :properties => [@prop])
      @comp3a = create_package(:name => 'Package 3a', :properties => [@prop], :active => false)
      @comp4 = create_package(:name => 'Package 4', :properties => [@prop])
      @comp4a = create_package(:name => 'Package 4a', :properties => [@prop], :active => false)

      @active = [@comp1, @comp2, @comp3, @comp4]
      @inactive = [@comp2a, @comp3a, @comp4a]
    end

    after(:all) do
      Package.delete_all
      App.delete(@app)
      Property.delete(@prop)
    end

    it_behaves_like 'active/inactive filter' do
      describe 'filter by name' do
        subject { described_class.filtered(:name => 'Package 1') }
        it { should match_array([@comp1]) }
      end

      describe 'filter by property_name' do
        subject { described_class.filtered(:property_name => @prop.name) }
        it { should match_array([@comp3, @comp4]) }
      end

      describe 'filter by name (inactive is not specified)' do
        subject { described_class.filtered(:name => 'Package 4a') }
        it { should be_empty }
      end

      describe 'filter by name (inactive is specified)' do
        subject { described_class.filtered(:name => 'Package 4a', :inactive => true) }
        it { should match_array([@comp4a]) }
      end
    end
  end

  describe '#deactivate!' do
    context 'when not destroyable' do
      let(:package) { stub_model Package, destroyable?: false }

      it 'returns false' do
        expect(package.deactivate!).to eq false
      end

      it 'has validation error messages' do
        package.deactivate!
        expect(package.errors.full_messages).to include I18n.t('package.errors.inactivate_condition')
      end
    end

    context 'when destroyable' do
      let(:package) { stub_model Package, destroyable?: true }

      it 'makes it inactive' do
        package.deactivate!
        expect(package).not_to be_active
      end
    end

  end

  protected

  def create_package(options = nil)
    create(:package, options)
  end

end

