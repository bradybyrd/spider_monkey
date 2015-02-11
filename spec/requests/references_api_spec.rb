require 'spec_helper'

describe '/v1/references' do
  let(:api_token) { create(:user, :root).api_key }

  describe 'post /v1/references' do
    it 'creates and returns a reference as JSON' do
      server = create(:server)
      package = create(:package)
      reference_params = {
        server_id: server.id,
        package_id: package.id,
        name: 'My Reference',
        uri: 'My URI'
      }

      post v1_references_path(token: api_token),
        format: :json,
        reference: reference_params

      expect(response.status).to eq 201
      expect(response_json[:created_at]).to be_present
      expect(response_json[:updated_at]).to be_present
      expect(response_json[:name]).to eq 'My Reference'
      expect(response_json[:uri]).to eq 'My URI'
      expect(response_json[:server_id]).to eq server.id
      expect(response_json[:package_id]).to eq package.id
    end

    it 'creates and returns a reference as XML' do
      server = create(:server)
      package = create(:package)
      reference_params = {
        server_id: server.id,
        package_id: package.id,
        name: 'My Reference',
        uri: 'My URI'
      }

      post v1_references_path(token: api_token),
        format: :xml,
        reference: reference_params

      expect(response.status).to eq 201
      reference_xml = response_xml[:reference]
      expect(reference_xml[:created_at]).to be_present
      expect(reference_xml[:updated_at]).to be_present
      expect(reference_xml[:name]).to eq 'My Reference'
      expect(reference_xml[:uri]).to eq 'My URI'
      expect(reference_xml[:server_id]).to eq server.id
      expect(reference_xml[:package_id]).to eq package.id
    end

    it 'returns errors as JSON' do
      post v1_references_path(token: api_token), format: :json, reference: {}

      expect(response.status).to eq 422
      expect(response_json[:name]).to be_present
      expect(response_json[:uri]).to be_present
      expect(response_json[:server_id]).to be_present
      expect(response_json[:package]).to be_present
    end

    it 'returns errors as XML' do
      post v1_references_path(token: api_token), format: :xml, reference: {}

      expect(response.status).to eq 422
      expect(response_xml[:errors]).to be_present
    end
  end

  describe 'put /v1/references' do
    context 'the reference exists' do
      it 'updates the property values of the application package from JSON' do
        property = create(:property)
        package = create(:package, properties: [property])
        reference = create(:reference, package: package)
        reference_params = {
          properties_with_values: { property.name => 'Overridden Value' }
        }

        put v1_reference_path(reference, token: api_token),
          format: :json,
          reference: reference_params

        expect(response.status).to eq 202
        expect(response_json[:property_values].size).to eq 1
        expect(response_json[:property_values].first).
          to include(name: property.name, value: 'Overridden Value')
      end

      it 'does not allow package id to be changed' do
        property = create(:property)
        package = create(:package, properties: [property])
        reference = create(:reference, package: package)

        package2 = create(:package, properties: [property])

        reference_params = {
          package_id: package2.id
        }

        put v1_reference_path(reference, token: api_token),
            format: :json,
            reference: reference_params

        expect(response.status).to eq 422
        expect(response.body).to include( I18n.t('package.errors.package_id_change_not_allowed') )
      end

      it 'updates the property values of the application package from XML' do
        property = create(:property)
        package = create(:package, properties: [property])
        reference = create(:reference, package: package)
        reference_params = {
          properties_with_values: { property.name => 'Overridden Value' }
        }

        put v1_reference_path(reference, token: api_token),
          format: :xml,
          reference: reference_params

        expect(response.status).to eq 202
        reference_xml = response_xml[:reference]
        expect(reference_xml[:property_values].size).to eq 1
        expect(reference_xml[:property_values].first).
          to include(name: property.name, value: 'Overridden Value')
      end
    end
  end

  describe 'delete /v1/references' do
    tested_formats.each do |format|
      it "deletes the record with reference_id in #{format}" do
        reference = create(:reference)

        delete v1_reference_path(reference, token: api_token), format: format

        expect(response.status).to eq 202
        expect(Reference.count).to eq 0
      end

      it 'returns a 404 status code if record does not exist' do
        id_of_non_existent_record = 1

        delete v1_reference_path(id_of_non_existent_record, token: api_token),
          format: format

        expect(response.status).to eq 404
      end
    end
  end

  def response_json
    @response_json ||= JSON.parse(response.body).with_indifferent_access
  end

  def response_xml
    @response_xml ||= Hash.from_xml(response.body).with_indifferent_access
  end
end

