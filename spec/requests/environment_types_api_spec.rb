require 'spec_helper'

base_url =  '/v1/environment_types'
describe "testing #{base_url}" do
  let(:base_url) { base_url }
  let(:json_root) {:environment_type}
  let(:xml_root) {'environment-type'}

  before :all do
    @user         = create(:user)
    @token        = @user.api_key
  end

  context 'with existing environment types and valid api key' do
    before(:each)  do
      @env_1 = create(:environment)
      @env_2 = create(:environment)
      @plan_stage_1 = create(:plan_stage, :environment_type => nil)
      @plan_stage_2 = create(:plan_stage, :environment_type => nil)
    end

    let(:url)     { "#{base_url}?token=#{@token}" }

    describe "GET #{base_url}" do
      before(:each) do
        @env_type_1 = create(:environment_type)
        @env_type_2 = create(:environment_type, :name => 'fire_in_the_hole')
        @env_type_3 = create(:environment_type, :name => 'mad name')
        @env_type_3.archive
        @env_type_3.reload
        @archived_name = @env_type_3.name

        @unarchived_environment_ids = [@env_type_2.id, @env_type_1.id]
      end

      context 'JSON' do
        subject { response.body }

        it 'should return all environment types except archived(by default)' do
          jget

          should have_json('number.id').with_values(@unarchived_environment_ids)
        end

        it 'should return all environment types except archived' do
          param   = {:filters => {:unarchived => true}}

          jget param

          should have_json('number.id').with_values(@unarchived_environment_ids)
        end

        it 'should return all environment types archived' do
          param   = {:filters => {:archived => true}}

          jget param

          should have_json('number.id').with_values([@env_type_3.id])
        end

        it 'should return all environment types' do
          param   = {:filters => {:archived => true, :unarchived => true}}

          jget param

          should have_json('number.id').with_values([@env_type_3.id] + @unarchived_environment_ids)
        end

        it 'should return all archived environment types' do
          param   = {:filters => {:archived => true, :unarchived => false}}

          jget param

          should have_json('number.id').with_value(@env_type_3.id)
        end

        it 'should return environment type by name' do
          param   = {:filters => {:name => 'fire_in_the_hole'}}

          jget param

          should have_json('number.id').with_value(@env_type_2.id)
        end

        it 'should not return archived environment type by name' do
          param   = {:filters => {:name => 'mad name'}}

          jget param

          should == " "
        end

        it 'should return archived environment type by name if it is specified' do
          param   = {:filters => {:name => @archived_name, :archived => true}}

          jget param

          should have_json('number.id').with_value(@env_type_3.id)
        end
      end

      context 'XML' do
        let(:xml_root) {'environment-types/environment-type'}
        subject { response.body }

        it 'should return all environment types except archived(by default)' do
          xget

          should have_xpath("#{xml_root}/id").with_texts(@unarchived_environment_ids)
        end

        it 'should return all environment types except archived' do
          param   = {:filters => {:unarchived => true}}

          xget param

          should have_xpath("#{xml_root}/id").with_texts(@unarchived_environment_ids)
        end

        it 'should return all environment types archived' do
          param   = {:filters => {:archived => true}}

          xget param

          should have_xpath("#{xml_root}/id").with_texts([@env_type_3.id])
        end

        it 'should return all environment types' do
          param   = {:filters => {:archived => true, :unarchived => true}}

          xget param

          should have_xpath("#{xml_root}/id").with_texts([@env_type_3.id] + @unarchived_environment_ids)
        end

        it 'should return all archived environment types' do
          param   = {:filters => {:archived => true, :unarchived => false}}

          xget param

          should have_xpath("#{xml_root}/id").with_text(@env_type_3.id)
        end

        it 'should return environment type by name' do
          param   = {:filters => {:name => 'fire_in_the_hole'}}

          xget param

          should have_xpath("#{xml_root}/id").with_text(@env_type_2.id)
        end

        it 'should not return archived environment type by name if that was not specified' do
          param   = {:filters => {:name => 'mad name'}}

          xget param

          should == " "
        end

        it 'should return archived environment type by name if it is specified' do
          param   = {:filters => {:name => @archived_name, :archived => true}}

          xget param

          should have_xpath("#{xml_root}/id").with_text(@env_type_3.id)
        end
      end
    end

    describe "GET #{base_url}/[id]" do
      before(:each) do
        @environment_type_1 = create(:environment_type)
        @environment_type_2 = create(:environment_type)
      end

      context 'JSON' do
        let(:url) {"#{base_url}/#{@environment_type_1.id}?token=#{@user.api_key}"}

        subject { response.body }

        it 'should return environment type' do
          jget

          should have_json('number.id').with_value(@environment_type_1.id)
        end
      end

      context 'XML' do
        let(:url) {"#{base_url}/#{@environment_type_2.id}?token=#{@user.api_key}"}

        subject { response.body }

        it 'should return environment type' do
          xget

          should have_xpath('environment-type/id').with_text(@environment_type_2.id)
        end
      end
    end

    describe "POST #{base_url}" do

      let(:created_environment_type) { EnvironmentType.last }

      context 'with valid params' do
        let(:param)             { {:name => 'New Environment Type',
                                   :description => 'New Environment Type description',
                                   :strict => true,
                                   :label_color => '#C0C0C0',
                                   :environment_ids => [@env_1.id, @env_2.id],
                                   :plan_stage_ids => [@plan_stage_1.id, @plan_stage_2.id]
        }
        }

        context 'JSON' do
          before :each do
            params = {json_root => param}.to_json

            jpost params
          end

          subject { response.body }

          specify { response.code.should == '201' }

          it { should have_json('*.archive_number')  }
          it { should have_json('*.archived_at')     }
          it { should have_json('string.created_at') }
          it { should have_json('string.updated_at') }
          it { should have_json('number.id')         }
          it { should have_json('number.position')   }

          it 'should create environment type with name' do
            should have_json('string.name').with_value('New Environment Type')
          end

          it 'should create environment type with description' do
            should have_json('string.description').with_value('New Environment Type description')
          end

          it 'should create environment type with strict' do
            should have_json('boolean.strict').with_value(true)
          end

          it 'should create environment type with label_color' do
            should have_json('string.label_color').with_value('#C0C0C0')
          end

          it 'should create environment type with given `environment_ids`' do
            should have_json('array.environments number.id').with_values([@env_1.id, @env_2.id])
            created_environment_type.environments.should match_array [@env_1, @env_2]
          end

          it 'should create environment type with given `plan_stage_ids`' do
            should have_json('array.plan_stages number.id').with_values([@plan_stage_1.id, @plan_stage_2.id])
            created_environment_type.plan_stages.should match_array [@plan_stage_1, @plan_stage_2]
          end
        end

        context 'XML' do
          before :each do
            params = param.to_xml(:root => xml_root)

            xpost params
          end

          subject { response.body }

          specify { response.code.should == '201' }

          it { should have_xpath("#{xml_root}/archive-number") }
          it { should have_xpath("#{xml_root}/archived-at")    }
          it { should have_xpath("#{xml_root}/created-at")     }
          it { should have_xpath("#{xml_root}/updated-at")     }
          it { should have_xpath("#{xml_root}/id")             }
          it { should have_xpath("#{xml_root}/position")       }

          it 'should create environment type with name' do
            should have_xpath("#{xml_root}/name").with_text('New Environment Type')
          end

          it 'should create environment type with description' do
            should have_xpath("#{xml_root}/description").with_text('New Environment Type description')
          end

          it 'should create environment type with strict' do
            should have_xpath("#{xml_root}/strict").with_text('true')
          end

          it 'should create environment type with label-color' do
            should have_xpath("#{xml_root}/label-color").with_text('#C0C0C0')
          end

          it 'should create environment type with given `environment_ids`' do
            should have_xpath("#{xml_root}/environments/environment/id").with_texts([@env_1.id, @env_2.id])
            created_environment_type.environments.should match_array [@env_1, @env_2]
          end

          it 'should create environment type with given `plan_stage_ids`' do
            should have_xpath("#{xml_root}/plan-stages/plan-stage/id").with_texts([@plan_stage_1.id, @plan_stage_2.id])
            created_environment_type.plan_stages.should match_array [@plan_stage_1, @plan_stage_2]
          end
        end
      end

      it_behaves_like 'creating request with params that fails validation' do
        before(:each) { create(:environment_type) }

        let(:param) { {:name => EnvironmentType.last.name} }
      end

      it_behaves_like 'creating request with invalid params'
    end

    describe "PUT #{base_url}/[id]" do

      let(:updated_environment_type) { EnvironmentType.find(@environment_type.id) }
      let(:url)                      {"#{base_url}/#{@environment_type.id}?token=#{@user.api_key}"}

      context 'with valid params' do
        let(:param)             { {:name => 'Updated Environment Type',
                                   :description => 'Updated Environment Type description',
                                   :strict => false,
                                   :label_color => '#808080',
                                   :environment_ids => [@env_1.id, @env_2.id],
                                   :plan_stage_ids => [@plan_stage_1.id, @plan_stage_2.id]
        }
        }

        context 'JSON' do
          before :each do
            params = {json_root => param}.to_json
            @environment_type = create(:environment_type)

            jput params
          end

          subject { response.body }

          specify { response.code.should == '202' }

          it { should have_json('*.archive_number')           }
          it { should have_json('*.archived_at')              }
          it { should have_json('string.created_at')          }
          it { should have_json('string.updated_at')          }
          it { should have_json('number.id')                  }
          it { should have_json('number.position')            }

          it 'should update environment type with name' do
            should have_json('string.name').with_value('Updated Environment Type')
          end

          it 'should update environment type with description' do
            should have_json('string.description').with_value('Updated Environment Type description')
          end

          it 'should update environment type with strict' do
            should have_json('boolean.strict').with_value(false)
          end

          it 'should update environment type with label_color' do
            should have_json('string.label_color').with_value('#808080')
          end

          it 'should update environment type with given `environment_ids`' do
            should have_json('array.environments number.id').with_values([@env_1.id, @env_2.id])
            updated_environment_type.environments.should match_array [@env_1, @env_2]
          end

          it 'should update environment type with given `plan_stage_ids`' do
            should have_json('array.plan_stages number.id').with_values([@plan_stage_1.id, @plan_stage_2.id])
            updated_environment_type.plan_stages.should match_array [@plan_stage_1, @plan_stage_2]
          end
        end

        context 'XML' do
          before :each do
            params = param.to_xml(:root => xml_root)
            @environment_type = create(:environment_type)

            xput params
          end

          subject { response.body }

          specify { response.code.should == '202' }

          it { should have_xpath("#{xml_root}/archive-number")       }
          it { should have_xpath("#{xml_root}/archived-at")          }
          it { should have_xpath("#{xml_root}/created-at")           }
          it { should have_xpath("#{xml_root}/updated-at")           }
          it { should have_xpath("#{xml_root}/id")                   }
          it { should have_xpath("#{xml_root}/position")             }

          it 'should update environment type with name' do
            should have_xpath("#{xml_root}/name").with_text('Updated Environment Type')
          end

          it 'should update environment type with description' do
            should have_xpath("#{xml_root}/description").with_text('Updated Environment Type description')
          end

          it 'should udpate environment type with strict' do
            should have_xpath("#{xml_root}/strict").with_text('false')
          end

          it 'should udpate environment type with label-color' do
            should have_xpath("#{xml_root}/label-color").with_text('#808080')
          end

          it 'should update environment type with given `environment_ids`' do
            should have_xpath("#{xml_root}/environments/environment/id").with_texts([@env_1.id, @env_2.id])
            updated_environment_type.environments.should match_array [@env_1, @env_2]
          end

          it 'should update environment type with given `plan_stage_ids`' do
            should have_xpath("#{xml_root}/plan-stages/plan-stage/id").with_texts([@plan_stage_1.id, @plan_stage_2.id])
            updated_environment_type.plan_stages.should match_array [@plan_stage_1, @plan_stage_2]
          end
        end
      end

      it_behaves_like 'with `toggle_archive` param'

      it_behaves_like 'editing request with params that fails validation' do
        before(:each) do
          create(:environment_type)
          @environment_type = create(:environment_type)
        end

        let(:param) { {:name => EnvironmentType.first.name} }
      end

      it_behaves_like 'editing request with invalid params'
    end

    describe "DELETE #{base_url}/[id]" do

      before :each do
        @environment_type = create(:environment_type)
        EnvironmentType.stub(:find).with(@environment_type.id).and_return @environment_type
        @environment_type.should_receive(:try).with(:destroy).and_return true
      end

      let(:url) {"#{base_url}/#{@environment_type.id}?token=#{@user.api_key}"}

      mimetypes = ['json', 'xml']
      mimetypes.each do |mimetype|
        it "should be successful using mimetype #{mimetype.upcase}" do
          params_json       = { id: @environment_type.id }.to_json
          params_xml        = create_xml {|xml| xml.id @environment_type.id}
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
        get:      ["#{base_url}", "#{base_url}/1"],
        post:     ["#{base_url}"],
        put:      ["#{base_url}/1"],
        delete:   ["#{base_url}/1"]
    }

    test_batch_of_requests methods_urls_for_403, :response_code => 403
  end

  context 'with no existing environments' do
    before :each do
      # make sure there's none of environment types
      EnvironmentType.delete_all
    end

    let(:token) { @token }

    methods_urls_for_404 = {
        get:      ["#{base_url}", "#{base_url}/1"],
        put:      ["#{base_url}/1"],
        delete:   ["#{base_url}/1"]
    }

    mimetypes = ['json', 'xml']

    test_batch_of_requests methods_urls_for_404, :response_code => 404, mimetypes: mimetypes
  end
end
