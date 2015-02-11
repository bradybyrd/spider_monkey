require 'spec_helper'

describe 'v1/deployment_window/series' do
  before :all do
    @user = create(:user)
    User.current_user = @user
    @token        = @user.api_key
  end

  let(:base_url) { '/v1/deployment_window/series' }
  let(:json_root) { :deployment_window_series }
  let(:xml_root) { 'deployment_window_series' }
  let(:params) { {token: @user.api_key} }

  subject       { response.body }
  before { DeploymentWindow::SeriesBackgroundable.stub(:background).and_return(DeploymentWindow::SeriesBackgroundable) }

  describe 'GET /v1/deployment_window/series' do
    let(:url) { base_url }

    context 'without filters' do
      let!(:deployment_window_series) { create(:deployment_window_series) }
      let!(:other_deployment_window_series) { create(:deployment_window_series) }
      let(:ids) { DeploymentWindow::Series.pluck(:id) }
      let(:names) { DeploymentWindow::Series.pluck(:name) }
      let(:behaviors) { DeploymentWindow::Series.pluck(:behavior) }
      let(:durations_in_days) { DeploymentWindow::Series.pluck(:duration_in_days) }

      it_behaves_like 'successful request', type: :json do
        it { should have_json('.id').with_values(ids) }
        it { should have_json('.name').with_values(names) }
        it { should have_json('.behavior').with_values(behaviors) }
        it { should have_json('.duration_in_days').with_values(durations_in_days) }
        it { should have_json('.start_at') }
        it { should have_json('.finish_at') }
        it { should_not have_json('array.requests') }
      end

      it_behaves_like 'successful request', type: :xml do
        it { should have_xpath('/series-collection/series-item/id').with_texts(ids) }
        it { should have_xpath('/series-collection/series-item/name').with_texts(names) }
        it { should have_xpath('/series-collection/series-item/behavior').with_texts(behaviors) }
        it { should have_xpath('/series-collection/series-item/duration-in-days').with_texts(durations_in_days) }
        it { should have_xpath('/series-collection/series-item/start-at') }
        it { should have_xpath('/series-collection/series-item/finish-at') }
        it { should_not have_xpath('/series-collection/series-item/requests') }
      end
    end

    context 'with filter' do
      let(:url)   { "#{base_url}?token=#{@token}" }
      let(:name)  { 'duckduckgo' }
      let(:start_at) { Time.zone.now + 1.day }
      let(:finish_at) { Time.zone.now + 2.day }
      let(:environment) { create :environment, :closed }
      let!(:dws_archived) { create(:deployment_window_series).archive }

      describe 'by name' do
        let!(:dws_filtered) { create(:deployment_window_series, name: name) }
        let!(:dws_other) { create(:deployment_window_series) }
        let(:params) { { filters: { name: name } } }

        it_behaves_like 'successful request', type: :json do
          it { should have_json('.id').with_value(dws_filtered.id) }
          it { should have_json('.name').with_value(dws_filtered.name) }
        end

        it_behaves_like 'successful request', type: :xml do
          it { should have_xpath('/series-collection/series-item/id').with_text(dws_filtered.id) }
          it { should have_xpath('/series-collection/series-item/name').with_text(dws_filtered.name) }
        end
      end

      describe 'by behavior' do
        let!(:dws_filtered_allow)   { create(:deployment_window_series, behavior: DeploymentWindow::Series::ALLOW) }
        let!(:dws_filtered_prevent) { create(:deployment_window_series, behavior: DeploymentWindow::Series::PREVENT) }
        let(:params) { { filters: { behavior: DeploymentWindow::Series::ALLOW } } }

        it_behaves_like 'successful request', type: :json do
          it { should have_json('.id').with_value(dws_filtered_allow.id) }
          it { should have_json('.behavior').with_value(dws_filtered_allow.behavior) }
        end

        it_behaves_like 'successful request', type: :xml do
          it { should have_xpath('/series-collection/series-item/id').with_text(dws_filtered_allow.id) }
          it { should have_xpath('/series-collection/series-item/behavior').with_text(dws_filtered_allow.behavior) }
        end
      end

      describe 'by start_after' do
        let!(:dws_filtered)   { create(:deployment_window_series, start_at: start_at ) }
        let(:params) { { filters: { start_after: (start_at - 1.minute).to_s(:db) } } }

        it_behaves_like 'successful request', type: :json do
          it { should have_json('.id').with_value(dws_filtered.id) }
        end

        it_behaves_like 'successful request', type: :xml do
          it { should have_xpath('/series-collection/series-item/id').with_text(dws_filtered.id) }
        end
      end

      describe 'by start_before' do
        let!(:dws_filtered)   { create(:deployment_window_series, start_at: start_at ) }
        let(:params) { { filters: { start_before: (start_at + 1.minute).to_s(:db) } } }

        it_behaves_like 'successful request', type: :json do
          it { should have_json('.id').with_value(dws_filtered.id) }
        end

        it_behaves_like 'successful request', type: :xml do
          it { should have_xpath('/series-collection/series-item/id').with_text(dws_filtered.id) }
        end
      end

      describe 'by finish_after' do
        let!(:dws_filtered)   { create(:deployment_window_series, finish_at: finish_at ) }
        let(:params) { { filters: { finish_after: (finish_at - 1.minute).to_s(:db) } } }

        it_behaves_like 'successful request', type: :json do
          it { should have_json('.id').with_value(dws_filtered.id) }
        end

        it_behaves_like 'successful request', type: :xml do
          it { should have_xpath('/series-collection/series-item/id').with_text(dws_filtered.id) }
        end
      end

      describe 'by finish_before' do
        let!(:dws_filtered)   { create(:deployment_window_series, finish_at: finish_at ) }
        let(:params) { { filters: { finish_before: (finish_at + 1.minute).to_s(:db) } } }

        it_behaves_like 'successful request', type: :json do
          it { should have_json('.id').with_value(dws_filtered.id) }
        end

        it_behaves_like 'successful request', type: :xml do
          it { should have_xpath('/series-collection/series-item/id').with_text(dws_filtered.id) }
        end
      end

      describe 'by environment' do
        let!(:dws_filtered)   { create(:deployment_window_series, :with_occurrences, environment_ids: [environment.id] ) }
        let(:params) { { filters: { environment: environment.id } } }

        it_behaves_like 'successful request', type: :json do
          it { should have_json('.id').with_value(dws_filtered.id) }
        end

        it_behaves_like 'successful request', type: :xml do
          it { should have_xpath('/series-collection/series-item/id').with_text(dws_filtered.id) }
        end
      end
    end

  end

  describe 'GET /v1/deployment_window/series/[id]' do
    let!(:deployment_window_series) { create(:deployment_window_series) }
    let(:url) { "#{base_url}/#{deployment_window_series.id}" }

    it_behaves_like "successful request", type: :json do
      it { should have_json('.id').with_value(deployment_window_series.id) }
      it { should have_json('.name').with_value(deployment_window_series.name) }
      it { should have_json('.behavior').with_value(deployment_window_series.behavior) }
      it { should have_json('.duration_in_days').with_value(deployment_window_series.duration_in_days) }
      it { should have_json('.start_at') }
      it { should have_json('.finish_at') }
      it { should have_json('array.requests') }
    end

    it_behaves_like "successful request", type: :xml do
      it { should have_xpath('/series-item/id').with_text(deployment_window_series.id) }
      it { should have_xpath('/series-item/name').with_text(deployment_window_series.name) }
      it { should have_xpath('/series-item/behavior').with_text(deployment_window_series.behavior) }
      it { should have_xpath('/series-item/duration-in-days').with_text(deployment_window_series.duration_in_days) }
      it { should have_xpath('/series-item/start-at') }
      it { should have_xpath('/series-item/finish-at') }
      it { should have_xpath('/series-item/requests') }
    end
  end

  describe 'POST /v1/deployment_window/series' do
    let(:url)           { "#{base_url}?token=#{@user.api_key}" }
    let(:behavior)      { DeploymentWindow::Series::ALLOW }
    let(:environments)  { create_list :environment, 2, :closed }
    let(:added_series)  { DeploymentWindow::Series.where(name: name).first }
    let(:added_events)  { DeploymentWindow::Event.scoped.extending(QueryHelper::WhereIn).where_in('environment_id', environments.map(&:id)) }

    describe 'nonrecurrent' do
      let(:params_base) { {name:            name,
                           behavior:        behavior,
                           environment_ids: environments.map(&:id),
                           start_at:        (Date.today + 1.day).to_s,
                           finish_at:       (Date.today + 2.days).to_s}
      }

      context 'JSON' do
        let(:name)    { 'Hananamiti' }
        let(:params)  { {json_root => params_base}.to_json }
        before { jpost params }

        it { should have_json('.id').with_value(added_series.id) }
        it { should have_json('.name').with_value(name) }
        it { should have_json('.behavior').with_value(behavior) }
        it { should have_json('.duration_in_days').with_value(added_series.duration_in_days) }
        it { should have_json('.start_at') }
        it { should have_json('.finish_at') }
        it { should have_json('array.events number.id').with_values(added_events.map(&:id)) }
      end

      context 'XML' do
        let(:name) { 'WhiteRoses' }
        let(:params) { params_base.to_xml(root: xml_root) }
        before { xpost params }

        it { should have_xpath('/series-item/id').with_text(added_series.id) }
        it { should have_xpath('/series-item/name').with_text(name) }
        it { should have_xpath('/series-item/behavior').with_text(behavior) }
        it { should have_xpath('/series-item/duration-in-days').with_text(added_series.duration_in_days) }
        it { should have_xpath('/series-item/start-at') }
        it { should have_xpath('/series-item/finish-at') }
        it { should have_xpath('/series-item/events/event/id').with_texts(added_events.map(&:id)) }
      end
    end

    describe 'recurrent' do
      let(:params_base) { {name:            name,
                           behavior:        behavior,
                           recurrent:       true,
                           duration_in_days: 1,
                           frequency:       '{"validations":{"day_of_month":[1,18,-1]},"rule_type":"IceCube::MonthlyRule","interval":1}',
                           environment_ids: environments.map(&:id),
                           start_at:        (Date.today + 1.day).to_s,
                           finish_at:       (Date.today + 31.days).to_s}
      }

      context 'JSON' do
        let(:name)    { 'Alohomora' }
        let(:params)  { {json_root => params_base}.to_json }
        before  { jpost params }

        it { should have_json('.id').with_value(added_series.id) }
        it { should have_json('.name').with_value(name) }
        it { should have_json('.behavior').with_value(behavior) }
        it { should have_json('.duration_in_days').with_value(added_series.duration_in_days) }
        it { should have_json('.start_at') }
        it { should have_json('.finish_at') }
        it { should have_json('array.events number.id').with_values(added_events.map(&:id)) }
      end

      context 'XML' do
        let(:name)    { 'Vendetta' }
        let(:params)  { params_base.to_xml(root: xml_root) }
        before  { xpost params }

        it { should have_xpath('/series-item/id').with_text(added_series.id) }
        it { should have_xpath('/series-item/name').with_text(name) }
        it { should have_xpath('/series-item/behavior').with_text(behavior) }
        it { should have_xpath('/series-item/duration-in-days').with_text(added_series.duration_in_days) }
        it { should have_xpath('/series-item/start-at') }
        it { should have_xpath('/series-item/finish-at') }
        it { should have_xpath('/series-item/events/event/id').with_texts(added_events.map(&:id)) }
      end
    end

    it_behaves_like 'creating request with params that fails validation' do
      let(:param) { {name: ''} }
    end

    it_behaves_like 'creating request with invalid params'
  end

  describe 'PUT /v1/deployment_window/series/[id]' do
    let(:url)                       { "#{base_url}/#{deployment_window_series.id}?token=#{@user.api_key}" }
    let(:environment)               { create :environment, :closed }
    let(:behavior)                  { DeploymentWindow::Series::ALLOW }
    let(:updated_series)            { DeploymentWindow::Series.where(name: name).first }
    let(:updated_events)            { DeploymentWindow::Event.scoped.extending(QueryHelper::WhereIn).where_in('environment_id', [environment.id]) }
    let(:deployment_window_series)  { create(:deployment_window_series, :with_occurrences, behavior: behavior) }
    let(:params_base) { {name:            name,
                         environment_ids: [environment.id],
                         start_at:        (Date.today + 1.day).to_s,
                         finish_at:       (Date.today + 2.days).to_s}
    }


    it_behaves_like 'successful request', type: :json, method: :put, status: 202 do
      let(:name) { 'We will, we will' }
      let(:params) { {json_root => params_base}.to_json }

      it { should have_json('.id').with_value(updated_series.id) }
      it { should have_json('.name').with_value(name) }
      it { should have_json('.behavior').with_value(behavior) }
      it { should have_json('.duration_in_days').with_value(updated_series.duration_in_days) }
      it { should have_json('.start_at') }
      it { should have_json('.finish_at') }
      it { should have_json('array.events number.id').with_values(updated_events.map(&:id)) }
    end

    it_behaves_like 'successful request', type: :xml, method: :put, status: 202 do
      let(:name) { 'Rock you' }
      let(:params) { params_base.to_xml(root: xml_root) }

      it { should have_xpath('/series-item/id').with_text(updated_series.id) }
      it { should have_xpath('/series-item/name').with_text(name) }
      it { should have_xpath('/series-item/behavior').with_text(behavior) }
      it { should have_xpath('/series-item/duration-in-days').with_text(updated_series.duration_in_days) }
      it { should have_xpath('/series-item/start-at') }
      it { should have_xpath('/series-item/finish-at') }
      it { should have_xpath('/series-item/events/event/id').with_texts(updated_events.map(&:id)) }
    end

    it_behaves_like 'editing request with params that fails validation' do
      let(:param) { { behavior: 'ignore' } }
    end

    describe 'editing with invalid params' do
      it 'returns error status 202' do
        put url, json_root => { invalid: 'params' }, format: :json

        expect(response.status).to eq 202
      end
    end

    it_behaves_like 'with `toggle_archive` param', custom_entity: DeploymentWindow::Series do
      let(:xml_root) { 'series-item' }
    end

    describe 'prevents update for not editable series' do
      before { DeploymentWindow::Series.any_instance.stub(:editable?).and_return(false) }
      after { response.body.should include I18n.t('deployment_window.not_editable') }

      context 'json' do
        it { put url, json_root => { name: 'TestJson' }, format: :json }
      end
      context 'xml' do
        it { put url, xml_root => { name: 'TestXml' }, format: :xml }
      end
    end

    describe 'able to receive environment ids' do
      let!(:opened_policy_environment) { create(:environment, :opened) }
      let!(:closed_policy_environment) { create(:environment, :closed) }
      let!(:allowed_deployment_window_series) { create(:deployment_window_series, :with_occurrences, behavior: DeploymentWindow::Series::ALLOW) }
      let!(:prevent_deployment_window_series) { create(:deployment_window_series, :with_occurrences, behavior: DeploymentWindow::Series::PREVENT) }

      context 'allowed behavior' do
        let(:url) { "#{base_url}/#{allowed_deployment_window_series.id}?token=#{@user.api_key}" }

        it 'json' do
          params = {json_root => { environment_ids: [closed_policy_environment.id] }}.to_json
          jput params
          allowed_deployment_window_series.reload.environments.map(&:id).should eq [closed_policy_environment.id]
        end

        it 'xml' do
          params = { environment_ids: [closed_policy_environment.id] }.to_xml(root: xml_root)
          xput params
          allowed_deployment_window_series.reload.environments.map(&:id).should eq [closed_policy_environment.id]
        end

        it 'validates inconsistent environments' do
          params = {json_root => { environment_ids: [closed_policy_environment.id, opened_policy_environment.id] }}.to_json
          jput params
          response.code.should eq '422'
        end
      end

      context 'prevent behavior' do
        let(:url) { "#{base_url}/#{prevent_deployment_window_series.id}?token=#{@user.api_key}" }

        it 'json' do
          put url, json_root => { environment_ids: [opened_policy_environment.id] }, format: :json
          prevent_deployment_window_series.reload.environments.map(&:id).should eq [opened_policy_environment.id]
        end

        it 'xml' do
          put url, xml_root => { environment_ids: [opened_policy_environment.id] }, format: :xml
          prevent_deployment_window_series.reload.environments.map(&:id).should eq [opened_policy_environment.id]
        end

        it 'skips inconsistent environments' do
          put url, json_root => { environment_ids: [closed_policy_environment.id, opened_policy_environment.id] }, format: :json
          response.code.should eq '422'
        end
      end
    end
  end

  describe 'DELETE /v1/deployment_window/series/[id]' do
    let!(:archived_deployment_window_series) { create(:deployment_window_series, archive_number: '123', archived_at: DateTime.now) }
    let!(:unarchived_deployment_window_series) { create(:deployment_window_series) }
    let(:params) { { } }

    context 'delete archived deployment window series' do
      let(:url) { "#{base_url}/#{archived_deployment_window_series.id}?token=#{@user.api_key}" }

      it_behaves_like 'successful request', type: :json, method: :delete, status: 202 do
        specify { DeploymentWindow::Series.exists?(archived_deployment_window_series.id).should be_falsey }
      end

      it_behaves_like 'successful request', type: :xml, method: :delete, status: 202 do
        specify { DeploymentWindow::Series.exists?(archived_deployment_window_series.id).should be_falsey }
      end
    end

    context 'delete unarchived deployment window series' do
      let(:url) { "#{base_url}/#{unarchived_deployment_window_series.id}?token=#{@user.api_key}" }

      it_behaves_like 'successful request', type: :json, method: :delete, status: 412 do
        specify { DeploymentWindow::Series.exists?(unarchived_deployment_window_series.id).should be_truthy }
      end

      it_behaves_like 'successful request', type: :xml, method: :delete, status: 412 do
        specify { DeploymentWindow::Series.exists?(unarchived_deployment_window_series.id).should be_truthy }
      end
    end
  end

end
