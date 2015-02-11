require 'spec_helper'

describe Request do
  context 'filters' do
    context 'by deployment window series' do
      let(:environment){ create(:environment, :closed) }
      let(:series){ create(:recurrent_deployment_window_series, :with_occurrences, environment_ids: [environment.id]) }
      let(:request_with_dws) { create(:request,
                                        deployment_window_event: series.events.first,
                                        scheduled_at: series.start_at,
                                        estimate: (series.finish_at - series.start_at) / 60
                              )}
      let(:request_without_dws) { create(:request) }
      let(:params) { {"deployment_window_series_id"=>["#{series.id}"]} }
      let(:params_with_none) { {"deployment_window_series_id"=>["no_dws"]} }
      let(:mixed_params) { {"deployment_window_series_id"=>["#{series.id}","no_dws"]} }

      describe '.filtered' do
        it 'returns requests without any Deployment Window Series' do
          expect(Request.filtered(params_with_none,true)).to eq [request_without_dws]
        end

        it 'returns requests with specific Deployment Window Series' do
          expect(Request.filtered(params,false)).to eq [request_with_dws]
        end

        it 'returns requests with specific Deployment Window Series and requests without any Deployment Window Series' do
          expect(Request.filtered(mixed_params,false)).to eq [request_with_dws, request_without_dws]
        end
      end

      describe '.relation_with_no_dws' do
        let(:result) { Request.relation_with_no_dws(Request.scoped,["#{series.id}"]) }
        it 'returns concatenation of two scopes' do
          expect(result).to be_a_kind_of ActiveRecord::Relation
        end
      end
    end
  end
end

