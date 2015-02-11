require 'spec_helper'

base_url =  '/v1/categories'
describe "testing #{base_url}" do
  let(:base_url) { base_url }
  let(:json_root) { :category }
  let(:xml_root) { 'category' }

  before(:all) do
    @user         = create(:user)
    @token        = @user.api_key
  end

  let(:token)    { @token }

  context 'with existing categories and valid api key' do
    before(:each)  do
      @plan_member  = create(:plan_member)
    end

    let(:url)     { "#{base_url}?token=#{@token}" }

    describe "GET #{base_url}" do
      before(:each) do
        # categories
        @category_1 = create(:category)
        @category_2 = create(:category, :name => 'cool name')
        @category_3 = create(:category, :name => 'mad name')
        @category_3.toggle_archive
        @category_3.reload

        @unarchived_category_ids = [@category_2.id, @category_1.id]
      end

      context 'JSON' do
        let(:json_root) { 'array:root > object' }

        subject { response.body }

        it 'should return all categories except archived(by default)' do
          jget

          should have_json("#{json_root} > number.id").with_values(@unarchived_category_ids)
        end

        it 'should return all categories except archived' do
          param   = {:filters => {:unarchived => true}}

          jget param

          should have_json("#{json_root} > number.id").with_values(@unarchived_category_ids)
        end

        it 'should return all categories archived' do
          param   = {:filters => {:archived => true}}

          jget param

          should have_json("#{json_root} > number.id").with_values([@category_3.id])
        end

        it 'should return all categories' do
          param   = {:filters => {:archived => true, :unarchived => true}}

          jget param

          should have_json("#{json_root} > number.id").with_values([@category_3.id] + @unarchived_category_ids)
        end

        it 'should return all archieved categories' do
          param   = {:filters => {:archived => true, :unarchived => false}}

          jget param

          should have_json('number.id').with_value(@category_3.id)
        end

        it 'should return category by name' do
          param   = {:filters => {:name => 'cool name'}}

          jget param

          should have_json('number.id').with_value(@category_2.id)
        end

        it 'should not return archived category by name' do
          param   = {:filters => {:name => @category_3.name}}

          jget param

          should == " "
        end

        it 'should return archived category by name if it specified' do
          param   = {:filters => {:name => @category_3.name, :archived => true}}

          jget param

          should have_json('number.id').with_value(@category_3.id)
        end

      end

      context 'XML' do
        let(:xml_root) {'categories/category'}

        subject { response.body }

        it 'should return all categories except archived(by default)' do
          xget

          should have_xpath("#{xml_root}/id").with_texts(@unarchived_category_ids)
        end

        it 'should return all categories archived' do
          param   = {:filters => {:archived => true}}

          xget param

          should have_xpath("#{xml_root}/id").with_texts([@category_3.id])
        end

        it 'should return all categories except archived' do
          param   = {:filters => {:unarchived => true}}

          xget param

          should have_xpath("#{xml_root}/id").with_texts(@unarchived_category_ids)
        end

        it 'should return all categories' do
          param   = {:filters => {:archived => true, :unarchived => true}}

          xget param

          should have_xpath("#{xml_root}/id").with_texts([@category_3.id] + @unarchived_category_ids)
        end

        it 'should return all archieved categories' do
          param   = {:filters => {:archived => true, :unarchived => false}}

          xget param

          should have_xpath("#{xml_root}/id").with_text(@category_3.id)
        end

        it 'should return category by name' do
          param   = {:filters => {:name => 'cool name'}}

          xget param

          should have_xpath("#{xml_root}/id").with_text(@category_2.id)
        end

        it 'should not return archived category by name if that was not specified' do
          param   = {:filters => {:name => @category_3.name}}

          xget param

          should == " "
        end

        it 'should return archived category by name if that was specified' do
          param   = {:filters => {:name => @category_3.name, :archived => true}}

          xget param

          should have_xpath("#{xml_root}/id").with_text(@category_3.id)
        end
      end
    end

    describe "GET #{base_url}/[id]" do
      before(:each) do
        @category_1 = create(:category)
        @category_2 = create(:category)
      end

      context 'JSON' do
        let(:url) {"#{base_url}/#{@category_1.id}?token=#{@user.api_key}"}

        subject { response.body }

        it 'should return category' do
          jget

          should have_json('number.id').with_value(@category_1.id)
        end
      end

      context 'XML' do
        let(:url) {"#{base_url}/#{@category_2.id}?token=#{@user.api_key}"}

        subject { response.body }

        it 'should return category' do
          xget

          should have_xpath('category/id').with_text(@category_2.id)
        end
      end
    end

    describe "POST #{base_url}" do
      let(:_request){ with_current_user @user do
        create(:request, :deployment_coordinator => @user, :requestor => @user, :plan_member => @plan_member)
      end }
      let(:step){ with_current_user @user do
        create(:step)
      end }
      let(:created_category)  { Category.last }

      context 'with valid params' do
        let(:param)             { {:name => 'shakeit',
                                   :categorized_type => 'request',
                                   :associated_events => ['problem', 'resolve', 'cancel'],
                                   :step_ids => [step.id],
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
          it { should have_json('string.updated_at') }

          it 'should create category name' do
            should have_json('string.name').with_value('shakeit')
          end

          it 'should create category with given `categorized_type`' do
            should have_json('string.categorized_type').with_value('request')
          end

          it 'should create category with given `associated_events`' do
            should have_json('array.associated_events').with_value(['problem', 'resolve', 'cancel'])
          end

          it 'should create category with given `request_ids`' do
            should have_json('array.requests number.id').with_value(_request.id)
            created_category.requests.should match_array [_request]
          end

          it 'should create category with given `step_ids`' do
            should have_json('array.steps number.id').with_value(step.id)
            created_category.steps.should match_array [step]
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
          it { should have_xpath("#{xml_root}/updated-at")     }

          it 'should create category name' do
            should have_xpath("#{xml_root}/name").with_text('shakeit')
          end

          it 'should create category with given `categorized_type`' do
            should have_xpath("#{xml_root}/categorized-type").with_text('request')
          end

          it 'should update category with given `associated_events`' do
            should have_xpath("#{xml_root}/associated-events/associated-event").with_texts(['problem', 'resolve', 'cancel'])
          end

          it 'should create category with given `request_ids`' do
            should have_xpath("#{xml_root}/requests/request/id").with_text(_request.id)
            created_category.requests.should match_array [_request]
          end

          it 'should create category with given `step_ids`' do
            should have_xpath("#{xml_root}/steps/step/id").with_text(step.id)
            created_category.steps.should match_array [step]
          end
        end
      end

      it_behaves_like 'creating request with params that fails validation' do
        before(:each) { create(:category, :name => 'already exists') }

        let(:param) { {name: 'already exists'} }
      end

      it_behaves_like 'creating request with invalid params'
    end

    describe "PUT #{base_url}/[id]" do
      before(:each) do
        @category = create(:category)
      end

      let(:_request)          { create(:request, :deployment_coordinator => @user, :requestor => @user, :plan_member => @plan_member) }
      let(:step)              { create(:step) }
      let(:updated_category)  { Category.find(@category.id) }
      let(:url)               {"#{base_url}/#{@category.id}?token=#{@user.api_key}"}

      context 'with valid params' do
        let(:param)             { {:name => 'googleit',
                                   :categorized_type => 'request',
                                   :associated_events => ['problem', 'resolve', 'cancel'],
                                   :step_ids => [step.id],
                                   :request_ids => [_request.id]
        }
        }

        context 'JSON' do
          before :each do
            params    = {json_root => param}.to_json
            @category = create(:category)

            jput params
          end

          subject { response.body }

          specify { response.code.should == '202' }

          it 'should create category name' do
            should have_json('string.name').with_value('googleit')
          end

          it 'should create category with given `categorized_type`' do
            should have_json('string.categorized_type').with_value('request')
          end

          it 'should create category with given `associated_events`' do
            should have_json('array.associated_events').with_value(['problem', 'resolve', 'cancel'])
          end

          it 'should create category with given `request_ids`' do
            should have_json('array.requests number.id').with_value(_request.id)
            updated_category.requests.should match_array [_request]
          end

          it 'should create category with given `step_ids`' do
            should have_json('array.steps number.id').with_value(step.id)
            updated_category.steps.should match_array [step]
          end
        end

        context 'XML' do
          before :each do
            params    = param.to_xml(:root => xml_root)
            @category = create(:category)

            xput params
          end

          subject { response.body }

          specify { response.code.should == '202' }

          it 'should create category name' do
            should have_xpath("#{xml_root}/name").with_text('googleit')
          end

          it 'should create category with given `categorized_type`' do
            should have_xpath("#{xml_root}/categorized-type").with_text('request')
          end

          it 'should update category with given `associated_events`' do
            should have_xpath("#{xml_root}/associated-events/associated-event").with_texts(['problem', 'resolve', 'cancel'])
          end

          it 'should create category with given `request_ids`' do
            should have_xpath("#{xml_root}/requests/request/id").with_text(_request.id)
            updated_category.requests.should match_array [_request]
          end

          it 'should create category with given `step_ids`' do
            should have_xpath("#{xml_root}/steps/step/id").with_text(step.id)
            updated_category.steps.should match_array [step]
          end
        end
      end

      it_behaves_like 'with `toggle_archive` param'

      it_behaves_like 'editing request with params that fails validation' do
        before(:each) { @category = create(:category) }

        let(:param) { {:name => ''} }
      end

      it_behaves_like 'editing request with invalid params'
    end

    describe "DELETE #{base_url}/[id]" do
      before :each do
        @category = create(:category)
      end

      before :each do
        Category.stub(:find).with(@category.id).and_return @category
        @category.should_receive(:try).with(:destroy).and_return true
      end

      let(:url) {"#{base_url}/#{@category.id}?token=#{@user.api_key}"}

      mimetypes = ['json', 'xml']
      mimetypes.each do |mimetype|
        it "should be successful using mimetype #{mimetype.upcase}" do
          params_json       = { id: @category.id }.to_json
          params_xml        = create_xml {|xml| xml.id @category.id}
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

  context 'with no existing categories' do

    methods_urls_for_404 = {
        get:      ["#{base_url}", "#{base_url}/1"],
        put:      ["#{base_url}/1"],
        delete:   ["#{base_url}/1"]
    }

    mimetypes = ['json', 'xml']

    test_batch_of_requests methods_urls_for_404, :response_code => 404, mimetypes: mimetypes
  end
end
