require 'spec_helper'

base_url =  '/v1/properties'
describe "testing #{base_url}" do
  let(:base_url) { base_url }
  let(:json_root) { :property }
  let(:xml_root) { 'property' }

  before :all do
    @user         = create(:user)
    @token        = @user.api_key
  end

  context 'with existing properties and valid api key' do
    before(:each)  do
    end

    let(:url)                    { "#{base_url}?token=#{@token}" }

    describe "GET #{base_url}" do
      before(:each) do
        @app          = create(:app, :name => 'app')
        @server       = create(:server, :name => 'server')
        @component    = create(:component, :name => 'component')
        @package      = create(:package)
        @server_level = create(:server_level, :name => 'server_level')
        @work_task    = create(:work_task, :name => 'work_task')

        @property_1   = create(:property,
                               apps: [@app],
                               servers: [@server],
                               components: [@component],
                               packages: [@package],
                               server_levels: [@server_level]
        )
        @property_2   = create(:property,
                               name: 'Veritas odium paret',
                               apps: [@app],
                               servers: [@server],
                               components: [@component],
                               server_levels: [@server_level],
                               packages: [@package],
                               work_tasks: [@work_task]
        )
        # dunno why this thing isn't created automatically
        create(:property_work_task, :work_task => @work_task, :property => @property_2)

        @property_3   = create(:property,
                               :name => 'mad',
                               :active => false
        )

        @current_property_value = create(:property_value, value: 'current_property_value', property: @property_1, value_holder_id: @component.id, value_holder_type: 'Component')
        @deleted_property_value = create(:property_value, value: 'deleted_property_value', property: @property_2, value_holder_id: @component.id, value_holder_type: 'Component', deleted_at: Time.now)

        @active_property_ids    = [@property_2.id, @property_1.id]
      end

      context 'JSON' do
        let(:json_root) {'array:root > object'}

        subject { response.body }

        it 'should return all properties except inactive(by default)' do
          jget

          should have_json("#{json_root} > number.id").with_values(@active_property_ids)
        end

        it 'should return all properties except inactive' do
          param   = {:filters => {:active => true}}

          jget param

          should have_json("#{json_root} > number.id").with_values(@active_property_ids)
        end

        it 'should return all properties inactive' do
          param   = {:filters => {:inactive => true}}

          jget param

          should have_json("#{json_root} > number.id").with_values([@property_3.id])
        end

        it 'should return all properties' do
          param   = {:filters => {:inactive => true, :active => true}}

          jget param

          should have_json("#{json_root} > number.id").with_values([@property_3.id] + @active_property_ids)
        end

        it 'should return all inactive properties' do
          param   = {:filters => {:inactive => true, :active => false}}

          jget param

          should have_json('number.id').with_value(@property_3.id)
        end

        it 'should return property by name' do
          param   = {:filters => {:name => 'Veritas odium paret'}}

          jget param

          should have_json('number.id').with_value(@property_2.id)
        end

        it 'should not return inactive property by name' do
          param   = {:filters => {:name => 'mad'}}

          jget param

          response.status.should == 404
          should == " "
        end

        it 'should return nothing' do
          param   = {:filters => {:active => false}}

          jget param

          response.status.should == 404
          should == " "
        end

        it 'should return inactive property by name if it is specified' do
          param   = {:filters => {:name => 'mad', :inactive => true}}

          jget param

          should have_json('number.id').with_value(@property_3.id)
        end

        it 'should return properties by current value name' do
          param = {:filters => {:current_value => 'current_property_value'}}

          jget param

          should have_json("#{json_root} > number.id").with_values([@property_1.id])
        end

        it 'should return properties by `name`, `deleted_value`, `app_name`, `server_name`, `component_name`, `server_level_name`, `work_task_name`' do
          param = {:filters => {name: 'Veritas odium paret',
                                deleted_value: 'deleted_property_value',
                                app_name: 'app',
                                server_name: 'server',
                                component_name: 'component',
                                package_name: @package.name,
                                server_level_name: 'server_level',
                                work_task_name: 'work_task'}
          }

          jget param

          should have_json("#{json_root} > number.id").with_values([@property_2.id])
        end
      end

      context 'XML' do
        let(:xml_root) {'properties/property'}

        subject { response.body }

        it 'should return all properties except inactive(by default)' do
          xget

          should have_xpath("#{xml_root}/id").with_texts(@active_property_ids)
        end

        it 'should return all properties except inactive' do
          param   = {:filters => {:active => true}}

          xget param

          should have_xpath("#{xml_root}/id").with_texts(@active_property_ids)
        end

        it 'should return all properties inactive' do
          param   = {:filters => {:inactive => true}}

          xget param

          should have_xpath("#{xml_root}/id").with_texts([@property_3.id])
        end

        it 'should return all properties' do
          param   = {:filters => {:inactive => true, :active => true}}

          xget param

          should have_xpath("#{xml_root}/id").with_texts([@property_3.id] + @active_property_ids)
        end

        it 'should return all inactive properties' do
          param   = {:filters => {:inactive => true, :active => false}}

          xget param

          should have_xpath("#{xml_root}/id").with_text(@property_3.id)
        end

        it 'should return property by name' do
          param   = {:filters => {:name => 'Veritas odium paret'}}

          xget param

          should have_xpath("#{xml_root}/id").with_text(@property_2.id)
        end

        it 'should not return inactive property by name if that was not specified' do
          param   = {:filters => {:name => 'mad'}}

          xget param

          response.status.should == 404
        end

        it 'should return nothing' do
          param   = {:filters => {:active => false}}

          xget param

          response.status.should == 404
        end

        it 'should return inactive property by name if it is specified' do
          param   = {:filters => {:name => 'mad', :inactive => true}}

          xget param

          should have_xpath("#{xml_root}/id").with_text(@property_3.id)
        end

        it 'should return properties by current value name' do
          param = {:filters => {:current_value => 'current_property_value'}}

          xget param

          should have_xpath("#{xml_root}/id").with_text(@property_1.id)
        end

        it 'should return properties by `name`, `deleted_value`, `app_name`, `server_name`, `component_name`, `server_level_name`, `work_task_name`' do
          param = {:filters => {name:'Veritas odium paret',
                                deleted_value: 'deleted_property_value',
                                app_name: 'app',
                                server_name: 'server',
                                component_name: 'component',
                                package_name: @package.name,
                                server_level_name: 'server_level',
                                work_task_name: 'work_task'}
          }

          xget param

          should have_xpath("#{xml_root}/id").with_text(@property_2.id)
        end
      end
    end

    describe "GET #{base_url}/[id]" do
      before(:each) do
        @property_1 = create(:property)
        @property_2 = create(:property)
      end

      context 'JSON' do
        let(:url) {"#{base_url}/#{@property_1.id}?token=#{@token}"}

        subject { response.body }

        it 'should return property' do
          jget

          should have_json('number.id').with_value(@property_1.id)
        end
      end

      context 'XML' do
        let(:url) {"#{base_url}/#{@property_2.id}?token=#{@token}"}

        subject { response.body }

        it 'should return property' do
          xget

          should have_xpath('property/id').with_text(@property_2.id)
        end
      end
    end

    describe "POST #{base_url}" do
      before :each do
        @app          = create(:app)
        @component    = create(:component)
        @package      = create(:package)
        @server       = create(:server)
        @server_level = create(:server_level)
        @work_task    = create(:work_task)
      end

      let(:url) {"#{base_url}?token=#{@token}"}

      let(:default_value) { "c:\\jruby-1.7.1\\bin" }
      let(:is_private) { false }
      let(:app_ids) { [@app.id] }
      let(:component_ids) { [@component.id] }
      let(:package_ids) { [@package.id] }
      let(:server_ids) { [@server.id] }
      let(:server_level_ids) { [@server_level.id] }
      let(:work_task_ids) { [@work_task.id] }

      it_behaves_like "successful request", type: :json, method: :post, status: 201 do
        let(:name) { "json_Property" }
        let(:params) { { json_root => { name: name,
                                        default_value: default_value,
                                        is_private: is_private,
                                        app_ids: app_ids,
                                        component_ids: component_ids,
                                        package_ids: package_ids,
                                        server_ids: server_ids,
                                        server_level_ids: server_level_ids,
                                        work_task_ids: work_task_ids } }.to_json }

        let(:added_property) { Property.where(name: name).first }

        subject { response.body }
        it { should have_json('number.id').with_value(added_property.id) }
        it { should have_json('string.name').with_value(added_property.name) }
        it { should have_json('array.packages > object > string.name').with_value(@package.name) }
        it { should have_json('string.default_value').with_value(added_property.default_value) }
        it { should have_json('boolean.is_private').with_value(added_property.is_private) }
        it { should have_json('boolean.active').with_value(true) }
      end

      it_behaves_like "successful request", type: :xml, method: :post, status: 201 do
        let(:name) { "xml_Property" }
        let(:params) { { name: name,
                         default_value: default_value,
                         is_private: is_private,
                         app_ids: app_ids,
                         component_ids: component_ids,
                         package_ids: package_ids,
                         server_ids: server_ids,
                         server_level_ids: server_level_ids,
                         work_task_ids: work_task_ids }.to_xml(root: xml_root) }

        let(:added_property) { Property.where(name: name).first }

        subject { response.body }
        it { should have_xpath('property/id').with_text(added_property.id) }
        it { should have_xpath('property/name').with_text(added_property.name) }
        it { should have_xpath('property/default-value').with_text(added_property.default_value) }
        it { should have_xpath('property/is-private').with_text(added_property.is_private) }
        it { should have_xpath('property/packages/package/name').with_text(@package.name) }
        it { should have_xpath('property/active').with_text('true') }
      end

      it_behaves_like 'creating request with params that fails validation' do
        before (:each) { @post_property = create(:property) }

        let(:param) { {:name => @post_property.name } }
      end

      it_behaves_like 'creating request with invalid params'
    end

    describe "PUT #{base_url}/[id]" do
      before :each do
        @property = create(:property)
        @app          = create(:app)
        @component    = create(:component)
        @package      = create(:package)
        @server       = create(:server)
        @server_level = create(:server_level)
        @work_task    = create(:work_task)
      end

      let(:url) {"#{base_url}/#{@property.id}?token=#{@token}"}

      let(:default_value) { "c:\\jruby-1.7.1\\bin" }
      let(:is_private) { false }
      let(:app_ids) { [@app.id] }
      let(:component_ids) { [@component.id] }
      let(:package_ids) { [@package.id] }
      let(:server_ids) { [@server.id] }
      let(:server_level_ids) { [@server_level.id] }
      let(:work_task_ids) { [@work_task.id] }

      it_behaves_like "successful request", type: :json, method: :put, status: 202 do
        let(:name) { "new_xml_Property" }
        let(:params) { { json_root => { name: name,
                                        default_value: default_value,
                                        is_private: is_private,
                                        app_ids: app_ids,
                                        component_ids: component_ids,
                                        package_ids: package_ids,
                                        server_ids: server_ids,
                                        server_level_ids: server_level_ids,
                                        work_task_ids: work_task_ids } }.to_json }

        let(:updated_property) { Property.where(name: name).first }

        subject { response.body }
        it { should have_json('number.id').with_value(updated_property.id) }
        it { should have_json('string.name').with_value(updated_property.name) }
        it { should have_json('string.default_value').with_value(updated_property.default_value) }
        it { should have_json('boolean.is_private').with_value(updated_property.is_private) }
        it { should have_json('array.packages > object > string.name').with_value(@package.name) }
      end

      it_behaves_like "successful request", type: :xml, method: :put, status: 202 do
        let(:name) { "new_json_Property" }
        let(:params) { { name: name,
                         default_value: default_value,
                         is_private: is_private,
                         app_ids: app_ids,
                         component_ids: component_ids,
                         package_ids: package_ids,
                         server_ids: server_ids,
                         server_level_ids: server_level_ids,
                         work_task_ids: work_task_ids }.to_xml(root: xml_root) }

        let(:updated_property) { Property.where(name: name).first }

        subject { response.body }
        it { should have_xpath('property/id').with_text(updated_property.id) }
        it { should have_xpath('property/name').with_text(updated_property.name) }
        it { should have_xpath('property/default-value').with_text(updated_property.default_value) }
        it { should have_xpath('property/is-private').with_text(updated_property.is_private) }
        it { should have_xpath('property/packages/package/name').with_text(@package.name) }
      end

      context "rest with no properties" do
        it_behaves_like "successful request", type: :xml, method: :put, status: 202 do
          let(:name) { "new_json_Property" }
          let(:params) { { name: name,
                           default_value: default_value,
                           is_private: is_private,
                           app_ids: app_ids,
                           component_ids: component_ids,
                           package_ids: [],
                           server_ids: server_ids,
                           server_level_ids: server_level_ids,
                           work_task_ids: work_task_ids }.to_xml(root: xml_root) }

          let(:updated_property) { Property.where(name: name).first }

          subject { response.body }
          it { should have_xpath('property/id').with_text(updated_property.id) }
          it { should have_xpath('property/name').with_text(updated_property.name) }
          it { should have_xpath('property/default-value').with_text(updated_property.default_value) }
          it { should have_xpath('property/is-private').with_text(updated_property.is_private) }
          it { should have_xpath('property/packages') }
          it { should_not have_xpath('property/packages/package/name').with_text(@package.name) }
        end
      end

      it_behaves_like 'change `active` param'

      it_behaves_like 'editing request with params that fails validation' do
        before :each do
          create(:property)
          @put_property = create(:property)
        end

        let(:url) {"#{base_url}/#{@put_property.id}?token=#{@token}"}
        let(:param) { { :name => Property.first.name } }
      end

      it_behaves_like 'editing request with invalid params'

    end

    describe "DELETE #{base_url}/[id]" do

      before :each do
        @property = create(:property)
      end

      let(:deactivated_property) { Property.find(@property.id) }
      let(:url) {"#{base_url}/#{@property.id}?token=#{@token}"}

      mimetypes = ['json', 'xml']
      mimetypes.each do |mimetype|
        it "should be successful using mimetype #{mimetype.upcase}" do
          params_json       = { id: @property.id }.to_json
          params_xml        = create_xml {|xml| xml.id @property.id}
          params            = eval "params_#{mimetype}"
          mimetype_headers  = eval "#{mimetype}_headers"

          delete url, params, mimetype_headers

          response.status.should == 202
          deactivated_property.active.should == false
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

  context 'with no existing properties' do

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
