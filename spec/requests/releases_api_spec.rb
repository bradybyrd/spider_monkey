require 'spec_helper'

base_url =  '/v1/releases'
describe "testing #{base_url}" do
  let(:base_url) { base_url }
  let(:json_root) { :release }
  let(:xml_root) { 'release' }

  before(:all)  do
    @user   = create(:user)
    @token  = @user.api_key
    User.current_user = @user
  end

  context 'with existing releases and valid api key' do
    let(:url)     { "#{base_url}?token=#{@token}" }

    describe "GET #{base_url}" do
      before(:each) do
        @release_1 = create(:release)
        @release_2 = create(:release, :name => 'cool name')
        @release_3 = create(:release, :name => 'mad name')
        @release_3.archive
        @release_3.reload

        @unarchived_release_ids = [@release_2.id, @release_1.id]
      end

      context 'JSON' do
        subject { response.body }

        it 'should return all releases except archived(by default)' do
          jget

          should have_json('number.id').with_values(@unarchived_release_ids)
        end

        it 'should return all releases except archived' do
          param   = {:filters => {:unarchived => true}}

          jget param

          should have_json('number.id').with_values(@unarchived_release_ids)
        end

        it 'should return all releases archived' do
          param   = {:filters => {:archived => true}}

          jget param

          should have_json('number.id').with_values([@release_3.id])
        end

        it 'should return all releases' do
          param   = {:filters => {:archived => true, :unarchived => true}}

          jget param

          should have_json('number.id').with_values([@release_3.id] + @unarchived_release_ids)
        end

        it 'should return all archieved releases' do
          param   = {:filters => {:archived => true, :unarchived => false}}

          jget param

          should have_json('number.id').with_value(@release_3.id)
        end

        it 'should return release by name' do
          param   = {:filters => {:name => 'cool name'}}

          jget param

          should have_json('number.id').with_value(@release_2.id)
        end

        it 'should not return archived release by name' do
          param   = {:filters => {:name => @release_3.name}}

          jget param

          should == " "
        end

        it 'should return archived release by name if it is specified' do
          param   = {:filters => {:name => @release_3.name, :archived => true}}

          jget param

          should have_json('number.id').with_value(@release_3.id)
        end
      end

      context 'XML' do
        subject { response.body }

        it 'should return all releases except archived(by default)' do
          xget

          should have_xpath('releases/release/id').with_texts(@unarchived_release_ids)
        end

        it 'should return all releases except archived' do
          param   = {:filters => {:unarchived => true}}

          xget param

          should have_xpath('releases/release/id').with_texts(@unarchived_release_ids)
        end

        it 'should return all releases archived' do
          param   = {:filters => {:archived => true}}

          xget param

          should have_xpath('releases/release/id').with_texts([@release_3.id])
        end

        it 'should return all releases' do
          param   = {:filters => {:archived => true, :unarchived => true}}

          xget param

          should have_xpath('releases/release/id').with_texts([@release_3.id] + @unarchived_release_ids)
        end

        it 'should return all archieved releases' do
          param   = {:filters => {:archived => true, :unarchived => false}}

          xget param

          should have_xpath('releases/release/id').with_text(@release_3.id)
        end

        it 'should return release by name' do
          param   = {:filters => {:name => 'cool name'}}

          xget param

          should have_xpath('releases/release/id').with_text(@release_2.id)
        end

        it 'should not return archived release by name if that was not specified' do
          param   = {:filters => {:name => @release_3.name}}

          xget param

          should == " "
        end

        it 'should return archived release by name if it is specified' do
          param   = {:filters => {:name => @release_3.name, :archived => true}}

          xget param

          should have_xpath('releases/release/id').with_text(@release_3.id)
        end
      end
    end

    describe "GET #{base_url}/[id]" do
      before(:each) do
        @release_1 = create(:release)
        @release_2 = create(:release)
      end

      context 'JSON' do
        let(:url) {"#{base_url}/#{@release_1.id}?token=#{@token}"}

        subject { response.body }

        it 'should return release' do
          jget

          should have_json('number.id').with_value(@release_1.id)
        end
      end

      context 'XML' do
        let(:url) {"#{base_url}/#{@release_2.id}?token=#{@token}"}

        subject { response.body }

        it 'should return release' do
          xget

          should have_xpath('release/id').with_text(@release_2.id)
        end
      end
    end

    describe "POST #{base_url}" do
      before(:each) do
        @_request = create(:request)
      end

      let(:created_release)   { Release.where(:name => 'shakeit').try(:first) }

      context 'with valid params' do
        let(:param)             { {:name => 'shakeit',
                                   :request_ids => [@_request.id]
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
          it { should have_json('string.updated_at') }
          it { should have_json('number.id')         }
          it { should have_json('number.position')   }

          it 'should create release name' do
            should have_json('string.name').with_value('shakeit')
          end

          it 'should create release with given `request_ids`' do
            should have_json('array.requests number.id').with_value(@_request.id)
            created_release.requests.should match_array [@_request]
          end
        end

        context 'XML' do
          before :each do
            params    = param.to_xml(:root => xml_root)

            xpost params
          end

          subject { response.body }

          specify { response.code.should == '201' }

          it { should have_xpath('release/archive-number') }
          it { should have_xpath('release/archived-at')    }
          it { should have_xpath('release/created-at')     }
          it { should have_xpath('release/updated-at')     }
          it { should have_xpath('release/id')             }
          it { should have_xpath('release/position')       }

          it 'should create release name' do
            should have_xpath('release/name').with_text('shakeit')
          end

          it 'should create release with given `request_ids`' do
            should have_xpath('release/requests/request/id').with_text(@_request.id)
            created_release.requests.should match_array [@_request]
          end
        end
      end

      it_behaves_like 'creating request with params that fails validation' do
        before(:each) { @release = create(:release) }

        let(:param) { {:name => ''} }
      end

      it_behaves_like 'creating request with invalid params'
    end

    describe "PUT #{base_url}/[id]" do
      before(:each) do
        @release = create(:release)
        @_request = create(:request)
        # a very nasty intermittent bug causes this test to fail when a plan
        # is involved because of a collision between the locked? method
        # invoked somewhere in the call chain for PUT and POST rest calls
        # and the 'locked' scope of the plan aasm state.  See https://github.com/rails/rails/issues/7421
        # I relaxed the plans part of the test as a work around.
      end


      let(:updated_release)   { Release.find(@release.id) }
      let(:url)               {"#{base_url}/#{@release.id}?token=#{@token}"}

      context 'with valid params' do
        let(:param)             { {:name => 'shakeit',
                                   :request_ids => [@_request.id]
                                  }
        }

        context 'JSON' do
          before :each do
            params    = {json_root => param}.to_json
            @release  = create(:release)

            jput params
          end

          subject { response.body }

          specify { response.code.should == '202' }

          it { should have_json('*.archive_number')  }
          it { should have_json('*.archived_at')     }
          it { should have_json('string.created_at') }
          it { should have_json('string.updated_at') }
          it { should have_json('number.id')         }
          it { should have_json('number.position')   }

          it 'should update release name' do
            should have_json('string.name').with_value('shakeit')
          end

          it 'should update release with given `request_ids`' do
            should have_json('array.requests number.id').with_value(@_request.id)
            updated_release.requests.should match_array [@_request]
          end

        end

        context 'XML' do
          before :each do
            params    = param.to_xml(:root => xml_root)
            @release  = create(:release)

            xput params
          end

          subject { response.body }

          specify { response.code.should == '202' }

          it { should have_xpath('release/archive-number') }
          it { should have_xpath('release/archived-at')    }
          it { should have_xpath('release/created-at')     }
          it { should have_xpath('release/updated-at')     }
          it { should have_xpath('release/id')             }
          it { should have_xpath('release/position')       }

          it 'should update release name' do
            should have_xpath('release/name').with_text('shakeit')
          end

          it 'should update release with given `request_ids`' do
            should have_xpath('release/requests/request/id').with_text(@_request.id)
            updated_release.requests.should match_array [@_request]
          end
        end
      end

      it_behaves_like 'with `toggle_archive` param'

      it_behaves_like 'editing request with params that fails validation' do
        before(:each) { @release = create(:release) }

        let(:param) { {:name => ''} }
      end

      it_behaves_like 'editing request with invalid params'
    end

    describe "DELETE #{base_url}/[id]" do
      before :each do
        @release = create(:release)
        Release.stub(:find).with(@release.id).and_return @release
        @release.should_receive(:try).with(:destroy).and_return true
      end

      let(:url) {"#{base_url}/#{@release.id}?token=#{@token}"}

      mimetypes = ['json', 'xml']
      mimetypes.each do |mimetype|
        it "should be successful using mimetype #{mimetype.upcase}" do
          params_json       = { id: @release.id }.to_json
          params_xml        = create_xml {|xml| xml.id @release.id}
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

  context 'with no existing releases' do

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
