require 'spec_helper'

describe 'v1/tickets' do
  before(:all) {
    @user = create(:user)
  }
  let(:token) { @user.api_key }
  let(:base_url) { '/v1/tickets' }
  let(:json_root) { :ticket }
  let(:xml_root) { 'ticket' }
  let(:params) { {} }

  context 'when no tickets exist' do
    let(:url) { "#{base_url}?token=#{token}" }
    tested_formats.each do |type|
      it_behaves_like 'successful request', status: 404, type: type
    end
    context 'when trying to reach invalid id' do
      let(:url) { "#{base_url}/50?token=#{token}" }
      %w(get put delete).each do |method|
        context "#{method.upcase} /{{id}}" do
          tested_formats.each do |type|
            it_behaves_like 'successful request', status: 404, type: type, method: method.to_sym
          end
        end
      end
    end
    describe 'POST /' do
      before(:each) {
        @project_server = create(:project_server)
      }
      it_behaves_like 'successful request', status: 201, method: :post, type: :json do
        let(:params) { {json_root => {foreign_id: 'json foreign id',
                                      name: 'json ticket',
                                      project_server_id: @project_server.id,
                                      url: 'www.rally.com/?id=abc123'}}.to_json }
        specify { response.body.should have_json('number.id') }
        specify { response.body.should have_json('string.name').with_value('json ticket') }
        specify { response.body.should have_json('string.url').with_value('http://www.rally.com/?id=abc123') }
      end
      it_behaves_like 'successful request', status: 201, method: :post, type: :xml do
        let(:params) { {name: 'xml ticket',
                        foreign_id: 'xml foreign id',
                        project_server_id: 10,
                        url: 'rally.com/?id=xyz333'}.to_xml(root: xml_root) }
        specify { response.body.should have_xpath('ticket/id') }
        specify { response.body.should have_xpath('ticket/name').with_text('xml ticket') }
        specify { response.body.should have_xpath('ticket/url').with_text('http://rally.com/?id=xyz333') }
      end

      it_behaves_like 'creating request with params that fails validation' do
        let(:param) { {:foreign_id => nil, :name => nil, :status => nil, :project_server_id => nil, :ticket_type => nil } }
      end

      it_behaves_like 'creating request with invalid params'
    end
  end

  context 'when tickets exists' do
    before(:each) {
      User.current_user = @user
      @ticket1 = create(:ticket, ticket_type: 'cool_type', url: 'http://rally.com/?id=1',
                    steps: create_list(:step, 1), project_server: create(:project_server))
      @ticket2 = create(:ticket, name: 'cool name', url: 'http://rally.com/?id=2',
                    app: create(:app, name: 'cool_app'))
      @ticket3 = create(:ticket, plans: [create(:plan)], url: 'http://rally.com/?id=3')
      User.current_user = nil
    }
    let(:tickets) { [@ticket1, @ticket2, @ticket3] }
    describe 'GET /' do
      let(:url) { "#{base_url}?token=#{token}" }
      let(:id_json_select) { ':root > object > number.id' }
      let(:id_xpath) { 'tickets/ticket/id' }
      it_behaves_like 'successful request', type: :json do
        subject { response.body }
        it { should have_json(':root > object > string.created_at') }
        it { should have_json(':root > object > string.updated_at') }
        it { should have_json(':root > object > number.id')
             .with_values(tickets.map(&:id)) }
        it { should have_json(':root > object > string.name')
             .with_values(tickets.map(&:name)) }
        it { should have_json(':root > object > string.status')
             .with_values(tickets.map(&:status)) }
        it { should have_json(':root > object > number.app_id')
             .with_values(tickets.map(&:app).select(&:present?).map(&:id)) }
        it { should have_json(':root > object > number.project_server_id')
             .with_values(tickets.map(&:project_server).select(&:present?)
                          .map(&:id)) }
        it { should have_json(':root > object > string.ticket_type')
             .with_values(tickets.map(&:ticket_type)) }
        it { should have_json(':root > object > string.url')
                    .with_values(tickets.map(&:url)) }
        it { should have_json(':root > object > object.project_server') }
        it { should have_json(':root > object > array.plans') }
        it { should have_json(':root > object > array.related_tickets') }
        it { should have_json(':root > object > array.steps') }
        it { should have_json(':root > object > array.extended_attributes') }
      end
      it_behaves_like 'successful request', type: :xml do
        subject { response.body }
        it { should have_xpath('tickets/ticket/created-at') }
        it { should have_xpath('tickets/ticket/updated-at') }
        it { should have_xpath('tickets/ticket/id')
             .with_texts(tickets.map(&:id)) }
        it { should have_xpath('tickets/ticket/name')
             .with_texts(tickets.map(&:name)) }
        it { should have_xpath('tickets/ticket/status')
             .with_texts(tickets.map(&:status)) }
        it { should have_xpath('tickets/ticket/app-id/text()')
             .with_texts(tickets.map(&:app).select(&:present?).map(&:id)) }
        it { should have_xpath('tickets/ticket/project-server-id')
             .with_texts(tickets.map(&:project_server).select(&:present?)
                         .map(&:id)) }
        it { should have_xpath('tickets/ticket/ticket-type')
             .with_texts(tickets.map(&:ticket_type)) }
        it { should have_xpath('tickets/ticket/url')
                    .with_texts(tickets.map(&:url)) }
        it { should have_xpath('tickets/ticket/project-server') }
        it { should have_xpath('tickets/ticket/plans') }
        it { should have_xpath('tickets/ticket/related-tickets') }
        it { should have_xpath('tickets/ticket/steps') }
        it { should have_xpath('tickets/ticket/extended-attributes') }
      end
      describe 'filtered by type' do
        let(:params) { {filters: { ticket_type: ['cool_type'] }} }
        it_behaves_like 'successful request', type: :json do
          specify { response.body.should have_json(id_json_select)
                    .with_values([@ticket1.id]) }
        end
        it_behaves_like 'successful request', type: :xml do
          specify { response.body.should have_xpath(id_xpath)
                    .with_texts([@ticket1.id]) }
        end
      end
      describe 'filtered by app id' do
        let(:params) { {filters: { app_id: @ticket2.app.id }} }
        it_behaves_like 'successful request', type: :json do
          specify { response.body.should have_json(id_json_select)
                    .with_values([@ticket2.id]) }
        end
        it_behaves_like 'successful request', type: :xml do
          specify { response.body.should have_xpath(id_xpath)
                    .with_texts([@ticket2.id]) }
        end
      end
      describe 'filtered by plan id' do
        let(:params) { {filters: { plan_id: @ticket3.plans.first.id }} }
        it_behaves_like 'successful request', type: :json do
          specify { response.body.should have_json(id_json_select)
                    .with_values([@ticket3.id]) }
        end
        it_behaves_like 'successful request', type: :xml do
          specify { response.body.should have_xpath(id_xpath)
                    .with_texts([@ticket3.id]) }
        end
      end
      describe 'filtered by foreign id' do
        let(:params) { {filters: { foreign_id: @ticket3.foreign_id }} }
        it_behaves_like 'successful request', type: :json do
          specify { response.body.should have_json(id_json_select)
                    .with_values([@ticket3.id]) }
        end
        it_behaves_like 'successful request', type: :xml do
          specify { response.body.should have_xpath(id_xpath)
                    .with_texts([@ticket3.id]) }
        end
      end
      describe 'filtered by project server id' do
        let(:params) { {filters: { project_server_id: @ticket1.project_server.id }} }
        it_behaves_like 'successful request', type: :json do
          specify { response.body.should have_json(id_json_select)
                    .with_values([@ticket1.id]) }
        end
        it_behaves_like 'successful request', type: :xml do
          specify { response.body.should have_xpath(id_xpath)
                    .with_texts([@ticket1.id]) }
        end
      end
      describe 'filtered by step id' do
        let(:params) { {filters: { step_id: @ticket1.steps.first.id }} }
        it_behaves_like 'successful request', type: :json do
          specify { response.body.should have_json(id_json_select)
                    .with_values([@ticket1.id]) }
        end
        it_behaves_like 'successful request', type: :xml do
          specify { response.body.should have_xpath(id_xpath)
                    .with_texts([@ticket1.id]) }
        end
      end
      describe 'filtered by app name' do
        let(:params) { {filters: { app_name: 'cool_app' }} }
        it_behaves_like 'successful request', type: :json do
          specify { response.body.should have_json(id_json_select)
                    .with_values([@ticket2.id]) }
        end
        it_behaves_like 'successful request', type: :xml do
          specify { response.body.should have_xpath(id_xpath)
                    .with_texts([@ticket2.id]) }
        end
      end
    end

    describe 'PUT {{id}}/' do
      before(:each) { @ticket_put = create(:ticket) }
      let(:url) { "#{base_url}/#{@ticket_put.id}?token=#{@user.api_key}" }
      it_behaves_like 'successful request', status: 202, method: :put, type: :json do
        let(:params) { {json_root => {name: 'updated json name'}}.to_json }
        specify { response.body.should have_json('number.id') }
        specify { response.body.should have_json('string.name').with_value('updated json name') }
        specify { Ticket.find(@ticket_put.id).name.should == 'updated json name' }
      end
      it_behaves_like 'successful request', status: 202, method: :put, type: :xml do
        let(:params) { {name: 'updated xml name'}.to_xml(root: xml_root) }
        specify { response.body.should have_xpath('ticket/id')}
        specify { response.body.should have_xpath('ticket/name').with_text('updated xml name') }
        specify { Ticket.find(@ticket_put.id).name.should == 'updated xml name' }
      end

      it_behaves_like 'editing request with params that fails validation' do
        let(:param) { {:foreign_id => nil, :name => nil, :status => nil, :project_server_id => nil, :ticket_type => nil } }
      end

      it_behaves_like 'editing request with invalid params'
    end

    describe "DELETE {{id}}/" do
      tested_formats.each do |format|
        context 'when trying to delete ticket' do
          before(:each) { @ticket_delete = create(:ticket) }
          let(:url) { "#{base_url}/#{@ticket_delete.id}?token=#{@user.api_key}"}
          it_behaves_like 'successful request', type: format, status: 202, method: :delete do
            specify { Ticket.exists?(@ticket_delete.id).should be_falsey }
          end
        end
      end
    end
  end
end
