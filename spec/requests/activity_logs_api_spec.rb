require 'spec_helper'

describe 'testing /v1/activity_logs' do
  before(:each) do
    @user             = create(:user)
    @token            = @user.api_key

    # Temporary set current user - request can't be created otherwise
    User.current_user = @user
    @request          = create(:request)
    @step             = create(:step, :request => @request)
  end

  base_url = '/v1/activity_logs'
  let(:base_url) {'/v1/activity_logs'}

  describe "GET #{base_url}" do
    before(:each) do
      ActivityLog.delete_all

      @al1      = create(:activity_log, :user => @user, :request => @request, :step => @step)
      @al2      = create(:activity_log, :user => @user, :request => @request, :step => @step)

      @als      = [@al1, @al2].map(&:id)
    end

    let(:url) {"#{base_url}?token=#{@token}"}

    context 'JSON' do
      let(:json_root) {'array:root > object'}

      subject { response.body }

      context 'response body' do
        before(:each) {jget }

        specify { response.code.should == '200' }

        it {should have_json('string.activity')}
        it {should have_json('string.created_at')}
        it {should have_json('number.usec_created_at')}
        it {should have_json('number.id')}
        it {should have_json('*.type')}
        it {should have_json('object.request')}
        it {should have_json('object.user')}
      end

      it 'should return all activity logs' do
        jget

        should have_json("#{json_root} > number.id").with_values(@als)
      end

      it 'should return all activity by type' do
        param = {:filters => {:type => nil}}

        jget param

        should have_json("#{json_root} > number.id").with_values(@als)
      end

      it 'should return all activity by request_id' do
        param = {:filters => {:request_id => @request.id}}

        jget param

        should have_json("#{json_root} > number.id").with_values(@als)
      end

      it 'should return all activity by user_id' do
        param = {:filters => {:user_id => @user.id}}

        jget param

        should have_json("#{json_root} > number.id").with_values(@als)
      end

      it 'should return all activity by step_id' do
        param = {:filters => {:step_id => @step.id}}

        jget param

        should have_json("#{json_root} > number.id").with_values(@als)
      end

      it 'should return all activity by type and request_id' do
        param = {:filters => {:type => nil,
                              :request_id => @request.id}
        }

        jget param

        should have_json("#{json_root} > number.id").with_values(@als)
      end

      it 'should return all activity by type and request_id, and user_id' do
        param = {:filters => {:type => nil,
                              :request_id => @request.id,
                              :user_id => @user.id}
        }

        jget param

        should have_json("#{json_root} > number.id").with_values(@als)
      end

      it 'should return all activity by type and request_id, and user_id, and step_id' do
        param = {:filters => {:type => nil,
                              :request_id => @request.id,
                              :user_id => @user.id,
                              :step_id => @step.id}
        }

        jget param

        should have_json("#{json_root} > number.id").with_values(@als)
      end
    end

    context 'XML' do
      let(:xml_root) { 'activity-logs/activity-log' }

      subject { response.body }

      context 'response body' do
        before(:each) { xget }

        specify { response.code.should == '200' }

        it {should have_xpath("#{xml_root}/activity")}
        it {should have_xpath("#{xml_root}/created-at")}
        it {should have_xpath("#{xml_root}/usec-created-at")}
        it {should have_xpath("#{xml_root}/id")}
        it {should have_xpath("#{xml_root}/type")}
        it {should have_xpath("#{xml_root}/request")}
        it {should have_xpath("#{xml_root}/user")}
      end

      it 'should return all activity logs' do
        xget

        should have_xpath("#{xml_root}/id").with_texts(@als)
      end

      it 'should return all activity by type' do
        param = {:filters => {:type => nil}}

        xget param

        should have_xpath("#{xml_root}/id").with_texts(@als)
      end

      it 'should return all activity by request_id' do
        param = {:filters => {:request_id => @request.id}}

        xget param

        should have_xpath("#{xml_root}/id").with_texts(@als)
      end

      it 'should return all activity by user_id' do
        param = {:filters => {:user_id => @user.id}}

        xget param

        should have_xpath("#{xml_root}/id").with_texts(@als)
      end

      it 'should return all activity by step_id' do
        param = {:filters => {:step_id => @step.id}}

        xget param

        should have_xpath("#{xml_root}/id").with_texts(@als)
      end

      it 'should return all activity by type and request_id' do
        param = {:filters => {:type => nil,
                              :request_id => @request.id}
        }

        xget param

        should have_xpath("#{xml_root}/id").with_texts(@als)
      end

      it 'should return all activity by type and request_id, and user_id' do
        param = {:filters => {:type => nil,
                              :request_id => @request.id,
                              :user_id => @user.id}
        }

        xget param

        should have_xpath("#{xml_root}/id").with_texts(@als)
      end

      it 'should return all activity by type and request_id, and user_id, and step_id' do
        param = {:filters => {:type => nil,
                              :request_id => @request.id,
                              :user_id => @user.id,
                              :step_id => @step.id}
        }

        xget param

        should have_xpath("#{xml_root}/id").with_texts(@als)
      end
    end
  end

  describe "GET #{base_url}/[id]" do
    before(:each) do
      ActivityLog.delete_all

      @al      = create(:activity_log, :user => @user, :request => @request, :step => @step)
    end

    let(:url) {"#{base_url}/#{@al.id}?token=#{@token}"}
    let(:param) { {:id => @al.id} }

    context 'JSON' do
      it 'should return activity log by given id' do
        jget param

        response.body.should have_json('number.id').with_value(@al.id)
      end
    end

    context 'XML' do
      it 'should return activity log by given id' do
        xget param

        response.body.should have_xpath('activity-log/id').with_text(@al.id)
      end
    end
  end

  describe "POST PUT DELETE #{base_url}" do
    let(:token) { @token }

    methods_urls_for_405 = {
        post:     ["#{base_url}"],
        put:      ["#{base_url}/1"],
        delete:   ["#{base_url}/1"]
    }

    mimetypes = ['json', 'xml']

    test_batch_of_requests methods_urls_for_405, :response_code => 405, :mimetypes => mimetypes
  end

  context 'with invalid api key' do
    let(:token)     { 'invalid_api_key' }

    methods_urls_for_403 = {
        get:      ["#{base_url}", "#{base_url}/1"],
        post:     ["#{base_url}"],
        put:      ["#{base_url}/1"],
        delete:   ["#{base_url}/1"]
    }

    test_batch_of_requests methods_urls_for_403, response_code: 403
  end

  context 'with no existing releases' do
    before(:each) do
      # make sure there's none of ActivityLog
      ActivityLog.delete_all
    end

    let(:token)    { @token }

    methods_urls_for_404 = {
        get:      ["#{base_url}", "#{base_url}/1"]
    }

    mimetypes = ['json', 'xml']

    test_batch_of_requests methods_urls_for_404, response_code: 404, mimetypes: mimetypes
  end

end