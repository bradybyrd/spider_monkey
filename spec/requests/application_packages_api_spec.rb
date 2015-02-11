require 'spec_helper'

describe '/v1/application_packages' do
  let(:url) do
    api_user = create(:user, :root)
    "/v1/application_packages?token=#{api_user.api_key}"
  end

  describe 'post /v1/application_packages' do
    it 'creates and returns an application package as JSON' do
      app = create(:app)
      property = create(:property)
      package = create(:package, properties: [property])
      application_package_params = {
        app_id: app.id,
        package_id: package.id,
        properties_with_values: { property.name => 'Overridden Value' }
      }

      post url, format: :json, application_package: application_package_params

      expect(response.status).to eq 201
      expect(response_json[:created_at]).to be_present
      expect(response_json[:updated_at]).to be_present
      expect(response_json[:app]).to eq app.as_json(only: [:id, :name])
      expect(response_json[:package]).to eq package.as_json(only: [:id, :name])
      expect(response_json[:property_values].first).
        to include(name: property.name, value: 'Overridden Value')
    end

    it 'creates and returns an application package as XML' do
      app = create(:app)
      property = create(:property)
      package = create(:package, properties: [property])
      application_package_params = {
        app_id: app.id,
        package_id: package.id,
        properties_with_values: { property.name => 'Overridden Value' }
      }

      post url, format: :xml, application_package: application_package_params

      expect(response.status).to eq 201
      application_package = response_xml[:application_package]
      expect(application_package[:created_at]).to be_present
      expect(application_package[:updated_at]).to be_present
      expect(application_package[:app]).to eq app.as_json(only: [:id, :name])
      expect(application_package[:package]).to eq package.as_json(only: [:id, :name])
      expect(application_package[:property_values].first).
        to include(name: property.name, value: 'Overridden Value')
    end

    context 'invalid property value' do
      it 'returns an error stating that the property is invalid' do
        app = create(:app)
        property = create(:property)
        package = create(:package, properties: [property])
        application_package_params = {
          app_id: app.id,
          package_id: package.id,
          properties_with_values: { 'Non-Existent' => 'Overridden Value' }
        }

        post url, format: :json, application_package: application_package_params

        expect(response.status).to eq 422
        expect(response_json[:properties_with_values]).to be_present
      end
    end

    context 'package id does not exist' do
      it 'returns an error stating that the package cannot be blank' do
        app = create(:app)
        non_existent_package_id = 1234
        application_package_params = {
          app_id: app.id,
          package_id: non_existent_package_id,
          properties_with_values: { 'Anything' => 'Value' }
        }

        post url, format: :json, application_package: application_package_params

        expect(response.status).to eq 422
        expect(response_json[:package]).to be_present
      end
    end

    it 'returns errors as JSON' do
      post url, format: :json, application_package: {}

      expect(response.status).to eq 422
      expect(response_json[:app]).to be_present
    end

    it 'returns errors as XML' do
      post url, format: :xml, application_package: {}

      expect(response.status).to eq 422
      expect(response_xml[:errors]).to be_present
    end
  end

  describe 'put /v1/application_packages' do
    context 'the application package exists' do
      it 'updates the property values of the application package from JSON' do
        property = create(:property)
        package = create(:package, properties: [property])
        application_package = create(:application_package, package: package)
        application_package_params = {
          app_id: application_package.app.id,
          package_id: package.id,
          properties_with_values: { property.name => 'Overridden Value' }
        }

        put url, format: :json, application_package: application_package_params

        expect(response.status).to eq 202
        expect(response_json[:property_values].size).to eq 1
        expect(response_json[:property_values].first).
          to include(name: property.name, value: 'Overridden Value')
      end

      it 'updates the property values of the application package from XML' do
        property = create(:property)
        package = create(:package, properties: [property])
        application_package = create(:application_package, package: package)
        application_package_params = {
          app_id: application_package.app.id,
          package_id: package.id,
          properties_with_values: { property.name => 'Overridden Value' }
        }

        put url, format: :xml, application_package: application_package_params

        expect(response.status).to eq 202
        application_package = response_xml[:application_package]
        expect(application_package[:property_values].size).to eq 1
        expect(application_package[:property_values].first).
          to include(name: property.name, value: 'Overridden Value')
      end
    end

    context 'the application package does not exist' do
      it 'returns a 404 status code in JSON format' do
        id_of_non_existent_record = 1
        application_package_params = {
          app_id: id_of_non_existent_record,
          package_id: id_of_non_existent_record
        }

        put url, format: :json, application_package: application_package_params

        expect(response.status).to eq 404
      end

      it 'returns a 404 status code in XML format' do
        id_of_non_existent_record = 1
        application_package_params = {
          app_id: id_of_non_existent_record,
          package_id: id_of_non_existent_record
        }

        put url, format: :xml, application_package: application_package_params

        expect(response.status).to eq 404
      end
    end
  end

  describe 'delete /v1/application_packages' do
    tested_formats.each do |format|
      it "deletes the record with app_id and package_id in #{format}" do
        application_package = create(:application_package)
        application_package_params = {
          app_id: application_package.app_id,
          package_id: application_package.package_id
        }

        delete url, format: format, application_package: application_package_params

        expect(response.status).to eq 202
        expect(ApplicationPackage.count).to eq 0
      end

      it 'returns a 404 status code if record does not exist' do
        id_of_non_existent_record = 1
        application_package_params = {
          app_id: id_of_non_existent_record,
          package_id: id_of_non_existent_record
        }

        delete url, format: format, application_package: application_package_params

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
