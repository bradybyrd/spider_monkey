require 'spec_helper'

describe AutomationCommon do
  let!(:user) { User.current_user = create(:old_user) }
  let(:request) { create(:request_with_app) }
  let(:app) { request.apps.first }
  let(:env) { request.environment }
  let(:assigned_env) { AssignedEnvironment.create!(:environment_id => env.id, :assigned_app_id => app.assigned_apps.first.id, :role => user.roles.first) }

  let(:step) { create(:step_with_script, :request => request) }

  it "#output_separator" do
    AutomationCommon.output_separator("some_phrase").should include("===================== some_phrase =======")
  end

  it "#platform_path" do
    AutomationCommon.platform_path('/root').should eql("/root")
  end

  it "#base_url" do
    GlobalSettings[:base_url] = '/root'
    AutomationCommon.base_url.should eql('/root')
  end

  it "#callback_url" do
    GlobalSettings[:base_url] = '/root'
    assigned_env
    result = AutomationCommon.callback_url(step, 'token')
    result.should eql("#{GlobalSettings[:base_url]}/steps/#{step.id}/#{request.number}/callback.xml?token=token")
  end

  describe "#get_output_dir" do
    it "success" do
      assigned_env
      result = AutomationCommon.get_output_dir('request', step)
      result.should include("/automation_results/request/#{app.name.gsub(" ", "_")}/#{request.number}/step_#{step.id}")
    end

    it "raise error" do
      assigned_env
      FileUtilsUTF.stub(:mkdir_p).and_raise('error')
      FileUtils.stub(:mkdir_p).and_raise('error')
      expect { AutomationCommon.get_output_dir 'request', step}.to raise_error(RuntimeError)
    end
  end

  it "#get_request_dir" do
    assigned_env
    AutomationCommon.get_request_dir(request).should include("/automation_results/request/#{app.name.gsub(" ", "_")}/#{request.number}")
  end

  it "#append_output_file" do
    file_like_object = double("file like object")
    FileInUTF.stub(:open).and_return(file_like_object)
    file_like_object.should_receive(:puts).with("some_phrase")
    file_like_object.should_receive(:flush)
    file_like_object.should_receive(:close)
    AutomationCommon.append_output_file({"SS_output_file" => 'file'}, 'some_phrase')
  end

  describe "#get_trailer_string" do
    it "returns empty string" do
      AutomationCommon.get_trailer_string({"SS_script_target" => "bladelogic"}).should eql('')
    end

    specify "for remedy or baa script" do
      result = AutomationCommon.get_trailer_string({"SS_script_target" => "remedy", "SS_input_file" => 'file.rb'})
      result.should include('Load the input parameters')
      result.should include("load_input_params('file.rb'")
      result.should include('create_output_file')
    end

    it "returns 'Trailer TBD'" do
      AutomationCommon.get_trailer_string({"SS_script_target" => "automation"}).should eql('### Trailer TBD ###')
    end
  end

  it "#init_run_files" do
    file_like_object = double("file like object")
    FileInUTF.stub(:new).and_return(file_like_object)
    file_like_object.should_receive(:print).with(anything).any_number_of_times
    FileInUTF.stub(:open).and_return(file_like_object)
    file_like_object.should_receive(:puts).with(anything).any_number_of_times
    file_like_object.should_receive(:close).exactly(3).times
    File.stub(:chmod).and_return(1)
    file_like_object.stub(:path).and_return('/root')
    AutomationCommon.init_run_files({"SS_input_file" => 'file'}, "content")
  end

  it "#mask_passwords" do
    AutomationCommon.mask_passwords('SS_password = my_pass').should eql("SS_password = '<private>'")
  end

  it "#tokenize" do
    assigned_env
    AutomationCommon.tokenize(step).should eql("#{request.id}_#{step.id}_#{Time.now.to_i}")
  end

  describe "#error_in?" do
    it "true" do
      AutomationCommon.error_in?('failed: 12_30_2013').should be_truthy
    end

    it "false" do
      List.stub(:find_by_name).and_return(["errors"])
      AutomationCommon.error_in?('failed: 12_30_2013').should_not be_truthy
    end
  end

  describe "#build_params" do
    before(:each) { assigned_env }

    specify "bladelogic" do
      Script.any_instance.stub(:authentication).and_return('step')
      step.owner.stub_chain(:bladelogic_user, :username).and_return('1')
      step.stub(:bladelogic_role).and_return('1')
      step.request.stub(:headers_for_request).and_return("request_notes"=>'headers_for_request')
      AutomationCommon.build_params({"SS_script_target" => "bladelogic"}, step)["SS_auth_type"].should eql('step')
    end

    specify "ssh" do
      step.stub(:new_record?).and_return(true)
      AutomationCommon.build_params({"SS_script_target" => "ssh", "step_user_id" => create(:old_user)}, step)["step_id"].should eql(step.id)
    end

    specify "remedy" do
      step.request.stub(:headers_for_request).and_return("request_notes"=>'headers_for_request')
      AutomationCommon.build_params({"SS_script_target" => "remedy", "step_user_id" => create(:old_user)}, step)["step_id"].should eql(step.id)
    end

    specify "resource_automation" do
      step.request.stub(:headers_for_request).and_return("request_notes"=>'headers_for_request')
      AutomationCommon.build_params({"SS_script_target" => "resource_automation", "step_user_id" => create(:old_user)}, step)["step_id"].should eql(step.id)
    end

    specify "hudson" do
      step.request.stub(:headers_for_request).and_return("request_notes"=>'headers_for_request')
      AutomationCommon.build_params({"SS_script_target" => "hudson", "step_user_id" => create(:old_user)}, step)["step_id"].should eql(step.id)
    end

    specify "baa" do
      step.request.stub(:headers_for_request).and_return("request_notes"=>'headers_for_request')
      AutomationCommon.build_params({"SS_script_target" => "baa", "step_user_id" => create(:old_user)}, step)["step_id"].should eql(step.id)
    end

    specify "rlm" do
      step.request.stub(:headers_for_request).and_return("request_notes"=>'headers_for_request')
      AutomationCommon.build_params({"SS_script_target" => "rlm", "step_user_id" => create(:old_user)}, step)["step_id"].should eql(step.id)
    end

    specify "script" do
      step.request.stub(:headers_for_request).and_return("request_notes"=>'headers_for_request')
      AutomationCommon.build_params({"SS_script_target" => "script", "step_user_id" => create(:old_user)}, step)["step_id"].should eql(step.id)
    end

    specify "automation" do
      step.request.stub(:headers_for_request).and_return("request_notes"=>'headers_for_request')
      AutomationCommon.build_params({"SS_script_target" => "automation", "step_user_id" => create(:old_user)}, step)["step_id"].should eql(step.id)
    end
  end

  describe "#build_server_params" do
    before(:each) do
      create_installed_component
      assigned_env
    end

    specify "server" do
      server = create(:server)
      step.server_ids = [server.id]
      step.stub(:installed_component).and_return(@installed_component)
      @installed_component.server_ids = [server.id]
      AutomationCommon.build_server_params(step)["server1000_name"].should eql(server.name)
    end

    specify "server aspect" do
      server_aspect = create(:server_aspect, :server_level => create(:server_level))
      @installed_component.server_aspect_ids = [server_aspect.id]
      AutomationCommon.build_server_params(@installed_component.id)["server1000_name"].should eql("#{server_aspect.server.name}:#{server_aspect.name}")
    end
  end

  it "#test_property_values components" do
    create_installed_component
    property = create(:property)
    property_val = create(:property_value, :property => property,
                                           :value_holder_id => @installed_component.id,
                                           :value_holder_type => 'InstalledComponent')
    AutomationCommon.test_property_values_component(@installed_component.id)[property.name].should eql(property_val.value)
  end

  it "#test_property_values packages" do
    create_app_package
    property = create(:property)
    property_val = create(:property_value, :property => property,
                          :value_holder_id => @app_package.id,
                          :value_holder_type => 'ApplicationPackage')
    expect(AutomationCommon.test_property_values_app_package(@app_package)[property.name]).to eql(property_val.value)
  end

  it "#test_package_values" do
    create_app_package
    hash_parms = {
      "app_id" => @app.id,
      "package_id" => @package.id,
      "type_of_object" => 'Package'
    }
    puts "sending:#{hash_parms}"
    hash = AutomationCommon.test_script_values(hash_parms)
    expect(hash).to include("step_package_id" => @package.id)
    expect(hash).to include("step_package_name"=> @package.name)
  end

  it "#test_package instance_values" do
    create_app_package
    @package_instance = create(:package_instance, package: @package)
    hash_parms = {
      "app_id" => @app.id,
      "package_id" => @package.id,
      "type_of_object" => 'Package',
      "package_instance_id" => @package_instance.id
    }
    puts "sending:#{hash_parms}"
    hash = AutomationCommon.test_script_values(hash_parms)
    expect(hash).to include("step_package_id" => @package.id)
    expect(hash).to include("step_package_name"=> @package.name)
    expect(hash).to include("step_package_instance_id" => @package_instance.id)
    expect(hash).to include("step_package_instance_name"=> @package_instance.name)
  end

  describe "#bladelogic_header_file" do
    let(:file_like_object) { double("file like object") }

    let(:bl_ready) {
      File.stub(:open).and_return(file_like_object)
      GlobalSettings[:bladelogic_profile] = "user"
      GlobalSettings[:bladelogic_rolename] = "admin"
      GlobalSettings[:bladelogic_username] = "User"
      GlobalSettings[:bladelogic_password] = "pass"
      GlobalSettings[:bladelogic_ip_address] = "192.168.1.1"
      GlobalSettings[:bladelogic_enabled] = true
    }

    it "change profile and role_name via params" do
      bl_ready
      file_like_object.stub(:read).and_return("$$BLADELOGIC_PROFILE $$BLADELOGIC_ROLENAME $$APPPATH")
      params = {"SS_auth_type" => 'Ldap',
                "bladelogic_profile" => "user1",
                "bladelogic_role" => "admin1",
                "SS_input_file" => "file"}
      AutomationCommon.bladelogic_header_file(params).should include('user1 admin1')
    end

    it "change profile and role_name via GlobalSettings" do
      bl_ready
      file_like_object.stub(:read).and_return("$$BLADELOGIC_PROFILE $$BLADELOGIC_ROLENAME $$APPPATH")
      AutomationCommon.bladelogic_header_file({"SS_input_file" => "file"}).should include('user admin')
    end

    it "change input file" do
      bl_ready
      file_like_object.stub(:read).and_return("$$BLADELOGIC_INPUTFILE $$APPPATH")
      AutomationCommon.bladelogic_header_file({"SS_input_file" => "file"}).should include('file')
    end

    it "change username and password" do
      bl_ready
      file_like_object.stub(:read).and_return("$$BLADELOGIC_USERNAME $$BLADELOGIC_PASSWORD $$APPPATH")
      AutomationCommon.bladelogic_header_file({"SS_input_file" => "file"}).should include('User pass')
    end

    it "raise error" do
      GlobalSettings.stub(:bladelogic_ready?).and_return(false)
      expect{ AutomationCommon.bladelogic_header_file ""}.to raise_error(RuntimeError)
    end
  end

  describe "#script_header_file" do
    specify "bladelogic" do
      AutomationCommon.stub(:bladelogic_header_file).and_return('/bladelogic')
      AutomationCommon.script_header_file({"SS_script_target" => "bladelogic"}).should eql('/bladelogic')
    end

    specify "ssh" do
      AutomationCommon.stub(:ssh_script_header).and_return('/ssh')
      AutomationCommon.script_header_file({"SS_script_target" => "ssh"}).should eql('/ssh')
    end

    specify "resource_automation" do
      AutomationCommon.stub(:resource_automation_script_header).and_return('/automation')
      AutomationCommon.script_header_file({"SS_script_target" => "resource_automation"}).should eql('/automation')
    end

    specify "hudson" do
      AutomationCommon.stub(:hudson_script_header).and_return('/hudson')
      AutomationCommon.script_header_file({"SS_script_target" => "hudson"}).should eql('/hudson')
    end

    specify "other" do
      AutomationCommon.script_header_file({"SS_script_target" => "some"}).should eql('other')
    end
  end

  it "#ssh_script_header" do
    file_like_object = double("file like object")
    File.stub(:open).and_return(file_like_object)
    file_like_object.stub(:read).and_return('ssh_script_header')
    AutomationCommon.ssh_script_header.should eql('ssh_script_header')
  end

  it "#hudson_script_header" do
    file_like_object = double("file like object")
    File.stub(:open).and_return(file_like_object)
    file_like_object.stub(:read).and_return('hudson_script_header')
    AutomationCommon.hudson_script_header.should eql('hudson_script_headerhudson_script_header')
  end

  it "#resource_automation_script_header" do
    AutomationCommon.stub(:hudson_script_header).and_return('hudson_script_header')
    AutomationCommon.resource_automation_script_header.should eql('hudson_script_header')
  end

  describe "#private_flag" do
    it "returns value with prefix" do
      AutomationCommon.private_flag(nil).should eql("")
    end

    it "returns empty str" do
      AutomationCommon.private_flag('val2').should eql('__SS__val2')
    end
  end

  describe "#redact" do
    it "read from file" do
      # pending "cann`t find RAILS_ROOT`"
      file_like_object = double("file like object").as_null_object
      stub_const('RAILS_ROOT', '').as_null_object
      File.stub(:open).and_return(file_like_object)
      file_like_object.stub(:read).and_return('value')
      AutomationCommon.redact(file_like_object)
    end

    it "returns value" do
      stub_const('RAILS_ROOT', '').as_null_object
      AutomationCommon.redact('val1').should eql('val1')
    end
  end

  it "#clean_script_file" do
    lines_to_clean = "params = load_input_params(ENV[\"_SS_INPUTFILE\"])\n@hand.close\ncreate_output_file(params)"+
        "params = load_input_params(os.environ[\"_SS_INPUTFILE\"])FHandle = open(params[\"SS_output_file\"], \"a\")"+
        "FHandle = open(params[\"output_file\"], \"a\")\nFHandle.close()\nbl_profile_name = os.environ[\"_SS_PROFILE\"]"+
        "bl_role_name\t= os.environ[\"_SS_ROLENAME\"]\nsys.exit(0)\n"
    AutomationCommon.clean_script_file(lines_to_clean + "some_text").should eql("some_text")
  end

  describe "#close_line" do
    it "returns sys.exit" do
      result = AutomationCommon.close_line("bladelogic")
      result.should include("FHandle.close()")
      result.should include("sys.exit(0)")
    end

    it "returns hand.close" do
      AutomationCommon.close_line("ssh").should include("@hand.close")
    end

    it "returns comment" do
      AutomationCommon.close_line("hudson").should include("#Close the file handle")
    end

    it "returns sys.exit" do
      AutomationCommon.close_line("automation").should eql("")
    end
  end

  it "#update_integration_values" do
    project_server = create(:project_server)
    result = AutomationCommon.update_integration_values("[integration_id=#{project_server.id}]/\#\=\=\=.+\=\=\= End \=\=\=\#/m", nil)
    result.should include("Hudson/Jenkins Integration Server: #{project_server.name}")
  end

  it "#hash_to_sorted_yaml" do
    AutomationCommon.hash_to_sorted_yaml({'b' => 1, 'a' => 2}).should eql("a: '2'\nb: '1'\n")
  end

  it "#hash_string" do
    AutomationCommon.hash_string({'b' => 1, 'a' => 2}).should eql("{'b'=>'1','a'=>'2'}")
  end

  def create_installed_component
    @env = create(:environment)
    @app_env = create(:application_environment, :app => app,
                      :environment => @env)
    @component = create(:component)
    @app_component = create(:application_component, :app => app,
                            :component => @component)
    @installed_component = create(:installed_component, :application_environment => @app_env,
                                  :application_component => @app_component)
  end


  def create_app_package
    @env = create(:environment)
    @app = create(:app)
    @app_env = create(:application_environment,
                      :app => @app,
                      :environment => @env)
    @package = create(:package)
    @app_package = create(:application_package,
                          :app => @app,
                          :package => @package)
  end


end
