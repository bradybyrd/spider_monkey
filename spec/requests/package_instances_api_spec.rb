require 'spec_helper'

base_url =  '/v1/package_instances'

describe "request for #{base_url}" do
  let(:base_url)  { base_url }

  before :all do
    user = create(:user, :root)
    @token = user.api_key
  end

  describe "GET #{base_url}" do
    before(:each) do
      default_server = create(:server)
      @package = create(:package)
      @package_instance = create(:package_instance, package: @package, active: true, name: 'test')
      @reference = create(:reference, name: 'test', server: default_server, package: @package)
      @instance_reference = create(:instance_reference, server: default_server, package_instance: @package_instance, reference: @reference)
    end

    context 'JSON' do
      let(:url) { "#{base_url}?token=#{@token}" }
      let(:json_root) { 'array:root > object' }

      it 'package instance should include the reference' do
        jget
        body = JSON.parse(response.body)
        expect(body.size).to eq(1)
        pi0 = body[0]
        expect(pi0["name"]).to eql(@package_instance.name)
        expect(pi0["instance_references"].size).to eq(1)
        ref0 = pi0["instance_references"][0]
        expect(ref0["id"]).to eql(@instance_reference.id)
      end

      it 'find package instance by name' do
        param = {filters: {name: @package_instance.name}}
        jget param
        body = JSON.parse(response.body)
        expect(body.size).to eq(1)
        pi0 = body[0]
        expect(pi0["name"]).to eql(@package_instance.name)
      end

      it 'find package instance by name with no match' do
        param = {:filters => {name: @package_instance.name + "X"}}
        jget param
        expect(response.status).to eq 404
      end

      it 'find package instance by name and active' do
        param = {filters: {name: @package_instance.name, active: true}}
        jget param
        body = JSON.parse(response.body)
        expect(body.size).to eq(1)
        pi0 = body[0]
        expect(pi0["name"]).to eql(@package_instance.name)
      end

      it 'find package instance by name and inactive' do
        @package_instance.active = false
        @package_instance.save!
        param = {filters: {name: @package_instance.name, inactive: true}}
        jget param
        body = JSON.parse(response.body)
        expect(body.size).to eq(1)
        package_instance = body[0]
        expect(package_instance["name"]).to eql(@package_instance.name)
      end

      it 'find package instance by name and inactive with no inactive instances' do
        param = {filters: {name: @package_instance.name, inactive: true}}
        jget param
        expect(response.status).to eq 404
      end

      it 'find package instance by name and active with no active instances' do
        @package_instance.active = false
        @package_instance.save!
        param = {filters: {name: @package_instance.name, active: true}}
        jget param
        expect(response.status).to eq 404
      end
    end
  end

  # Creates a new phase from posted data
  describe "POST #{base_url} with JSON mimetype" do
    before(:each) do
      default_server = create(:server)
      @package = create(:package)
      @reference = create(:reference, server: default_server, package: @package )
    end

    let(:url) { "#{base_url}?token=#{@token}" }

    context 'with valid params' do
      let(:params)  { { package_instance: { name: 'instance_name', package_name: @package.name  }}.to_json }
      it 'returns the successful code' do
        jpost params
        expect(response.status).to eq 201
        expect(response.body).to match('instance_name')
      end
    end

    context 'with valid params and reference' do
      let(:params)  { { package_instance: { name: 'instance_name', package_name: @package.name, reference_ids: [@reference.id]  }}.to_json }
      it 'returns the successful code' do
        jpost params
        expect(response.status).to eq 201
        expect(response.body).to match('instance_name')
        expect(response.body).to match('instance_references')
        expect(response.body).to match(@reference.name)
      end
    end

    context 'with no package name DE90855' do
      let(:params)  { { package_instance: { name: 'instance2_name' }}.to_json }
      it 'fails to create' do
        jpost params
        expect(response.status).to eq 422
        expect(response.body).to match('can\'t be blank')
      end
    end

    context 'with package not found' do
      let(:params)  { { package_instance: { name: 'instance3_name', package_name: @package.name + "_x" }}.to_json }
      it 'fails to create' do
        jpost params
        expect(response.status).to eq 422
        expect(response.body).to match('can\'t be blank')
        expect(response.body).to match(I18n.t('package_instance.package_not_found'))
      end
    end

    context 'with package not supplied' do
      let(:params)  { { package_instance: { name: 'instance3_name' } }.to_json }
      it 'fails to create' do
        jpost params
        expect(response.status).to eq 422
        expect(response.body).to match( I18n.t('package_instance.package_blank') )
      end
    end
  end

  describe "PUT #{base_url}/[id] with JSON mimetype" do
    before(:each) do
      default_server = create(:server)
      @package = create(:package)
      @reference1 = create(:reference, server: default_server, package: @package, name: 'reference1 name' )
      @reference2 = create(:reference, server: default_server, package: @package, name: 'reference2 name' )
      @package_instance = create(:package_instance, package: @package )
      @instance_reference = create(:instance_reference, package_instance: @package_instance, reference: @reference1, name: @reference1.name )
    end

    context "tries to change package" do
      let(:url) { "#{base_url}/#{@package_instance.id}?token=#{@token}" }
      let(:new_package) { create(:package) }
      let(:params)  { { package_instance: { package_name: new_package.name }}.to_json }
      it 'does not allow package to be changed' do
        jput params
        expect(response.status).to eq 422
        expect(response.body).to include( I18n.t('package_instance.package_change_not_allowed'))
      end
    end

    context "change name of instance" do
      let(:url) { "#{base_url}/#{@package_instance.id}?token=#{@token}" }
      let(:params)  { { package_instance: { name: "changed name" }}.to_json }
      it 'name is changed' do
        jput params
        expect(response.status).to eq 202
        expect(response.body).to match('changed name')
        expect(response.body).to match(@reference1.name)
        expect(response.body).not_to match(@reference2.name)
      end
    end

    context "add another reference" do
      let(:url) { "#{base_url}/#{@package_instance.id}?token=#{@token}" }
      let(:params)  { { package_instance: { reference_ids: [@reference1.id, @reference2.id] }}.to_json }
      it 'instance has 2 references' do
        jput params
        expect(response.status).to eq 202
        expect(response.body).to match(@reference1.name)
        expect(response.body).to match(@reference2.name)
      end
    end

    context "remove reference" do
      let(:url) { "#{base_url}/#{@package_instance.id}?token=#{@token}" }
      let(:params)  { { package_instance: { reference_ids: [ ] }}.to_json }
      it 'instance has no references' do
        jput params
        expect(response.status).to eq 202
        expect(response.body).not_to match(@reference1.name)
        expect(response.body).not_to match(@reference2.name)
      end
    end

    context "add and remove reference" do
      let(:url) { "#{base_url}/#{@package_instance.id}?token=#{@token}" }
      let(:params)  { { package_instance: { reference_ids: [@reference2.id] }}.to_json }
      it 'instance has 1 references' do
        jput params
        expect(response.status).to eq 202
        expect(response.body).not_to match(@reference1.name)
        expect(response.body).to match(@reference2.name)
      end
    end
  end

end


