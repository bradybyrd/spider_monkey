require 'spec_helper'

base_url =  '/v1/packages'

describe "request for #{base_url}" do
  let(:base_url)  { base_url }

  before :all do
    group         = create(:group, root: true)
    user          = create(:user, groups: [group])
    @token        = user.api_key
  end

  #name - string value of the component name
  #app_name - string value of the application name associated with a component
  #property_name - string value of a property name associated with a component
  describe "GET #{base_url}" do
    let(:url)     { "#{base_url}?token=#{@token}" }
    before(:each) do
      @app_1         = create(:app, name: 'AHNE')
      @app_2         = create(:app)
      @property_1    = create(:property, name: 'prettyproperty')
      @property_2    = create(:property)

      @package_1 = create(:package, name: 'gugl name', applications: [@app_1], properties: [@property_1])
      @package_2 = create(:package, name: 'cool name', applications: [@app_1])
      @package_3 = create(:package, properties: [@property_1], active: false)
      @package_4 = create(:package, name: 'mad name', active: false)

      @active_package_ids = [@package_1.id, @package_2.id]
    end

    context 'get packages' do
      let(:json_root) { 'array:root > object' }
      subject { response.body }
      it 'should return all packages except inactive' do
        jget
        should have_json("#{json_root} > number.id").with_values(@active_package_ids)
      end

      it 'should return packages by name' do
        param   = {filters: {name: 'cool name'}}
        jget param
        should have_json("#{json_root} > number.id").with_value(@package_2.id)
      end

      it 'should return packages by app_name' do
        param   = {filters: {app_name: 'AHNE'}}
        jget param
        should have_json("#{json_root} > number.id").with_values(@active_package_ids)
      end

      it 'should return packages by property_name' do
        param   = {filters: {property_name: 'prettyproperty'}}
        jget param
        should have_json("#{json_root} > number.id").with_value(@package_1.id)
      end

      it 'should return packages by app_name and property_name' do
        param   = {filters: {app_name: 'AHNE', property_name: 'prettyproperty'}}
        jget param
        should have_json("#{json_root} > number.id").with_value(@package_1.id)
      end

      it 'should return packages by name and app_name' do
        param   = {filters: {name: 'cool name', app_name: 'AHNE'}}
        jget param
        should have_json('number.id').with_value(@package_2.id)
      end

      it 'should return packages by name and property_name' do
        param   = {filters: {name: 'gugl name', property_name: 'prettyproperty'}}
        jget param
        should have_json('number.id').with_value(@package_1.id)
      end

      it 'should return packages by name and app_name, and property_name' do
        param   = {filters: {name: 'gugl name', app_name: 'AHNE', property_name: 'prettyproperty'}}
        jget param
        should have_json('number.id').with_value(@package_1.id)
      end

      it 'should not return inactive packages type by name' do
        param   = {filters: {name: 'mad name'}}
        jget param
        should == " "
      end

      it 'should return inactive packages type by name if it is specified' do
        param   = {filters: {name: 'mad name', inactive: true}}
        jget param
        should have_json('number.id').with_value(@package_4.id)
      end
    end

  end


  describe "PUT #{base_url}/[id] with JSON mimetype" do
    let(:url)     { "#{base_url}/#{package.id}?token=#{@token}" }
    let(:new_name){ 'Look, it is a very attractive new name'}

    context 'with valid params' do
      let(:params)  { { package: { name: new_name }}.to_json }
      let(:package) { create :package }

      it 'returns the successful code' do
        jput params
        expect(response.status).to eq 202
      end

      it 'updates the name' do
        jput params
        expect(package.reload.name).to eq new_name
      end
    end

    context 'with not valid params' do
      let(:params)  { { package: { name: '' }}.to_json }
      let(:package) { create :package }

      it 'returns the error code' do
        jput params
        expect(response.status).to eq 422
      end

      it 'does not update the entity' do
        jput params
        expect(package).not_to be_changed
      end
    end

  end

  describe "DELETE #{base_url}/[id] with JSON mimetype" do
    let(:url)     { "#{base_url}/#{package.id}?token=#{@token}" }
    let(:params)  { { id: package.id }.to_json }
    let(:package) { create :package }

    context 'when is not destroyable' do
      before { Package.any_instance.stub(:destroyable?).and_return { false } }

      it 'return error code' do
        delete url, params, json_headers
        expect(response.status).to eq 412
      end

      it 'contains error message in the response' do
        delete url, params, json_headers
        expect(response.body).to match I18n.t('package.errors.inactivate_condition')
      end
    end

    context 'when is destroyable' do
      before { Package.any_instance.stub(:destroyable?).and_return { true } }

      it 'return the successful code' do
        delete url, params, json_headers
        expect(response.status).to eq 202
      end

      it 'returns at least ID in the response' do
        delete url, params, json_headers
        expect(response.body).to match "#{package.id}"
      end
    end

  end

end
