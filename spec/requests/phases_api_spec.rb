require 'spec_helper'

describe 'testing /v1/phases' do
  before(:all) do
    @user   = create(:user)
    @token  = @user.api_key
  end

  let(:base_url) { '/v1/phases' }
  let(:json_root) { :phase }
  let(:xml_root) { 'phase' }

  let(:params) { {token: @token} }
  subject { response }
  context 'with existing phases' do
    describe 'get v1/phases/{{id}}' do
      before(:each) { @phase = Phase.in_order.first || create(:phase) }
      let(:url) { "#{base_url}/#{@phase.id}"}

      it_behaves_like 'successful request', type: :json do
        subject { response.body }
        it { should have_json('number.id').with_value(@phase.id) }
        it { should have_json('string.name').with_value(@phase.name) }
        it { should have_json('number.position').with_value(@phase.position) }
        it { should have_json('string.created_at') }
        it { should have_json('string.updated_at') }
      end

      it_behaves_like 'successful request', type: :xml do
        subject { response.body }
        it { should have_xpath('/phase/id').with_text(@phase.id) }
        it { should have_xpath('/phase/name').with_text(@phase.name) }
        it { should have_xpath('/phase/position').with_text(@phase.position) }
        it { should have_xpath('/phase/created-at') }
        it { should have_xpath('/phase/updated-at') }
      end
    end

    describe 'get v1/phases' do
      before(:each) { @phase = Phase.in_order.first || create(:phase) }
      let(:url) { base_url }

      it_behaves_like 'successful request', type: :json do
        subject { response.body }
        it { should have_json('object number.id').with_value(@phase.id) }
      end

      it_behaves_like 'successful request', type: :xml do
        subject { response.body }
        it { should have_xpath('/phases/phase[1]/id').with_text(@phase.id) }
      end
    end

    # Creates a new phase from posted data
    describe 'post /v1/phases' do
      let(:url) { "#{base_url}?token=#{@token}" }
      it_behaves_like 'successful request', type: :json, method: :post, status: 201 do
        let(:phase_name) { "JSON Phase #{Time.now.to_i}" }
        let(:params) { {phase: attributes_for(:phase, name: phase_name)}.to_json }
        let(:added_phase) { Phase.where(name: phase_name).first }
        subject { response.body }
        it { should have_json('number.id').with_value(added_phase.id) }
        it { should have_json('string.name').with_value(added_phase.name) }
        it { should have_json('number.position').with_value(added_phase.position) }
        it { should have_json('string.created_at') }
        it { should have_json('string.updated_at') }
      end
      it_behaves_like 'successful request', type: :xml, method: :post, status: 201 do
        let(:phase_name) { "XML Phase #{Time.now.to_i}" }
        let(:params) {
          create_xml do |xml|
            xml.phase { xml.name phase_name }
          end
        }
        subject { response.body }
        let(:added_phase) { Phase.where(name: phase_name).first }

        it { should have_xpath('/phase/id').with_text(added_phase.id) }
        it { should have_xpath('/phase/name').with_text(added_phase.name) }
        it { should have_xpath('/phase/position').with_text(added_phase.position) }
        it { should have_xpath('/phase/created-at') }
        it { should have_xpath('/phase/updated-at') }
      end

      it_behaves_like 'with `toggle_archive` param'

      it_behaves_like 'creating request with params that fails validation' do
        before(:each) do
          @phase = create(:phase)
        end

        let(:param) { {:name => ''} }
      end

      it_behaves_like 'creating request with invalid params'
    end

    # put /v1/phases/[id]
    describe 'PUT /v1/phases/[id]' do
      before :each do
        # Exist problems with creating `step` as its associations is being
        # created every time and causing collitions. So doing this manually.
        phase           = create(:phase)
        plan_member     = create(:plan_member)
        request         = create(:request, :deployment_coordinator => @user, :requestor => @user, :plan_member => plan_member)

        @step           = create(:step, :owner => @user, :request => request, :phase => phase)
        @runtime_phase  = create(:runtime_phase)
      end

      let(:url)     {"#{base_url}/#{@phase.id}?token=#{@token}"}

      context 'with valid params' do
        let(:step)          { Step.last         || create(:step, :owner => @user, :request => @request, :phase => @phase)}
        let(:runtime_phase) { RuntimePhase.last || create(:runtime_phase)}
        let(:new_name)      { 'new name'}
        let(:new_step_ids)  { [step.id] }
        let(:new_runtime_phase_ids) { [runtime_phase.id] }
        let(:phase_params)  { { :name => new_name,
                                :step_ids => new_step_ids,
                                :runtime_phase_ids => new_runtime_phase_ids
                            } }
        let(:updated_phase) { Phase.find(@phase.id) }

        context 'using mimetype JSON' do
          context 'within new phase' do
            before :each do
              @phase = create(:phase)

              params = { json_root => phase_params }
              params = params.to_json

              # update the @phase
              jput params
            end

            specify { response.status.should == 202 }

            it 'should update the phase name' do
              response.body.should have_json('string.name').with_value(new_name)
              updated_phase.name.should == new_name
            end

            it 'should update the phase runtime phases' do
              updated_phase.runtime_phases.should match_array [runtime_phase]
            end

            it 'should update the phase steps' do
              response.body.should have_json('array.steps number.id').with_value(step.id)
              updated_phase.steps.should match_array [step]
            end
          end

          context 'within new phase' do
            before(:each) do
              @phase = create(:phase)

              params = {toggle_archive: 'true'}.to_json

              jput params
            end

            subject { response.body }

            it 'should toggle phase archive' do
              should have_json('string.archive_number')
              should have_json('string.archived_at')
              should have_json('number.position')
            end
          end
        end

        context 'using mimetype XML' do
          context 'within new phase' do
            before :each do
              @phase = create(:phase)

              params = phase_params
              params = params.to_xml(:root => 'phase')

              # update the @phase
              xput params
            end

            specify { response.status.should == 202 }

            it 'should update the phase name' do
              response.body.should have_xpath('/phase/name').with_text(new_name)
              updated_phase.name.should == new_name
            end

            it 'should update the phase runtime phases' do
              updated_phase.runtime_phases.should match_array [runtime_phase]
            end

            it 'should update the steps' do
              response.body.should have_xpath('/phase/steps/step/id').with_text(step.id)
              updated_phase.steps.should match_array [step]
            end
          end

          context 'within new phase' do
            before(:each) do
              @phase = create(:phase)
              params = create_xml {|xml| xml.toggle_archive 'true'}

              xput params
            end

            subject { response.body }

            it 'should toggle archive' do
              should have_xpath('/phase/archive-number')
              should have_xpath('/phase/archived-at')
              should have_xpath('/phase/position')
            end
          end
        end
      end

      it_behaves_like 'editing request with params that fails validation' do
        before(:each) do
          @phase = create(:phase)
        end

        let(:param) { { name: '' } }
      end

      it_behaves_like 'editing request with invalid params'
    end

    # delete /v1/phases/[id]
    describe 'DELETE /v1/phases/[id]' do
      before :each do
        @phase = create(:phase)
        @token = @token
      end

      before :each do
        Phase.stub(:find).with(@phase.id).and_return @phase
        @phase.should_receive(:try).with(:destroy).and_return true
      end

      let(:url) {"#{base_url}/#{@phase.id}?token=#{@token}"}

      mimetypes = ['json', 'xml']
      mimetypes.each do |mimetype|
        it "should be successful using mimetype #{mimetype.upcase}" do
          params_json       = {id: @phase.id}.to_json
          params_xml        = create_xml {|xml| xml.id @phase.id}
          params            = eval "params_#{mimetype}"
          mimetype_headers  = eval "#{mimetype}_headers"

          delete url, params, mimetype_headers

          response.status.should == 202
        end
      end
    end

  end

  context 'with invalid api key' do
    let(:token) { 'invalid_api_key' }

    methods_urls_for_403 = {
        get:      ['/v1/phases', '/v1/phases/1'],
        post:     ['/v1/phases'],
        put:      ['/v1/phases/1'],
        delete:   ['/v1/phases/1']
    }

    test_batch_of_requests methods_urls_for_403, response_code: 403
  end

  context 'with no existing phases' do

    let(:token)   { @token}

    methods_urls_for_404 = {
        get:      ['/v1/phases', '/v1/phases/1'],
        put:      ['/v1/phases/1'],
        delete:   ['/v1/phases/1']
    }

    mimetypes = ['json', 'xml']

    test_batch_of_requests methods_urls_for_404, response_code: 404, mimetypes: mimetypes
  end
end
