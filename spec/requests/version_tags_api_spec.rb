require 'spec_helper'

base_url =  '/v1/version_tags'
describe "testing #{base_url}" do
  let(:base_url) { base_url }
  let(:json_root) { :version_tag }
  let(:xml_root) { 'version-tag' }

  before(:all) do
    @root_group = create(:group, root: true)
    @user       = create(:user, groups: [@root_group])
    @token      = @user.api_key
  end

  context 'with existing version_tags and valid api key' do
    before(:each) do
      @ic           = create(:installed_component)

      @environment  = create(:environment, :name => 'env')
      @app          = create(:app, :name => 'app')
      @ae           = create(:application_environment, :app => @app, :environment => @environment, :installed_components => [@ic])

      @ac           = create(:application_component, :installed_components => [@ic])
      @component    = create(:component, :name => 'comp', :apps => [@app], :application_components => [@ac])
    end

    let(:url)     { "#{base_url}?token=#{@token}" }

    describe "GET #{base_url}" do
      before(:each) do
        @vt_1 = create(:version_tag, :app => @app, :application_environment => @ae, :installed_component => @ic)
        @vt_2 = create(:version_tag, :name => 'Usus magister est optimus', :app => @app, :application_environment => @ae, :installed_component => @ic)
        @vt_3 = create(:version_tag, :name => 'mad name')
        @vt_3.toggle_archive
        @vt_3.reload

        @unarchived_vt_ids = [@vt_2.id, @vt_1.id]
      end

      context 'JSON' do
        let(:json_root) {'array:root > object'}
        subject { response.body }

        it 'should return all version_tags except archived(by default)' do
          jget

          should have_json("#{json_root} > number.id").with_values(@unarchived_vt_ids)
        end

        it 'should return version_tag by name' do
          param   = {:filters => {:name => 'Usus magister est optimus'}}

          jget param

          should have_json("#{json_root} > number.id").with_value(@vt_2.id)
        end

        it 'should return version_tag by `app_name`' do
          param   = {:filters => {:app_name => 'app',
                                  :component_name => 'comp',
                                  :environment_name => 'env'}
          }

          jget param

          should have_json("#{json_root} > number.id").with_values(@unarchived_vt_ids)
        end

        it 'should not return archived version tag by name' do
          param   = {:filters => {:name => @vt_3.name}}

          jget param

          should == " "
        end

        it 'should return archived version tag by name if it is specified' do
          param   = {:filters => {:name => @vt_3.name, :archived => true}}

          jget param

          should have_json("#{json_root} > number.id").with_value(@vt_3.id)
        end
      end

      context 'XML' do
        let(:xml_root) {'version-tags/version-tag'}

        subject { response.body }

        it 'should return all version_tags except archived' do
          xget

          should have_xpath("#{xml_root}/id").with_texts(@unarchived_vt_ids)
        end

        it 'should return version_tag by name' do
          param   = {:filters => {:name => 'Usus magister est optimus'}}

          xget param

          should have_xpath("#{xml_root}/id").with_text(@vt_2.id)
        end

        it 'should return version_tag by `app_name`' do
          param   = {:filters => {:app_name => 'app',
                                  :component_name => 'comp',
                                  :environment_name => 'env'}
          }

          xget param

          should have_xpath("#{xml_root}/id").with_texts(@unarchived_vt_ids)
        end

        it 'should not return archived version tag by name' do
          param   = {:filters => {:name => @vt_3.name}}

          xget param

          should == " "
        end

        it 'should return archived version tag by name if it is specified' do
          param   = {:filters => {:name => @vt_3.name, :archived => true}}

          xget param

          should have_xpath("#{xml_root}/id").with_text(@vt_3.id)
        end
      end
    end

    describe "GET #{base_url}/[id]" do
      before(:each) do
        @vt_1 = create(:version_tag)
        @vt_2 = create(:version_tag)
      end

      context 'JSON' do
        let(:url) {"#{base_url}/#{@vt_1.id}?token=#{@token}"}

        subject { response.body }

        it 'should return version_tag' do
          jget

          should have_json('number.id').with_value(@vt_1.id)
        end
      end

      context 'XML' do
        let(:url) {"#{base_url}/#{@vt_2.id}?token=#{@token}"}

        subject { response.body }

        it 'should return version-tag' do
          xget

          should have_xpath('version-tag/id').with_text(@vt_2.id)
        end
      end
    end

    describe "POST #{base_url}" do
      before :each do
        @ic             = create(:installed_component)
        @environment    = create(:environment, :name => 'name_env')
        @app            = create(:app, :name => 'name_app')
        @ae             = create(:application_environment, :app => @app, :environment => @environment, :installed_components => [@ic])
        @ac             = create(:application_component, :installed_components => [@ic])
        @component      = create(:component, :name => 'name_comp', :apps => [@app], :application_components => [@ac])
        @property1      = create(:property, :name => 'property_name1')
        @property2      = create(:property, :name => 'property_name2')
        @property_name3 = 'property_name3'
      end

      let(:url) {"#{base_url}?token=#{@token}"}
      let(:app_id) { @app.id }
      let(:artifact_url) { "http://artifact.url" }
      let(:app_env_id) { @ae.id }
      let(:installed_component_id) { @ic.id }
      let(:property_name1) {@property1.name}
      let(:property_name2) {@property2.name}
      let(:property_name3) {@property_name3}
      let(:property_value1){'property_value1'}
      let(:property_value2){'property_value2'}
      let(:property_value3){'property_value3'}

      it_behaves_like "successful request", type: :json, method: :post, status: 201 do
        let(:name) { "json_VersionTag"  }
        let(:params) { { json_root => { name: name,
                                        app_id: app_id,
                                        artifact_url: artifact_url,
                                        app_env_id: app_env_id,
                                        installed_component_id: installed_component_id,
                                        properties: [
                                         {name: property_name1, value: property_value1 },
                                         {name: property_name2, value: property_value2 },
                                         {name: property_name3, value: property_value3 }
                                        ],
                                        find_component: @component.name }
                        }.to_json
        }
        let(:added_version_tag) { VersionTag.where(name: name).first }

        subject { response.body }
        it { should have_json('number.id').with_value(added_version_tag.id) }
        it { should have_json('string.name').with_value(added_version_tag.name) }
        it { should have_json('number.app_id').with_value(added_version_tag.app_id) }
        it { should have_json('string.artifact_url').with_value(added_version_tag.artifact_url) }
        it { should have_json('number.installed_component_id').with_value(added_version_tag.installed_component_id) }
        it { should have_json('*.archive_number') }
        it { should have_json('*.archived_at') }
        it { should have_json('.assigned_properties_hashes').with_value([{'name' => property_name1, 'value' => property_value1}, {'name' => property_name2, 'value' => property_value2}, {'name' => property_name3, 'value' => property_value3}]) }
        it { should have_json('.assigned_properties_hashes string.value').with_values([property_value1, property_value2, property_value3]) }
        it { should have_json('.assigned_properties_hashes string.name').with_values([property_name1, property_name2, property_name3]) }
      end

      it_behaves_like "successful request", type: :xml, method: :post, status: 201 do
        let(:name) { "xml_VersionTag"  }
        let(:params) { { name: name,
                         app_id: app_id,
                         artifact_url: artifact_url,
                         app_env_id: app_env_id,
                         installed_component_id: installed_component_id,
                         properties: [
                           {name: property_name1, value: 'property_value1' },
                           {name: property_name2, value: 'property_value2' },
                           {name: property_name3, value: 'property_value3' }
                         ],
                         find_component: @component.name
                        }.to_xml(root: xml_root)
        }

        let(:added_version_tag) { VersionTag.where(name: name).first }

        subject { response.body }
        it { should have_xpath('version-tag/id').with_text(added_version_tag.id) }
        it { should have_xpath('version-tag/name').with_text(added_version_tag.name) }
        it { should have_xpath('version-tag/app-id').with_text(added_version_tag.app_id) }
        it { should have_xpath('version-tag/artifact-url').with_text(added_version_tag.artifact_url) }
        it { should have_xpath('version-tag/installed-component-id').with_text(added_version_tag.installed_component_id) }
        it { should have_xpath('version-tag/archive-number') }
        it { should have_xpath('version-tag/archived-at') }
        it { should have_xpath('version-tag/assigned-properties-hashes/assigned-properties-hash/value').with_texts([property_value1, property_value2, property_value3]) }
        it { should have_xpath('version-tag/assigned-properties-hashes/assigned-properties-hash/name').with_texts([property_name1, property_name2, property_name3]) }
      end

      it_behaves_like 'creating request with params that fails validation' do
        let(:param) { { :app_id => nil, :app_env_id => nil } }
      end

      it_behaves_like 'creating request with invalid params'
    end

    describe "PUT #{base_url}/[id]" do
      before :each do
        @ic  = create(:installed_component)
        @environment  = create(:environment, :name => 'put_name_env')
        @app  = create(:app, :name => 'put_name_app')
        @ae = create(:application_environment, :app => @app, :environment => @environment, :installed_components => [@ic])
        @ac  = create(:application_component, :installed_components => [@ic])
        @component  = create(:component, :name => 'put_name_comp', :apps => [@app], :application_components => [@ac])
        @version_tag_put = create(:version_tag)
        @properties = []
        @property_values = []
        [1,2].each do |index|
          @properties << create(:property, :name => "property_name#{index}")
          @property_values << create(:property_value, :value_holder_id => @version_tag_put.id, :value_holder_type => @version_tag_put.class.to_s, :value => "property_value#{index}", :property => @properties.last)
        end
      end

      let(:url) {"#{base_url}/#{@version_tag_put.id}?token=#{@token}"}
      let(:app_id) { @app.id }
      let(:artifact_url) { "http://artifact.url" }
      let(:app_env_id) { @ae.id }
      let(:installed_component_id) { @ic.id }
      let(:property_name1) {@properties[0].name}
      let(:property_name2) {@properties[1].name}
      let(:property_value1) {@property_values[0].value}
      let(:property_value2) {@property_values[1].value}
      let(:new_property_value2) {'new_property_value2'}
      let(:property_name3) {'property_name3'}
      let(:property_value3) {'property_value3'}

      it_behaves_like "successful request", type: :json, method: :put, status: 202 do
        let(:name) { "new_json_VersionTag"  }
        let(:params) { { json_root => { name: name,
                                        app_id: app_id,
                                        artifact_url: artifact_url,
                                        app_env_id: app_env_id,
                                        installed_component_id: installed_component_id,
                                        properties: [
                                          {name: property_name1, value: property_value1 },
                                          {name: property_name2, value: new_property_value2 },
                                          {name: property_name3, value: property_value3 }
                                        ],
                                        find_component: @component.name } }.to_json }
        let(:updated_version_tag) { VersionTag.where(name: name).first }

        subject { response.body }
        it { should have_json('number.id').with_value(updated_version_tag.id) }
        it { should have_json('string.name').with_value(updated_version_tag.name) }
        it { should have_json('number.app_id').with_value(updated_version_tag.app_id) }
        it { should have_json('string.artifact_url').with_value(updated_version_tag.artifact_url) }
        it { should have_json('number.installed_component_id').with_value(updated_version_tag.installed_component_id) }
        it { should have_json('*.archive_number') }
        it { should have_json('*.archived_at') }
        it {
          pending 'This is fantom test'
          should have_json('.assigned_properties_hashes').with_value([{'name' => property_name3, 'value' => property_value3}, {'name' => property_name2, 'value' => new_property_value2}, {'name' => property_name1, 'value' => property_value1}])
        }
        it { should have_json('.assigned_properties_hashes string.value').with_values([property_value1, new_property_value2, property_value3]) }
        it { should have_json('.assigned_properties_hashes string.name').with_values([property_name1, property_name2, property_name3]) }
      end

      it_behaves_like "successful request", type: :xml, method: :put, status: 202 do
        let(:name) { "new_xml_VersionTag"  }
        let(:params) { { name: name,
                         app_id: app_id,
                         artifact_url: artifact_url,
                         app_env_id: app_env_id,
                         installed_component_id: installed_component_id,
                         properties: [
                             {name: property_name1, value: property_value1 },
                             {name: property_name2, value: new_property_value2 },
                             {name: property_name3, value: property_value3 }
                         ],
                         find_component: @component.name }.to_xml(root: xml_root) }

        let(:updated_version_tag) { VersionTag.where(name: name).first }

        subject { response.body }
        it { should have_xpath('version-tag/id').with_text(updated_version_tag.id) }
        it { should have_xpath('version-tag/name').with_text(updated_version_tag.name) }
        it { should have_xpath('version-tag/app-id').with_text(updated_version_tag.app_id) }
        it { should have_xpath('version-tag/artifact-url').with_text(updated_version_tag.artifact_url) }
        it { should have_xpath('version-tag/installed-component-id').with_text(updated_version_tag.installed_component_id) }
        it { should have_xpath('version-tag/archive-number') }
        it { should have_xpath('version-tag/archived-at') }
        it { should have_xpath('version-tag/assigned-properties-hashes/assigned-properties-hash/value').with_texts([property_value1, new_property_value2, property_value3]) }
        it { should have_xpath('version-tag/assigned-properties-hashes/assigned-properties-hash/name').with_texts([property_name1, property_name2, property_name3]) }
      end

      it_behaves_like 'editing request with params that fails validation' do
        let(:param) { { :app_id => nil, :app_env_id => nil } }
      end

      it_behaves_like 'editing request with invalid params'
    end

    describe "DELETE #{base_url}/[id]" do
      before :each do
        @version_tag = create(:version_tag)
        VersionTag.stub(:find).with(@version_tag.id).and_return @version_tag
        @version_tag.should_receive(:try).with(:archive).and_return true
      end

      let(:url) {"#{base_url}/#{@version_tag.id}?token=#{@token}"}

      mimetypes = ['json', 'xml']
      mimetypes.each do |mimetype|
        it "should be successful using mimetype #{mimetype.upcase}" do
          params_json       = { id: @version_tag.id }.to_json
          params_xml        = create_xml {|xml| xml.id @version_tag.id}
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

  context 'with no existing version_tags' do

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
