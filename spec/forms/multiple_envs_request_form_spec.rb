require 'spec_helper'

describe MultipleEnvsRequestForm do

  describe '#parse_env_ids_from_params' do
    context 'without environment_ids' do
      it 'returns blank array' do
        params = { request: {}}
        expect(MultipleEnvsRequestForm.parse_env_ids_from_params(params)).to eq([])
      end
    end

    context 'with environment_ids' do
      let(:params) { {request: {environment_ids: '1,2', environment_id: '1'}} }

      it 'returns environment_ids array' do
        expect(MultipleEnvsRequestForm.parse_env_ids_from_params(params)).to eq(%w(1 2))
      end

      it 'deletes environment_ids from params and set first id to environment_id' do
        expected_result = { request: { environment_id: '1' } }
        MultipleEnvsRequestForm.parse_env_ids_from_params(params)
        expect(params).to eq(expected_result)
      end
    end
  end

  describe '#create_multiple_requests' do
    it 'creates request for each environment' do
      params = { request: {}}
      request = create(:request)
      request.stub(:clone_request_with_dependencies).and_return(true)
      environment_ids = %w(1 2 3)
      expect(request).to receive(:clone_request_with_dependencies).exactly(2).times
      MultipleEnvsRequestForm.create_multiple_requests(request, environment_ids, params)
    end
  end

  describe '#instantiate_multiple_requests' do
    it 'instantiate request for each environment' do
      params = { request: {}}
      request_template = create(:request_template)
      request_template.stub(:instantiate_request).and_return(true)
      environment_ids = %w(1 2 3)
      expect(request_template).to receive(:instantiate_request).exactly(2).times
      MultipleEnvsRequestForm.instantiate_multiple_requests(request_template, environment_ids, params)
    end
  end

  describe '#no_one_environment?' do
    it 'returns true' do
      req_params = {app_ids: '1', environment_id: ''}
      expect(MultipleEnvsRequestForm.no_one_environment?(req_params, [])).to be_truthy
    end

    it 'returns false' do
      req_params = {app_ids: '1'}
      expect(MultipleEnvsRequestForm.no_one_environment?(req_params, [1])).to be_falsey
    end

    it 'returns false' do
      req_params = {app_ids: '1', environment_id: '1'}
      expect(MultipleEnvsRequestForm.no_one_environment?(req_params, [])).to be_falsey
    end
  end
end