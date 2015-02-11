require 'spec_helper'

describe 'v1/deployment_window/events' do
  before :all do
    @user = create(:user)
    User.current_user = @user
    @token        = @user.api_key
  end

  let(:base_url) { '/v1/deployment_window/events' }
  let(:json_root) { :deployment_window_event }
  let(:xml_root) { 'deployment_window_event' }
  let(:params) { {token: @user.api_key} }
  let(:series) { create(:deployment_window_series, start_at: Time.now + 1.day, finish_at: Time.now + 2.years) }
  let(:occurrence) {
    create :deployment_window_occurrence, {
      start_at: Time.now - 1.year,
      finish_at: Time.now + 1.year,
      series_id: series.id,
      environment_ids: [create(:environment, :closed).id]
    }
  }
  let(:event) { create(:deployment_window_event, occurrence_id: occurrence.id) }

  subject       { response.body }

  describe 'GET /v1/deployment_window/events/[id]' do
    let(:url) { "#{base_url}/#{event.id}" }

    it_behaves_like "successful request", type: :json do
      it { should have_json('.id').with_value(event.id) }
      it { should have_json('.state').with_value(event.state) }
      it { should have_json('.start_at') }
      it { should have_json('.finish_at') }
      it { should have_json('.created_at') }
      it { should have_json('.updated_at') }
      it { should have_json('.occurrence') }
      it { should have_json('.series') }
    end

    it_behaves_like "successful request", type: :xml do
      it { should have_xpath('/event/id').with_text(event.id) }
      it { should have_xpath('/event/state').with_text(event.state) }
      it { should have_xpath('/event/start-at') }
      it { should have_xpath('/event/finish-at') }
      it { should have_xpath('/event/created-at') }
      it { should have_xpath('/event/updated-at') }
      it { should have_xpath('/event/occurrence') }
      it { should have_xpath('/event/series') }
    end
  end

  describe 'PUT /v1/deployment_window/events/[id]' do
    let(:url) { "#{base_url}/#{event.id}?token=#{@user.api_key}" }

    describe 'suspend' do
      let(:data) { {state: 'suspended', reason: 'suspend reason'} }

      context "json" do
        let(:params) { {json_root => data}.to_json }
        before { jput params }

        it { should have_json('.id').with_value(event.id) }
        it { should have_json('.state').with_value(data[:state]) }
        it { should have_json('.reason').with_value(data[:reason]) }

        context "without reason" do
          let(:data) { {state: 'suspended'} }

          it { response.code.should eq '422' }
        end
      end

      context "xml" do
        let(:params) { data.to_xml(root: xml_root) }
        before { xput params }

        it { should have_xpath('/event/id').with_text(event.id) }
        it { should have_xpath('/event/state').with_text(data[:state]) }
        it { should have_xpath('/event/reason').with_text(data[:reason]) }
      end
    end

    describe 'resume' do
      let(:data) { {state: 'resumed', reason: 'resume reason'} }

      context "json" do
        let(:params) { {json_root => data}.to_json }
        before { jput params }

        it { should have_json('.id').with_value(event.id) }
        it { should have_json('.state').with_value(data[:state]) }
        it { should have_json('.reason').with_value(data[:reason]) }
      end

      context "xml" do
        let(:params) { data.to_xml(root: xml_root) }
        before { xput params }

        it { should have_xpath('/event/id').with_text(event.id) }
        it { should have_xpath('/event/state').with_text(data[:state]) }
        it { should have_xpath('/event/reason').with_text(data[:reason]) }
      end
    end

    describe 'move' do
      let(:data) {
        {
          state: 'moved',
          reason: 'move reason',
          start_at: Time.now + 3.days,
          finish_at: Time.now + 4.days
        }
      }

      context "json" do
        let(:params) { {json_root => data}.to_json }
        before { jput params }

        it { should have_json('.id').with_value(event.id) }
        it { should have_json('.state').with_value(data[:state]) }
        it { should have_json('.reason').with_value(data[:reason]) }
      end

      context "xml" do
        let(:params) { data.to_xml(root: xml_root) }
        before { xput params }

        it { should have_xpath('/event/id').with_text(event.id) }
        it { should have_xpath('/event/state').with_text(data[:state]) }
        it { should have_xpath('/event/reason').with_text(data[:reason]) }
      end
    end
  end
end
