require 'spec_helper'

base_url =  '/v1/package_contents'
describe "testing #{base_url}" do
  let(:base_url) { base_url }
  let(:json_root) { :package_content }
  let(:xml_root) { 'package-content' }

  before :all do
    @user         = create(:user)
    @token        = @user.api_key
  end

  context 'with existing package_contents and valid api key' do
    before(:each)  do
      User.current_user = @user
      @request = create(:request)
    end

    let(:url)     { "#{base_url}?token=#{@token}" }

    describe "GET #{base_url}" do
      before(:each) do
        PackageContent.delete_all

        @pc_1 = create(:package_content)
        @pc_2 = create(:package_content, :name => 'Vulpes pilum mutat, non mores')
        @pc_3 = create(:package_content, :name => 'mad')
        @pc_3.toggle_archive
        @pc_3.reload

        @unarchived_pc_ids = [@pc_2.id, @pc_1.id]
      end

      context 'JSON' do
        subject { response.body }

        it 'should return all package_contents except archived(by default)' do
          jget

          should have_json('number.id').with_values(@unarchived_pc_ids)
        end

        it 'should return all package_contents except archived' do
          param   = {:filters => {:unarchived => true}}

          jget param

          should have_json('number.id').with_values(@unarchived_pc_ids)
        end

        it 'should return all package_contents except archived' do
          param   = {:filters => {:archived => true}}

          jget param

          should have_json('number.id').with_values([@pc_3.id])
        end

        it 'should return all package_contents' do
          param   = {:filters => {:archived => true, :unarchived => true}}

          jget param

          should have_json('number.id').with_values([@pc_3.id] + @unarchived_pc_ids)
        end

        it 'should return all archived package_contents' do
          param   = {:filters => {:archived => true, :unarchived => false}}

          jget param

          should have_json('number.id').with_value(@pc_3.id)
        end

        it 'should return package_content by name' do
          param   = {:filters => {:name => 'Vulpes pilum mutat, non mores'}}

          jget param

          should have_json('number.id').with_value(@pc_2.id)
        end

        it 'should not return archived package_content by name' do
          param   = {:filters => {:name => @pc_3.name}}

          jget param

          should == " "
        end

        it 'should return nothing' do
          param   = {:filters => {:unarchived => false}}

          jget param

          response.status.should == 404
          should == " "
        end

        it 'should return archived package_content by name if it is specified' do
          param   = {:filters => {:name => @pc_3.name, :archived => true}}

          jget param

          should have_json('number.id').with_value(@pc_3.id)
        end
      end

      context 'XML' do
        let(:xml_root) {'package-contents/package-content'}

        subject { response.body }

        it 'should return all package_contents except archived(by default)' do
          xget

          should have_xpath("#{xml_root}/id").with_texts(@unarchived_pc_ids)
        end

        it 'should return all package_contents except archived' do
          param   = {:filters => {:unarchived => true}}

          xget param

          should have_xpath("#{xml_root}/id").with_texts(@unarchived_pc_ids)
        end

        it 'should return all package_contents except archived' do
          param   = {:filters => {:archived => true}}

          xget param

          should have_xpath("#{xml_root}/id").with_texts([@pc_3.id])
        end

        it 'should return all package_contents' do
          param   = {:filters => {:archived => true, :unarchived => true}}

          xget param

          should have_xpath("#{xml_root}/id").with_texts([@pc_3.id] + @unarchived_pc_ids)
        end

        it 'should return all archived package_contents' do
          param   = {:filters => {:archived => true, :unarchived => false}}

          xget param

          should have_xpath("#{xml_root}/id").with_text(@pc_3.id)
        end

        it 'should return package_content by name' do
          param   = {:filters => {:name => 'Vulpes pilum mutat, non mores'}}

          xget param

          should have_xpath("#{xml_root}/id").with_text(@pc_2.id)
        end

        it 'should not return archived package_content by name if that was not specified' do
          param   = {:filters => {:name => @pc_3.name}}

          xget param

          response.status.should == 404
          should == " "
        end

        it 'should return archived package_content by name if it is specified' do
          param   = {:filters => {:name => @pc_3.name, :archived => true}}

          xget param

          should have_xpath("#{xml_root}/id").with_text(@pc_3.id)
        end
      end
    end

    describe "GET #{base_url}/[id]" do

      before(:each) { @pc = create(:package_content) }

      let(:url) {"#{base_url}/#{@pc.id}?token=#{@token}"}

      subject { response.body }

      context 'JSON' do
        it 'should return package_content' do
          jget

          should have_json('number.id').with_value(@pc.id)
        end
      end

      context 'XML' do
        it 'should return package_content' do
          xget

          should have_xpath('package-content/id').with_text(@pc.id)
        end
      end
    end

    #***Required Attributes***
    # name - string name of the package_content (required)
    #***Optional Attributes***
    # request_ids - array of integer ids for related request ids
    describe "POST #{base_url}" do
      let(:url)         {"#{base_url}?token=#{@token}"}
      let(:request_ids) {[@request.id]}

      context 'with valid params' do
        let(:param) do
          {
            :name        => 'Stronger',
            :request_ids => request_ids
          }
        end

        subject { response.body }

        context 'JSON' do
          before :each do
            params = {json_root => param}.to_json

            jpost params
          end

          specify { response.code.should == '201' }

          it { should have_json('*.abbreviation')             }
          it { should have_json('*.archive_number')           }
          it { should have_json('*.archived_at')              }
          it { should have_json('number.position')            }
          it { should have_json('string.created_at')          }
          it { should have_json('string.updated_at')          }
          it { should have_json('number.id')                  }

          it 'should have a name' do
            should have_json('string.name').with_value('Stronger')
          end

          it 'should have requests' do
            should have_json('array.requests number.id').with_values(request_ids)
          end
        end

        context 'XML' do
          before :each do
            params = param.to_xml(:root => xml_root)

            xpost params
          end

          specify { response.code.should == '201' }

          it { should have_xpath("#{xml_root}/abbreviation")   }
          it { should have_xpath("#{xml_root}/archive-number") }
          it { should have_xpath("#{xml_root}/archived-at")    }
          it { should have_xpath("#{xml_root}/position")       }
          it { should have_xpath("#{xml_root}/created-at")     }
          it { should have_xpath("#{xml_root}/updated-at")     }
          it { should have_xpath("#{xml_root}/id")             }

          it 'should have a name' do
            should have_xpath("#{xml_root}/name").with_text('Stronger')
          end

          it 'should have requests' do
            should have_xpath("#{xml_root}/requests/request/id").with_texts(request_ids)
          end
        end
      end

      it_behaves_like 'creating request with params that fails validation' do
        let(:param) { {:name => ''} }
      end

      it_behaves_like 'creating request with invalid params'
    end

    describe "PUT #{base_url}/[id]" do
      let(:url)         {"#{base_url}/#{@pc.id}?token=#{@token}"}
      let(:request_ids) {[@request.id]}

      context 'with valid params' do
        let(:param) do
          {
              :name        => 'Stronger',
              :request_ids => request_ids
          }
        end

        subject { response.body }

        context 'JSON' do
          before :each do
            @pc     = create(:package_content)
            params  = {json_root => param}.to_json

            jput params
          end

          specify { response.code.should == '202' }

          it { should have_json('*.abbreviation')             }
          it { should have_json('*.archive_number')           }
          it { should have_json('*.archived_at')              }
          it { should have_json('number.position')            }
          it { should have_json('string.created_at')          }
          it { should have_json('string.updated_at')          }
          it { should have_json('number.id')                  }

          it 'should have a name' do
            should have_json('string.name').with_value('Stronger')
          end

          it 'should have requests' do
            should have_json('array.requests number.id').with_values(request_ids)
          end
        end

        context 'XML' do
          before :each do
            @pc     = create(:package_content)
            params  = param.to_xml(:root => xml_root)

            xput params
          end

          specify { response.code.should == '202' }

          it { should have_xpath("#{xml_root}/abbreviation")   }
          it { should have_xpath("#{xml_root}/archive-number") }
          it { should have_xpath("#{xml_root}/archived-at")    }
          it { should have_xpath("#{xml_root}/position")       }
          it { should have_xpath("#{xml_root}/created-at")     }
          it { should have_xpath("#{xml_root}/updated-at")     }
          it { should have_xpath("#{xml_root}/id")             }

          it 'should have a name' do
            should have_xpath("#{xml_root}/name").with_text('Stronger')
          end

          it 'should have requests' do
            should have_xpath("#{xml_root}/requests/request/id").with_texts(request_ids)
          end
        end
      end

      it_behaves_like 'with `toggle_archive` param'

      it_behaves_like 'editing request with params that fails validation' do
        before(:each) { @pc = create(:package_content) }

        let(:param) { {:name => ''} }
      end

      it_behaves_like 'editing request with invalid params'
    end

    describe "DELETE #{base_url}/[id]" do

      before :each do
        @package_content = create(:package_content)
        PackageContent.stub(:find).with(@package_content.id).and_return @package_content
        @package_content.should_receive(:try).with(:destroy).and_return true
      end

      let(:pc_id) { @package_content.id }
      let(:url) {"#{base_url}/#{@package_content.id}?token=#{@token}"}

      mimetypes = ['json', 'xml']
      mimetypes.each do |mimetype|
        it "should be successful using mimetype #{mimetype.upcase}" do
          params_json       = { id: @package_content.id }.to_json
          params_xml        = create_xml {|xml| xml.id @package_content.id}
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

  context 'with no existing package_contents' do

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