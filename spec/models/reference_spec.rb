require 'spec_helper'

describe Reference do
  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:uri) }
    it { should validate_presence_of(:server_id) }
    it { should validate_presence_of(:package) }
    it { should ensure_inclusion_of(:resource_method).in_array(%w(File)) }
    it { should have_many(:property_values).conditions(deleted_at: nil) }
  end

  describe 'validation of the name uniqueness' do
    let(:name) { 'Per aspera ad astra' }

    it 'raises validation error' do
      p1 = create(:reference, name: name)
      reference_with_name_duplication = build(:reference, name: name, package: p1.package )

      expect(reference_with_name_duplication).not_to be_valid
      expect(reference_with_name_duplication.errors.full_messages).to include 'Name has already been taken'
    end
  end

  describe '#properties_that_can_be_overridden' do
    it 'returns properties from the package that have not been overridden yet' do
      property = create(:property)
      property_to_override = create(:property)
      reference = create_reference_with_properties(property, property_to_override)
      override_property_on_reference(reference, property_to_override)

      expect(reference.properties_that_can_be_overridden).to eq [property]
    end
  end

  describe '#available_servers_for' do
    context 'reference has a server and user does not have access to any servers' do
      it 'returns the server associated with the reference' do
        user = create(:user, :non_root)
        server = create(:server)
        reference = create(:reference, server: server)

        available_servers = reference.available_servers_for(user)

        expect(available_servers).to eq [server]
      end
    end

    context 'reference has no server and user has access to some servers' do
      it 'returns servers that are accessible to the user' do
        user = create(:user, :root)
        server = create(:server)
        reference = build(:reference, server: nil)

        available_servers = reference.available_servers_for(user)

        expect(available_servers).to eq [server]
      end
    end

    context 'reference has a server that a user has access to' do
      it 'returns just one instance of the server' do
        user = create(:user, :root)
        server = create(:server)
        reference = build(:reference, server: server)

        available_servers = reference.available_servers_for(user)

        expect(available_servers).to eq [server]
      end
    end

    context 'user has access to multiple servers' do
      it 'returns all user accessible servers' do
        user = create(:user, :root)
        server = create(:server)
        another_server = create(:server)
        reference = build(:reference, server: server)

        available_servers = reference.available_servers_for(user)

        expect(available_servers).to eq [server, another_server]
      end
    end
  end

  def create_reference_with_properties(*properties)
    package = create(:package, properties: properties)
    reference = create(:reference, package: package)
  end

  def override_property_on_reference(reference, property_to_override)
    property_value = build(:property_value, property: property_to_override)
    property_value.value_holder = reference
    property_value.save
  end
end
