require 'spec_helper'

base_url = '/v1/notification_templates'
describe "testing #{base_url}" do
  let(:base_url) { base_url }
  let(:json_root) { :notification_template }
  let(:xml_root) { 'notification-template' }

  before :all do
    @user         = create(:user)
    @token        = @user.api_key
  end

  context 'with existing notification_templates and valid api key' do
    before(:each)  do
    end

    let(:url)     { "#{base_url}?token=#{@token}" }

    describe "GET #{base_url}" do
      before(:each) do
        @nt_1 = create(:notification_template)
        @nt_2 = create(:notification_template, :title => 'Acta Non Verba')
        @nt_3 = create(:notification_template, :title => 'mad', :active => false)

        @active_nt_ids = [@nt_2.id, @nt_1.id]
      end

      context 'JSON' do
        subject { response.body }

        it 'should return all notification_templates except inactive(by default)' do
          jget

          should have_json('number.id').with_values(@active_nt_ids)
        end

        it 'should return all notification_templates except inactive' do
          param   = {:filters => {:active => true}}

          jget param

          should have_json('number.id').with_values(@active_nt_ids)
        end

        it 'should return all notification_templates inactive' do
          param   = {:filters => {:inactive => true}}

          jget param

          should have_json('number.id').with_values([@nt_3.id])
        end

        it 'should return all notification_templates' do
          param   = {:filters => {:inactive => true, :active => true}}

          jget param

          should have_json('number.id').with_values([@nt_3.id] + @active_nt_ids)
        end

        it 'should return all inactive notification_templates' do
          param   = {:filters => {:inactive => true, :active => false}}

          jget param

          should have_json('number.id').with_value(@nt_3.id)
        end

        it 'should return notification_template by title' do
          param   = {:filters => {:title => 'Acta Non Verba'}}

          jget param

          should have_json('number.id').with_value(@nt_2.id)
        end

        it 'should not return inactive notification_template by title' do
          param   = {:filters => {:title => 'mad'}}

          jget param

          should == " "
        end

        it 'should return inactive notification_template by title if it is specified' do
          param   = {:filters => {:title => 'mad', :inactive => true}}

          jget param

          should have_json('number.id').with_value(@nt_3.id)
        end
      end

      context 'XML' do
        let(:xml_root) {'notification-templates/notification-template'}

        subject { response.body }

        it 'should return all notification_templates except inactive(by default)' do
          xget

          should have_xpath("#{xml_root}/id").with_texts(@active_nt_ids)
        end

        it 'should return all notification_templates except inactive' do
          param   = {:filters => {:active => true}}

          xget param

          should have_xpath("#{xml_root}/id").with_texts(@active_nt_ids)
        end

        it 'should return all notification_templates inactive' do
          param   = {:filters => {:inactive => true}}

          xget param

          should have_xpath("#{xml_root}/id").with_texts([@nt_3.id])
        end

        it 'should return all notification_templates' do
          param   = {:filters => {:inactive => true, :active => true}}

          xget param

          should have_xpath("#{xml_root}/id").with_texts([@nt_3.id] + @active_nt_ids)
        end

        it 'should return all inactive notification_templates' do
          param   = {:filters => {:inactive => true, :active => false}}

          xget param

          should have_xpath("#{xml_root}/id").with_text(@nt_3.id)
        end

        it 'should return notification_template by title' do
          param   = {:filters => {:title => 'Acta Non Verba'}}

          xget param

          should have_xpath("#{xml_root}/id").with_text(@nt_2.id)
        end

        it 'should not return inactive notification_template by title if that was not specified' do
          param   = {:filters => {:title => 'mad'}}

          xget param

          should == " "
        end

        it 'should return inactive notification_template by title if it is specified' do
          param   = {:filters => {:title => 'mad', :inactive => true}}

          xget param

          should have_xpath("#{xml_root}/id").with_text(@nt_3.id)
        end
      end
    end

    describe "GET #{base_url}/[id]" do
      let(:url) {"#{base_url}/#{@nt.id}?token=#{@user.api_key}"}

      before(:each) { @nt = create(:notification_template) }

      subject { response.body }

      context 'JSON' do
        it 'should return notification_template' do
          jget

          should have_json('number.id').with_value(@nt.id)
        end
      end

      context 'XML' do
        it 'should return notification_template' do
          xget

          should have_xpath('notification-template/id').with_text(@nt.id)
        end
      end
    end

    #***Required Attributes***
    #title - string title of the notification_template (required, unique)
    #event - string event for notification_template (required); acceptable values:
    #  exception_raised
    #  request_message
    #  request_completed
    #  request_cancelled
    #  step_started
    #  step_ready
    #  step_completed
    #  step_blocked
    #  step_problem
    #  user_created
    #  password_reset
    #  password_changed
    #  login
    #  user_admin_created
    #format - string format for notification_template (required, one of text/plain, text/enriched, text/html)
    #body - text of the message in Liquid template format (required)
    #
    #***Optional Attributes***
    #description - string description of the notification template
    describe "POST #{base_url}" do
      let(:url) {"#{base_url}?token=#{@token}"}
      let(:param) do
        {
          :title        => 'Work It',
          :event        => 'user_created',
          :body         => 'Do It',
          :format       => 'text/plain',
          :description  => 'Makes Us Harder Better Faster',
          :active => true
        }
      end

      context 'with valid params' do
        context 'JSON' do
          before :each do
            params = {json_root => param}.to_json

            jpost params
          end

          subject { response.body }

          specify { response.code.should == '201' }

          it { should have_json('boolean.active').with_value(true) }
          it { should have_json('string.created_at')               }
          it { should have_json('string.updated_at')               }
          it { should have_json('number.id')                       }

          it 'should have a title' do
            should have_json('string.title').with_value('Work It')
          end

          it 'should be active' do
            should have_json('string.event').with_value('user_created')
          end

          it 'should have body' do
            should have_json('string.body').with_value('Do It')
          end

          it 'should have format' do
            should have_json('string.format').with_value('text/plain')
          end

          it 'should have description' do
            should have_json('string.description').with_value('Makes Us Harder Better Faster')
          end
        end

        context 'XML' do
          before :each do
            params = param.to_xml(:root => xml_root)

            xpost params
          end

          subject { response.body }

          specify { response.code.should == '201' }

          it { should have_xpath("#{xml_root}/active").with_text('true') }
          it { should have_xpath("#{xml_root}/created-at")               }
          it { should have_xpath("#{xml_root}/updated-at")               }
          it { should have_xpath("#{xml_root}/id")                       }

          it 'should have a title' do
            should have_xpath("#{xml_root}/title").with_text('Work It')
          end

          it 'should be active' do
            should have_xpath("#{xml_root}/event").with_text('user_created')
          end

          it 'should have body' do
            should have_xpath("#{xml_root}/body").with_text('Do It')
          end

          it 'should have format' do
            should have_xpath("#{xml_root}/format").with_text('text/plain')
          end

          it 'should have description' do
            should have_xpath("#{xml_root}/description").with_text('Makes Us Harder Better Faster')
          end
        end
      end

      it_behaves_like 'creating request with params that fails validation' do
        let(:param) { {:active => 'invalidate'} }
      end

      it_behaves_like 'creating request with invalid params'
    end

    describe "PUT #{base_url}/[id]" do

      let(:url)          { "#{base_url}/#{@nt.id}?token=#{@user.api_key}" }

      it_behaves_like 'change `active` param'

      it_behaves_like 'editing request with params that fails validation' do
        before(:each) { @nt = create(:notification_template) }

        let(:param) { {:title => ''} }
      end

      it_behaves_like 'editing request with invalid params'
    end

    describe "DELETE #{base_url}/[id]" do

      before :each do
        @notification_template = create(:notification_template)
        NotificationTemplate.stub(:find).with(@notification_template.id).and_return @notification_template
      end

      let(:url) {"#{base_url}/#{@notification_template.id}?token=#{@user.api_key}"}

      mimetypes = ['json', 'xml']
      mimetypes.each do |mimetype|
        it "should be successful using mimetype #{mimetype.upcase}" do
          params_json       = { id: @notification_template.id }.to_json
          params_xml        = create_xml {|xml| xml.id @notification_template.id}
          params            = eval "params_#{mimetype}"
          mimetype_headers  = eval "#{mimetype}_headers"

          delete url, params, mimetype_headers

          response.status.should == 202
          @notification_template.active.should == false
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

  context 'with no existing notification_templates' do
    before :each do
      # make sure there's none of notification_templates
      NotificationTemplate.delete_all
    end

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