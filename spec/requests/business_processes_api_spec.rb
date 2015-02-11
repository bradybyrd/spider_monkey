require 'spec_helper'

base_url =  '/v1/business_processes'
describe "testing #{base_url}" do
  let(:base_url) { base_url }
  let(:json_root) { :business_process }
  let(:xml_root) { 'business-process' }

  before(:all)  do
    @user         = create(:user)
    @token        = @user.api_key
  end

  context 'with existing business_processes and valid api key' do
    before(:each)  do
      User.current_user = @user
      @request      = create(:request, :deployment_coordinator => @user, :requestor => @user)
      User.stub(:current_user).and_return @user
    end

    let(:url)     { "#{base_url}?token=#{@token}" }

    describe "GET #{base_url}" do
      before(:each) do
        @bp_1 = create(:business_process)
        @bp_2 = create(:business_process, :name => 'cool name')
        @bp_3 = create(:business_process, :name => 'mad name')
        @bp_3.toggle_archive
        @bp_3.reload

        @unarchived_business_process_ids = [@bp_2.id, @bp_1.id]
      end

      context 'JSON' do
        let(:json_root) { 'array:root > object' }

        subject { response.body }

        it 'should return all business_processes except archived(by default)' do
          jget

          should have_json("#{json_root} > number.id").with_values(@unarchived_business_process_ids)
        end

        it 'should return all business_processes except archived' do
          param   = {:filters => {:unarchived => true}}

          jget param

          should have_json("#{json_root} > number.id").with_values(@unarchived_business_process_ids)
        end

        it 'should return all business_processes archived' do
          param   = {:filters => {:archived => true}}

          jget param

          should have_json("#{json_root} > number.id").with_values([@bp_3.id])
        end

        it 'should return all business_processes' do
          param   = {:filters => {:archived => true, :unarchived => true}}

          jget param

          should have_json("#{json_root} > number.id").with_values([@bp_3.id] + @unarchived_business_process_ids)
        end

        it 'should return all archieved business_processes' do
          param   = {:filters => {:archived => true, :unarchived => false}}

          jget param

          should have_json('number.id').with_value(@bp_3.id)
        end

        it 'should return business_process by name' do
          param   = {:filters => {:name => 'cool name'}}

          jget param

          should have_json('number.id').with_value(@bp_2.id)
        end

        it 'should return nothing' do
          param   = {:filters => {:archived => false, :unarchived => false}}

          jget param

          should == " "
        end

        it 'should return unarchived business processes' do
          param   = {:filters => {:asddas => false, :unarchived => 't'}}

          jget param

          should have_json("#{json_root} > number.id").with_values(@unarchived_business_process_ids)
        end

        it 'should not return archived business_process by name' do
          param   = {:filters => {:name => @bp_3.name}}

          jget param

          should == " "
        end

        it 'should return archived business_process by name if that was specified' do
          param   = {:filters => {:name => @bp_3.name, :archived => true}}

          jget param

          should have_json('number.id').with_value(@bp_3.id)
        end
      end

      context 'XML' do
        let(:xml_root) {'business-processes/business-process'}

        subject { response.body }

        it 'should return all business_processes except archived(by default)' do
          xget

          should have_xpath("#{xml_root}/id").with_texts(@unarchived_business_process_ids)
        end

        it 'should return all business_processes archived' do
          param   = {:filters => {:archived => true}}

          xget param

          should have_xpath("#{xml_root}/id").with_texts([@bp_3.id])
        end

        it 'should return all business_processes except archived' do
          param   = {:filters => {:unarchived => true}}

          xget param

          should have_xpath("#{xml_root}/id").with_texts(@unarchived_business_process_ids)
        end

        it 'should return all business_processes' do
          param   = {:filters => {:archived => true, :unarchived => true}}

          xget param

          should have_xpath("#{xml_root}/id").with_texts([@bp_3.id] + @unarchived_business_process_ids)
        end

        it 'should return all archieved business_processes' do
          param   = {:filters => {:archived => true, :unarchived => false}}

          xget param

          should have_xpath("#{xml_root}/id").with_text(@bp_3.id)
        end

        it 'should return business_process by name' do
          param   = {:filters => {:name => 'cool name'}}

          xget param

          should have_xpath("#{xml_root}/id").with_text(@bp_2.id)
        end

        it 'should not return archived business_process by name if that was not specified' do
          param   = {:filters => {:name => @bp_3.name}}

          xget param

          should == " "
        end

        it 'should return archived business_process by name if that was specified' do
          param   = {:filters => {:name => @bp_3.name, :archived => true}}

          xget param

          should have_xpath("#{xml_root}/id").with_text(@bp_3.id)
        end
      end
    end

    describe "GET #{base_url}/[id]" do
      before(:each) do
        @bp_1 = create(:business_process)
        @bp_2 = create(:business_process)
      end

      context 'JSON' do
        let(:url) {"#{base_url}/#{@bp_1.id}?token=#{@token}"}

        subject { response.body }

        it 'should return business_process' do
          jget

          should have_json('number.id').with_value(@bp_1.id)
        end
      end

      context 'XML' do
        let(:url) {"#{base_url}/#{@bp_2.id}?token=#{@token}"}

        subject { response.body }

        it 'should return business_process' do
          xget

          should have_xpath('business-process/id').with_text(@bp_2.id)
        end
      end
    end

    describe "POST #{base_url}" do
      let(:_request)                  { @request }
      let(:application)               { create(:app) }
      let(:created_business_process)  { BusinessProcess.last }

      context 'with valid params' do
        let(:param)             { {:name => 'shakeit',
                                   :label_color => '#00FFFF',
                                   :app_ids => [application.id],
                                   :request_ids => [_request.id]
        }
        }

        context 'JSON' do
          before :each do
            params    = {json_root => param}.to_json

            jpost params
          end

          subject { response.body }

          specify { response.code.should == '201' }

          it { should have_json('*.archive_number')  }
          it { should have_json('*.archived_at')     }
          it { should have_json('string.created_at') }
          it { should have_json('number.id')         }
          it { should have_json('string.label_color')}

          it 'should create business_process name' do
            should have_json('string.name').with_value('shakeit')
          end

          it 'should create business_process with given `label_color`' do
            should have_json('string.label_color').with_value('#00FFFF')
          end

          it 'should create business_process with given `request_ids`' do
            should have_json('array.requests number.id').with_value(_request.id)
            created_business_process.requests.should match_array [_request]
          end

          it 'should create business_process with given `app_ids`' do
            should have_json('array.apps number.id').with_value(application.id)
            created_business_process.apps.should match_array [application]
          end
        end

        context 'XML' do
          before :each do
            params    = param.to_xml(:root => xml_root)

            xpost params
          end

          subject { response.body }

          specify { response.code.should == '201' }

          it { should have_xpath("#{xml_root}/archive-number") }
          it { should have_xpath("#{xml_root}/archived-at")    }
          it { should have_xpath("#{xml_root}/created-at")     }
          it { should have_xpath("#{xml_root}/id")             }
          it { should have_xpath("#{xml_root}/label-color")    }

          it 'should create business_process name' do
            should have_xpath("#{xml_root}/name").with_text('shakeit')
          end

          it 'should update business_process with given `label_color`' do
            should have_xpath("#{xml_root}/label-color").with_text('#00FFFF')
          end

          it 'should create business_process with given `request_ids`' do
            should have_xpath("#{xml_root}/requests/request/id").with_text(_request.id)
            created_business_process.requests.should match_array [_request]
          end

          it 'should create business_process with given `app_ids`' do
            should have_xpath("#{xml_root}/apps/app/id").with_text(application.id)
            created_business_process.apps.should match_array [application]
          end
        end
      end

      it_behaves_like 'creating request with params that fails validation' do
        before(:each) { create(:business_process, :name => 'already exists') }

        let(:param) { {name: 'already exists'} }
      end

      it_behaves_like 'creating request with invalid params'
    end

    describe "PUT #{base_url}/[id]" do
      before(:each) do
        @bp = create(:business_process)
      end

      let(:_request)                  { create(:request, :deployment_coordinator => @user, :requestor => @user, :plan_member => @plan_member) }
      let(:application)               { create(:app) }
      let(:updated_business_process)  { BusinessProcess.find(@bp.id) }
      let(:url)                       {"#{base_url}/#{@bp.id}?token=#{@token}"}

      context 'with valid params' do
        let(:param)             { {:name => 'shakeit',
                                   :request_ids => [_request.id],
                                   :app_ids => [application.id],
                                   :label_color => '#00FFFF'
        }
        }

        context 'JSON' do
          before :each do
            params    = {json_root => param}.to_json
            @bp  = create(:business_process)

            jput params
          end

          subject { response.body }

          specify { response.code.should == '202' }

          it 'should update business_process name' do
            should have_json('string.name').with_value('shakeit')
          end

          it 'should update business_process with given `label_color`' do
            should have_json('string.label_color').with_value('#00FFFF')
          end

          it 'should update business_process with given `request_ids`' do
            should have_json('array.requests number.id').with_value(_request.id)
            updated_business_process.requests.should match_array [_request]
          end

          it 'should update business_process with given `app_ids`' do
            should have_json('array.apps number.id').with_value(application.id)
            updated_business_process.apps.should match_array [application]
          end
        end

        context 'XML' do
          before :each do
            params    = param.to_xml(:root => xml_root)
            @bp  = create(:business_process)

            xput params
          end

          subject { response.body }

          specify { response.code.should == '202' }

          it 'should update business_process name' do
            should have_xpath("#{xml_root}/name").with_text('shakeit')
          end

          it 'should update business_process with given `label_color`' do
            should have_xpath("#{xml_root}/label-color").with_text('#00FFFF')
          end

          it 'should update business_process with given `request_ids`' do
            should have_xpath("#{xml_root}/requests/request/id").with_text(_request.id)
            updated_business_process.requests.should match_array [_request]
          end

          it 'should update business_process with given `app_ids`' do
            should have_xpath("#{xml_root}/apps/app/id").with_text(application.id)
            updated_business_process.apps.should match_array [application]
          end
        end
      end

      it_behaves_like 'with `toggle_archive` param'

      it_behaves_like 'editing request with params that fails validation' do
        before(:each) do
          create(:business_process, :name => 'already exists')
          @bp = create(:business_process)
        end

        let(:param) { {:name => 'already exists'} }
      end

      it_behaves_like 'editing request with invalid params'
    end

    describe "DELETE #{base_url}/[id]" do
      before :each do
        @bp = create(:business_process)
      end

      before :each do
        BusinessProcess.delete_all
      end

      before :each do
        BusinessProcess.stub(:find).with(@bp.id).and_return @bp
        @bp.should_receive(:try).with(:destroy).and_return true
      end

      let(:url) {"#{base_url}/#{@bp.id}?token=#{@token}"}

      mimetypes = ['json', 'xml']
      mimetypes.each do |mimetype|
        it "should be successful using mimetype #{mimetype.upcase}" do
          params_json       = { id: @bp.id }.to_json
          params_xml        = create_xml {|xml| xml.id @bp.id}
          params            = eval "params_#{mimetype}"
          mimetype_headers  = eval "#{mimetype}_headers"

          delete url, params, mimetype_headers

          response.status.should == 202
        end
      end
    end
  end

  context 'with invalid api key' do
    let(:token)     { 'invalid_api_key' }

    methods_urls_for_403 = {
        get:      ["#{base_url}", "#{base_url}/1"],
        post:     ["#{base_url}"],
        put:      ["#{base_url}/1"],
        delete:   ["#{base_url}/1"]
    }

    test_batch_of_requests methods_urls_for_403, :response_code => 403
  end

  context 'with no existing business_processes' do

    let(:token)    { @token }

    methods_urls_for_404 = {
        get:      ["#{base_url}", "#{base_url}/1"],
        put:      ["#{base_url}/1"],
        delete:   ["#{base_url}/1"]
    }

    mimetypes = ['json', 'xml']

    test_batch_of_requests methods_urls_for_404, :response_code => 404, mimetypes: mimetypes
  end
end
