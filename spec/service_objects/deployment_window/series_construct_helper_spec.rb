require 'spec_helper'

describe DeploymentWindow::SeriesConstructHelper do

  describe '.prepare_environment_ids' do
    let(:params) { { deployment_window_series: {environment_ids: '[1, 2, 4]'} }  }
    let(:empty_params) { { deployment_window_series: {environment_ids: '[]'} }  }

    it 'returns array' do
      modified_params = DeploymentWindow::SeriesConstructHelper.prepare_environment_ids(params)
      expect(modified_params[:deployment_window_series][:environment_ids]).to eq([1,2,4])
    end

    it 'returns empty array' do
      modified_params = DeploymentWindow::SeriesConstructHelper.prepare_environment_ids(empty_params)
      expect(modified_params[:deployment_window_series][:environment_ids]).to eq([])
    end
  end

  describe '.prepare_schedule' do
    let(:params) { { deployment_window_series: {frequency: 'null'} }  }
    let(:params_without_frequency) { { deployment_window_series: {} }  }

    context 'when frequency is null' do
      it 'converts frequency to nil' do
        modified_params = DeploymentWindow::SeriesConstructHelper.prepare_schedule(params)
        expect(modified_params[:deployment_window_series][:frequency]).to be_nil
      end
    end

    context 'when frequency is not present' do
      it 'returns unmodified params' do
        modified_params = DeploymentWindow::SeriesConstructHelper.prepare_schedule(params_without_frequency)
        expect(modified_params).to eq(params_without_frequency)
      end
    end
  end

  describe '.prepare_duration' do
    let(:params) { { deployment_window_series: {duration_in_days: '1'} }  }

    it 'converts duration to integer' do
      modified_params = DeploymentWindow::SeriesConstructHelper.prepare_duration(params)
      expect(modified_params[:deployment_window_series][:duration_in_days]).to eq(1)
    end
  end

  describe '.prepare_dates' do
    let(:params) { { deployment_window_series: {
                        "start_at"      => "02/18/2014",
                        "start_at(4i)"  => "04",
                        "start_at(5i)"  => "27",
                        "finish_at"     => "02/27/2014",
                        "finish_at(4i)" => "05",
                        "finish_at(5i)" => "27"
                      }
                  } }

    it 'returns modified date params' do
      params_copy = params.dup.deep_symbolize_keys
      modified_params = DeploymentWindow::SeriesConstructHelper.prepare_dates(params_copy)
      expect(modified_params[:deployment_window_series]).to include(:"start_at(1i)", :"start_at(2i)", :"start_at(3i)", :"finish_at(1i)", :"finish_at(2i)", :"finish_at(2i)")
    end
  end

  describe '.prepare_params' do
    let(:params) { { deployment_window_series: {
                  name: 'Ubik',
                  behavior: 'prevent',
                  start_at: '01/01/3000',
                  "start_at(4i)"  => "04",
                  "start_at(5i)"  => "27",
                  finish_at: '02/01/3000',
                  "finish_at(4i)" => "05",
                  "finish_at(5i)" => "27",
                  recurrent: 'true',
                  frequency: 'null',
                  duration_in_days: '1',
                  environment_ids: '[1,2,3]'
                }
              } }

    context 'when series - recurrent' do
      it 'prepares duration params' do
        DeploymentWindow::SeriesConstructHelper.should_receive(:prepare_duration)
        DeploymentWindow::SeriesConstructHelper.prepare_params(params)
      end
    end

  end
end
