require 'spec_helper'

describe V1::ProceduresController do
  let(:base_url) { '/v1/procedures' }
  let(:json_root) { :procedure }
  let(:xml_root) { 'procedure' }

  before :all do
    @user         = create(:user)
    @token        = @user.api_key
  end

  context 'with existing procedures and valid api key' do
    before(:each)  do
      @app                = create(:app)
      @step               = create(:step)
      @step_to_be_cloned  = create(:step)
      @list               = create(:list, :name => 'IncludeInSteps')
      # set of list_items in order to duplicate step
      %w(name owner_id owner_type).each do |value_text|
        create(:list_item, :value_text => value_text, :list => @list)
      end
      User.current_user = nil
    end

    let(:url)     { "#{base_url}?token=#{@token}" }

    describe "GET /v1/procedures" do
      before(:each) do
        @procedure_1 = create(:procedure, :apps => [@app])
        @procedure_2 = create(:procedure, :apps => [@app], :name => 'Vipera in verpecula est')
        @procedure_3 = create(:procedure, :apps => [@app], :name => 'mad', :aasm_state => 'retired')
        @procedure_3.toggle_archive
        @procedure_3.reload

        @unarchived_procedure_ids = [@procedure_2.id, @procedure_1.id]
      end

      context 'JSON' do
        subject { response.body }

        it 'should return all procedures except archived(by default)' do
          jget

          should have_json('number.id').with_values(@unarchived_procedure_ids)
        end

        it 'should return all procedures except archived' do
          param   = {:filters => {:unarchived => true}}

          jget param

          should have_json('number.id').with_values(@unarchived_procedure_ids)
        end

        it 'should return all procedures archived' do
          param   = {:filters => {:archived => true}}

          jget param

          should have_json('number.id').with_values([@procedure_3.id])
        end

        it 'should return all procedures' do
          param   = {:filters => {:archived => true, :unarchived => true}}

          jget param

          should have_json('number.id').with_values([@procedure_3.id] + @unarchived_procedure_ids)
        end

        it 'should return all archived procedures' do
          param   = {:filters => {:archived => true, :unarchived => false}}

          jget param

          should have_json('number.id').with_value(@procedure_3.id)
        end

        it 'should return procedure by name' do
          param   = {:filters => {:name => 'Vipera in verpecula est'}}

          jget param

          should have_json('number.id').with_value(@procedure_2.id)
        end

        it 'should not return archived procedure by name' do
          param   = {:filters => {:name => @procedure_3.name}}

          jget param

          should == " "
        end

        it 'should return archived procedure by name if it is specified' do
          param   = {:filters => {:name => @procedure_3.name, :archived => true}}

          jget param

          should have_json('number.id').with_value(@procedure_3.id)
        end

        it 'should return procedures by `app_id`' do
          param   = {:filters => {:app_id => @app.id}}

          jget param

          should have_json('number.id').with_values(@unarchived_procedure_ids)
        end

        it 'should return archived procedure by `name` and `app_id` if it is specified' do
          param   = {:filters => {:name => @procedure_3.name, :app_id => @app.id, :archived => true}}

          jget param

          should have_json('number.id').with_value(@procedure_3.id)
        end
      end

      context 'XML' do
        let(:xml_root) {'procedures/procedure'}
        subject { response.body }

        it 'should return all procedures except archived(by default)' do
          xget

          should have_xpath("#{xml_root}/id").with_texts(@unarchived_procedure_ids)
        end

        it 'should return all procedures except archived' do
          param   = {:filters => {:unarchived => true}}

          xget param

          should have_xpath("#{xml_root}/id").with_texts(@unarchived_procedure_ids)
        end

        it 'should return all procedures archived' do
          param   = {:filters => {:archived => true}}

          xget param

          should have_xpath("#{xml_root}/id").with_texts([@procedure_3.id])
        end

        it 'should return all procedures' do
          param   = {:filters => {:archived => true, :unarchived => true}}

          xget param

          should have_xpath("#{xml_root}/id").with_texts([@procedure_3.id] + @unarchived_procedure_ids)
        end

        it 'should return all archived procedures' do
          param   = {:filters => {:archived => true, :unarchived => false}}

          xget param

          should have_xpath("#{xml_root}/id").with_text(@procedure_3.id)
        end

        it 'should return procedure by name' do
          param   = {:filters => {:name => 'Vipera in verpecula est'}}

          xget param

          should have_xpath("#{xml_root}/id").with_text(@procedure_2.id)
        end

        it 'should not return archived procedure by name if that was not specified' do
          param   = {:filters => {:name => @procedure_3.name}}

          xget param

          should == " "
        end

        it 'should return archived procedure by name if it is specified' do
          param   = {:filters => {:name => @procedure_3.name, :archived => true}}

          xget param

          should have_xpath("#{xml_root}/id").with_text(@procedure_3.id)
        end

        it 'should return procedures by `app_id`' do
          param   = {:filters => {:app_id => @app.id}}

          xget param

          should have_xpath("#{xml_root}/id").with_texts(@unarchived_procedure_ids)
        end

        it 'should return archived procedure by `name` and `app_id` if it is specified' do
          param   = {:filters => {:name => @procedure_3.name, :app_id => @app.id, :archived => true}}

          xget param

          should have_xpath("#{xml_root}/id").with_text(@procedure_3.id)
        end
      end
    end

    describe "GET /v1/procedures/[id]" do
      before(:each) do
        @procedure_1 = create(:procedure)
        @procedure_2 = create(:procedure)
      end

      context 'JSON' do
        let(:url) {"#{base_url}/#{@procedure_1.id}?token=#{@user.api_key}"}

        subject { response.body }

        it 'should return procedure' do
          jget

          should have_json('number.id').with_value(@procedure_1.id)
        end
      end

      context 'XML' do
        let(:url) {"#{base_url}/#{@procedure_2.id}?token=#{@user.api_key}"}

        subject { response.body }

        it 'should return procedure' do
          xget

          should have_xpath('procedure/id').with_text(@procedure_2.id)
        end
      end
    end


    #***Required Attribute***
    # name - string name of the business process
    #***Optional Attributes***
    # description - string description of the procedure
    # app_ids - array of integer related app ids
    # step_ids - array of integer related step ids
    # step_ids_to_clone - array of integer related step ids to be cloned and associated with the procedure. Fields to be cloned are controlled by the metadata list titled IncludeInSteps                                                                                                                                                                           step_ids_to_clone - array of integer related step ids to be cloned and associated with the procedure. Fields to be cloned are controlled by the metadata list titled IncludeInSteps
    describe "POST /v1/procedures" do
      let(:url)               {"#{base_url}?token=#{@token}"}
      let(:app_ids)           {[@app.id]}
      let(:step_ids)          {[@step.id]}
      let(:step_ids_to_clone) {[@step_to_be_cloned.id]}
      let(:created_procedure) {Procedure.last}
      let(:cloned_step_id)    {Step.last.id}

      context 'with valid params' do
        let(:param) do
          {
            :name               => 'eman',
            :description        => 'noitpircsed',
            :step_ids_to_clone  => step_ids_to_clone,
            :step_ids           => step_ids,
            :app_ids            => app_ids
          }
        end

        subject { response.body }

        context 'JSON' do
          before :each do
            params = {json_root => param}.to_json

            jpost params
          end

          specify { response.code.should == '201' }

          it { should have_json('*.archive_number')           }
          it { should have_json('*.archived_at')              }
          it { should have_json('string.created_at')          }
          it { should have_json('string.updated_at')          }
          it { should have_json('number.id')                  }

          it 'should have a name' do
            should have_json('string.name').with_value('eman')
          end

          it 'should have a description' do
            should have_json('string.description').with_value('noitpircsed')
          end

          it 'should have apps' do
            created_procedure.apps.should match_array [@app]
          end
          it 'should have steps' do
            should have_json('array.steps > object > number.id').with_values(step_ids + [cloned_step_id])
          end
        end

        context 'XML' do
          before :each do
            params = param.to_xml(:root => xml_root)

            xpost params
          end

          specify { response.code.should == '201' }

          it { should have_xpath("#{xml_root}/archive-number") }
          it { should have_xpath("#{xml_root}/archived-at")    }
          it { should have_xpath("#{xml_root}/created-at")     }
          it { should have_xpath("#{xml_root}/updated-at")     }
          it { should have_xpath("#{xml_root}/id")             }

          it 'should have a name' do
            should have_xpath("#{xml_root}/name").with_text('eman')
          end

          it 'should have description' do
            should have_xpath("#{xml_root}/description").with_text('noitpircsed')
          end

          it 'should have apps' do
            created_procedure.apps.should match_array [@app]
          end

          it 'should have steps' do
            should have_xpath("#{xml_root}/steps/step/id").with_texts(step_ids + [cloned_step_id])
          end
        end
      end

      it_behaves_like 'creating request with params that fails validation' do
        let(:param) { {name: ''} }
      end

      it_behaves_like 'creating request with invalid params'
    end

    describe "PUT /v1/procedures/[id]" do
      let(:url)               {"#{base_url}/#{@procedure.id}?token=#{@token}"}
      let(:app_ids)           {[@app.id]}
      let(:step_ids)          {[@step.id]}
      let(:step_ids_to_clone) {[@step_to_be_cloned.id]}
      let(:cloned_step_id)    {Step.last.id}

      context 'with' do
        subject { response.body }

        context 'valid params' do
          let(:param) do
            {
                :name               => 'eman',
                :description        => 'noitpircsed',
                :step_ids_to_clone  => step_ids_to_clone,
                #:step_ids           => step_ids, problems with it. Investigate
                :app_ids            => app_ids
            }
          end

          context 'JSON' do
            before :each do
              @procedure =  create(:procedure, apps: [@app])

              params = {json_root => param}.to_json

              jput params
            end

            specify { response.code.should == '202' }

            it { should have_json('*.archive_number')           }
            it { should have_json('*.archived_at')              }
            it { should have_json('string.created_at')          }
            it { should have_json('string.updated_at')          }
            it { should have_json('number.id')                  }

            it 'should have a name' do
              should have_json('string.name').with_value('eman')
            end

            it 'should have a description' do
              should have_json('string.description').with_value('noitpircsed')
            end

            it 'should have apps' do
              @procedure.apps.should match_array [@app]
            end

            it 'should have steps' do
              should have_json('array.steps > object > number.id').with_values([cloned_step_id])
            end
          end

          context 'XML' do
            before :each do
              @procedure = create(:procedure)
              @procedure.apps << @app

              params = param.to_xml(:root => xml_root)

              xput params
            end

            specify { response.code.should == '202' }

            it { should have_xpath("#{xml_root}/archive-number") }
            it { should have_xpath("#{xml_root}/archived-at")    }
            it { should have_xpath("#{xml_root}/created-at")     }
            it { should have_xpath("#{xml_root}/updated-at")     }
            it { should have_xpath("#{xml_root}/id")             }

            it 'should have a name' do
              should have_xpath("#{xml_root}/name").with_text('eman')
            end

            it 'should have description' do
              should have_xpath("#{xml_root}/description").with_text('noitpircsed')
            end

            it 'should have apps' do
              @procedure.apps.should match_array [@app]
            end

            it 'should have steps' do
              should have_xpath("#{xml_root}/steps/step/id").with_texts([cloned_step_id])
            end
          end
        end
      end

      it_behaves_like 'with `toggle_archive` param'

      it_behaves_like 'editing request with params that fails validation' do
        before(:each)  {@procedure = create(:procedure)}
        let(:param)   { {name: ''} }
      end

      it_behaves_like 'editing request with invalid params'
    end

    describe "DELETE /v1/procedures/[id]" do

      before :each do
        @procedure = create(:procedure)
        Procedure.stub(:find).with(@procedure.id).and_return @procedure
        @procedure.should_receive(:try).with(:destroy).and_return true
      end

      let(:url) {"#{base_url}/#{@procedure.id}?token=#{@user.api_key}"}

      mimetypes = ['json', 'xml']
      mimetypes.each do |mimetype|
        it "should be successful using mimetype #{mimetype.upcase}" do
          params_json       = { id: @procedure.id }.to_json
          params_xml        = create_xml {|xml| xml.id @procedure.id}
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
        get:      ["/v1/procedures", "/v1/procedures/1"],
        post:     ["/v1/procedures"],
        put:      ["/v1/procedures/1"],
        delete:   ["/v1/procedures/1"]
    }

    test_batch_of_requests methods_urls_for_403, :response_code => 403
  end

  context 'with no existing procedures' do

    let(:token)    { @token }

    methods_urls_for_404 = {
        get:      ["/v1/procedures", "/v1/procedures/1"],
        put:      ["/v1/procedures/1"],
        delete:   ["/v1/procedures/1"]
    }

    mimetypes = ['json', 'xml']

    test_batch_of_requests methods_urls_for_404, :response_code => 404, mimetypes: mimetypes
  end
end
