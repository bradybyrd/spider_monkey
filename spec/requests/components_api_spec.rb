require 'spec_helper'

base_url =  '/v1/components'
describe "testing #{base_url}" do
  let(:base_url) { base_url }
  let(:json_root) { :component }
  let(:xml_root) { 'component' }

  before :all do
    @user         = create(:user)
    @token        = @user.api_key
  end

  context 'with existing components and valid api key' do
    before(:each)  do
      @app_1         = create(:app, :name => 'AHNE_|_Absens haeres non erit.')
      @app_2         = create(:app)
      @property_1    = create(:property, :name => 'prettyproperty')
      @property_2    = create(:property)
    end

    let(:url)     { "#{base_url}?token=#{@token}" }

    #name - string value of the component name
    #app_name - string value of the application name associated with a component
    #property_name - string value of a property name associated with a component
    describe "GET #{base_url}" do
      before(:each) do
        Component.delete_all

        @component_1 = create(:component, :name => 'gugl name', :apps => [@app_1], :properties => [@property_1])
        @component_2 = create(:component, :name => 'cool name', :apps => [@app_1])
        @component_3 = create(:component, :properties => [@property_1])
        @component_4 = create(:component, :name => 'mad name')
        @component_3.deactivate!
        @component_4.deactivate!

        @active_component_ids = [@component_2.id, @component_1.id]
      end

      context 'JSON' do
        let(:json_root) { 'array:root > object' }

        subject { response.body }

        it 'should return all components except inactive' do
          jget

          should have_json("#{json_root} > number.id").with_values(@active_component_ids)
        end

        it 'should return components by name' do
          param   = {:filters => {:name => 'cool name'}}

          jget param

          should have_json("#{json_root} > number.id").with_value(@component_2.id)
        end

        it 'should return components by app_name' do
          param   = {:filters => {:app_name => 'AHNE'}}

          jget param

          should have_json("#{json_root} > number.id").with_values(@active_component_ids)
        end

        it 'should return components by property_name' do
          param   = {:filters => {:property_name => 'prettyproperty'}}

          jget param

          should have_json("#{json_root} > number.id").with_value(@component_1.id)
        end

        it 'should return components by app_name and property_name' do
          param   = {:filters => {:app_name => 'AHNE', :property_name => 'prettyproperty'}}

          jget param

          should have_json("#{json_root} > number.id").with_value(@component_1.id)
        end

        it 'should return components by name and app_name' do
          param   = {:filters => {:name => 'cool name', :app_name => 'AHNE'}}

          jget param

          should have_json('number.id').with_value(@component_2.id)
        end

        it 'should return components by name and property_name' do
          param   = {:filters => {:name => 'gugl name', :property_name => 'prettyproperty'}}

          jget param

          should have_json('number.id').with_value(@component_1.id)
        end

        it 'should return components by name and app_name, and property_name' do
          param   = {:filters => {:name => 'gugl name', :app_name => 'AHNE', :property_name => 'prettyproperty'}}

          jget param

          should have_json('number.id').with_value(@component_1.id)
        end

        it 'should not return inactive component type by name' do
          param   = {:filters => {:name => 'mad name'}}

          jget param

          should == " "
        end

        it 'should return inactive component type by name if it is specified' do
          param   = {:filters => {:name => 'mad name', :inactive => true}}

          jget param

          should have_json('number.id').with_value(@component_4.id)
        end
      end

      context 'XML' do
        let(:xml_root) {'components/component'}

        subject { response.body }

        it 'should return all components except unactive' do
          xget

          should have_xpath("#{xml_root}/id").with_texts(@active_component_ids)
        end

        it 'should return components by name' do
          param   = {:filters => {:name => 'cool name'}}

          xget param

          should have_xpath("#{xml_root}/id").with_text(@component_2.id)
        end

        it 'should return components by app_name' do
          param   = {:filters => {:app_name => 'AHNE'}}

          xget param

          should have_xpath("#{xml_root}/id").with_texts(@active_component_ids)
        end

        it 'should return components by property_name' do
          param   = {:filters => {:property_name => 'prettyproperty'}}

          xget param

          should have_xpath("#{xml_root}/id").with_text(@component_1.id)
        end

        it 'should return components by app_name and property_name' do
          param   = {:filters => {:app_name => 'AHNE', :property_name => 'prettyproperty'}}

          xget param

          should have_xpath("#{xml_root}/id").with_text(@component_1.id)
        end

        it 'should return components by name and app_name' do
          param   = {:filters => {:name => 'cool name', :app_name => 'AHNE'}}

          xget param

          should have_xpath("#{xml_root}/id").with_text(@component_2.id)
        end

        it 'should return components by name and property_name' do
          param   = {:filters => {:name => 'gugl name', :property_name => 'prettyproperty'}}

          xget param

          should have_xpath("#{xml_root}/id").with_text(@component_1.id)
        end

        it 'should return components by name and app_name, and property_name' do
          param   = {:filters => {:name => 'gugl name', :app_name => 'AHNE', :property_name => 'prettyproperty'}}

          xget param

          should have_xpath("#{xml_root}/id").with_text(@component_1.id)
        end

        it 'should not return inactive component by name' do
          param   = {:filters => {:name => 'mad name'}}

          xget param

          should == " "
        end

        it 'should return inactive component by name if it is specified' do
          param   = {:filters => {:name => 'mad name', :inactive => true}}

          xget param

          should have_xpath("#{xml_root}/id").with_text(@component_4.id)
        end
      end
    end

    describe "GET #{base_url}/[id]" do
      before(:each) do
        @component_1 = create(:component)
        @component_2 = create(:component)
      end

      context 'JSON' do
        let(:url) {"#{base_url}/#{@component_1.id}?token=#{@token}"}

        subject { response.body }

        it 'should return component' do
          jget

          should have_json('number.id').with_value(@component_1.id)
        end
      end

      context 'XML' do
        let(:url) {"#{base_url}/#{@component_2.id}?token=#{@token}"}

        subject { response.body }

        it 'should return component' do
          xget

          should have_xpath('component/id').with_text(@component_2.id)
        end
      end
    end

    describe "POST #{base_url}" do
      let(:created_component) { Component.last }

      context 'with valid params' do
        let(:param)             { {:name => 'mortalcombat',
                                   :app_name => [@app_1.name, @app_2.name],
                                   :property_name => @property_1.name
        }
        }

        context 'JSON' do
          before :each do
            params    = {json_root => param}.to_json

            jpost params
          end

          subject { response.body }

          specify { response.code.should == '201' }

          it { should have_json('array.installed_components')  }
          it { should have_json('array.apps')  }
          it { should have_json('number.id')         }

          it 'should create component with name' do
            should have_json('string.name').with_value('mortalcombat')
          end

          it 'should create component with active' do
            should have_json('boolean.active').with_value(true)
          end

          it 'should create component with given `app_name`' do
            should have_json('array.apps number.id').with_values([@app_1.id, @app_2.id])
            created_component.apps.order("apps.id ASC").should match_array [@app_1, @app_2]
          end

          it 'should create component with given `property_name`' do
            should have_json('array.properties number.id').with_value(@property_1.id)
            created_component.properties.should match_array [@property_1]
          end
        end

        context 'XML' do
          before :each do
            params    = param.to_xml(:root => xml_root)

            xpost params
          end

          subject { response.body }

          specify { response.code.should == '201' }

          it { should have_xpath("#{xml_root}/installed-components") }
          it { should have_xpath("#{xml_root}/apps")    }
          it { should have_xpath("#{xml_root}/id")             }

          it 'should create component with name' do
            should have_xpath("#{xml_root}/name").with_text('mortalcombat')
          end

          it 'should create component with active' do
            should have_xpath("#{xml_root}/active").with_text('true')
          end

          it 'should create component with given `app_name`' do
            should have_xpath("#{xml_root}/apps/app/id").with_texts([@app_1.id, @app_2.id])
            created_component.apps.order("apps.id ASC").should match_array [@app_1, @app_2]
          end

          it 'should create component with given `property_name`' do
            should have_xpath("#{xml_root}/properties/property/id").with_text(@property_1.id)
            created_component.properties.should match_array [@property_1]
          end
        end
      end

      it_behaves_like 'creating request with params that fails validation' do
        before(:each) { create(:component, :name => 'already exists') }

        let(:param) { {:name => 'already exists'} }
      end

      it_behaves_like 'creating request with invalid params'
    end

    describe "PUT #{base_url}/[id]" do
      let(:updated_component) { Component.find(@component.id) }
      let(:url)               {"#{base_url}/#{@component.id}?token=#{@token}"}

      context 'with valid params' do
        let(:param)             { {:name => 'switchback',
                                   :app_name => @app_1.name,
                                   :property_name => [@property_1.name, @property_2.name]
        }
        }

        context 'JSON' do
          before :each do
            params     = {json_root => param}.to_json
            @component = create(:component)

            jput params
          end

          subject { response.body }

          specify { response.code.should == '202' }

          it 'should update component with name' do
            should have_json('string.name').with_value('switchback')
          end

          it 'should update component with active' do
            should have_json('boolean.active').with_value(true)
          end

          it 'should update component with given `app_name`' do
            should have_json('array.apps number.id').with_value(@app_1.id)
            updated_component.apps.should match_array [@app_1]
          end

          it 'should update component with given `property_name`' do
            should have_json('array.properties number.id').with_values([@property_1.id, @property_2.id])
            updated_component.properties.should match_array([@property_1, @property_2])
          end
        end

        context 'XML' do
          before :each do
            params     = param.to_xml(:root => xml_root)
            @component = create(:component)

            xput params
          end

          subject { response.body }

          specify { response.code.should == '202' }

          it 'should update component with name' do
            should have_xpath("#{xml_root}/name").with_text('switchback')
          end

          it 'should update component with active' do
            should have_xpath("#{xml_root}/active").with_text('true')
          end

          it 'should update component with given `app_name`' do
            should have_xpath("#{xml_root}/apps/app/id").with_text(@app_1.id)
            updated_component.apps.should match_array [@app_1]
          end

          it 'should update component with given `property_name`' do
            should have_xpath("#{xml_root}/properties/property/id").with_texts([@property_1.id, @property_2.id])
            updated_component.properties.should match_array([@property_1, @property_2])
          end
        end
      end

      it_behaves_like 'change `active` param'

      it_behaves_like 'editing request with params that fails validation' do
        before(:each) { @component = create(:component) }

        let(:param) { {name: ''} }
      end

      it_behaves_like 'editing request with invalid params'
    end

    describe "DELETE #{base_url}/[id]" do

      before :each do
        @component = create(:component)
        Component.stub(:find).with(@component.id).and_return @component
      end

      let(:unactive_component) { Component.find(@component.id) }
      let(:url) {"#{base_url}/#{@component.id}?token=#{@token}"}

      mimetypes = ['json', 'xml']
      mimetypes.each do |mimetype|
        it "should be successful using mimetype #{mimetype.upcase}" do
          params_json       = { id: @component.id }.to_json
          params_xml        = create_xml {|xml| xml.id @component.id}
          params            = eval "params_#{mimetype}"
          mimetype_headers  = eval "#{mimetype}_headers"

          delete url, params, mimetype_headers

          response.status.should == 202
          unactive_component.active.should == false
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

  context 'with no existing components' do

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