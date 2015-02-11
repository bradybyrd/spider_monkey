require "spec_helper"
include ApplicationHelper
include ERB::Util

shared_examples "abstract_step_path", :shared => true do |method, path|
  specify "#{path} for request step" do
    send(method, @request1, @step1).should eql(send(path, @request1,@step1.id))
  end

  specify "#{path} for procedure step" do
    send(method, @request1, @step2).should eql(send(path, @request1, @step2.parent_id, {:step_id => @step2.id}))
  end
end

describe StepsHelper do
  before(:each) do
    @user = create(:user)
    User.current_user = @user
    helper.stub(:current_user).and_return(@user)
    @request1 = create(:request_with_app)
    @app = @request1.apps.first
    @step1 = create(:step, :request => @request1, :owner => @user)
    @step2 = create(:step, :request => @request1, :owner => @user)
    @step2.parent_id = @step1.id
  end

  it "#treeview_element_render" do
    treeview_element_render.should include('$("#tree_renderer").dynatree')
  end

  describe "#disable_automation_tasks?" do
    it "returns true" do
      expect(@step1).to receive(:enabled_editing?).and_return(false)
      expect(helper.disable_automation_tasks?(@step1)).to be_truthy
    end

    it "returns false" do
      expect(@step1).to receive(:enabled_editing?).and_return(true)
      expect(helper.disable_automation_tasks?(@step1)).to be_falsey
    end
  end

  describe "template_item" do
    before(:each) do
      @app = create(:app)
      @component = create(:component)
      @app_component = create(:application_component, :app => @app, :component => @component)
      @package_template = create(:package_template, :app => @app, :name => 'PT1', :version => '2')
      @component_template = ComponentTemplate.create(:name => "CT_name",
                                                     :app_id => @app.id,
                                                     :application_component_id => @app_component.id)
      @pt_item = create(:package_template_item,
                        :package_template => @package_template,
                        :component_template => @component_template)
      @step1.package_template_id = @package_template.id
    end

    context "returns command value" do
      it "of template_item" do
        @pt_item["commands"]['command'] = true
        template_item_command_value(nil, @pt_item, 'command').should be_truthy
      end

      it "of step" do
        @step1[:package_template_properties] = {"#{@pt_item.id}" => {'undo_command' => true}}
        template_item_command_value(@step1, @pt_item, 'undo_command').should be_truthy
      end
    end

    context "returns property value" do
      before(:each) do
        @property = create(:property, :name => 'prop_name')
        @property_value = create(:property_value, :property => @property,
                                                  :value_holder_id => @component.id)
      end

      it "of template_item" do
        @pt_item["properties"]['prop_name'] = 'Value1'
        template_item_property_value(nil, @pt_item, @property_value).should eql('Value1')
      end

      it "of step" do
        @step1[:package_template_properties] = {"#{@pt_item.id}" => {'prop_name' => 'Value2'}}
        template_item_property_value(@step1, @pt_item, @property_value).should eql('Value2')
      end
    end
  end

  describe "#hour_minute_estimate" do
    it "returns '0:00'" do
      hour_minute_estimate(nil).should eql("0:00")
    end

    it "returns estimate" do
      hour_minute_estimate(100).should eql("1:40")
    end
  end

  it "#user_owner_chosen_for" do
    user_owner_chosen_for(@step1).should be_truthy
  end

  describe "#procedure_attr_for_edit" do
    it "returns name" do
      procedure_attr_for_edit(@step1, 'name').should eql(@step1.name)
    end

    it "returns '[edit]'" do
      procedure_attr_for_edit(@step1, 'parent_id').should eql('[edit]')
    end
  end

  describe "#script_argument_value_output_display" do
    before(:each) { helper.stub(:ignore_current_script_arguments).and_return(false) }

    it "returns BladelogicScriptArgument" do
      @script = create(:bladelogic_script)
      @argument = @script.arguments.first
      @step_argument = @step1.step_script_arguments.create(:script_argument => @argument, :value => 'val1')
      script_argument_value_output_display(@step1, @argument).should eql(@step_argument.value)
    end

    it "returns Value Not Set" do
      @script = create(:general_script)
      @argument = @script.arguments.first
      @step_argument = @step1.step_script_arguments.create(:script_argument => @argument)
      script_argument_value_output_display(@step1, @argument).should include("Value Not Set")
    end

    describe "argument type " do
      before(:each) do
        @script = create(:general_script)
        @argument = @script.arguments.first
        @step_argument = @step1.step_script_arguments.create(:script_argument => @argument, :value => [:step])
        @value = @step_argument.value.first
      end

      specify "'out-text'" do
        @argument.argument_type = "out-text"
        script_argument_value_output_display(@step1, @argument).should eql(@value)
      end

      specify "'out-email'" do
        @argument.argument_type = "out-email"
        script_argument_value_output_display(@step1, @argument).should eql("<a href=\"mailto:#{@value}\">#{@value}</a>")
      end

      specify "'out-url'" do
        @argument.argument_type = "out-url"
        script_argument_value_output_display(@step1, @argument).should eql("<a href=\"#{@value}\" target=\"_blank\">#{@value}</a>")
      end

      specify "'out-file'" do
        @argument.argument_type = "out-file"
        script_argument_value_output_display(@step1, @argument).should eql("<a href=\"/environment/scripts/download_files?path=\">#{@value}</a>")
      end

      describe "'out-date'" do
        before(:each) { @argument.argument_type = "out-date" }

        it "returns 'Invalid Date'" do
          script_argument_value_output_display(@step1, @argument).should include("Invalid Date")
        end

        it "returns text fild with date" do
          @step_argument.value = '20131217'
          @step_argument.save
          script_argument_value_output_display(@step1, @argument).should include("12/17/2013")
        end
      end

      specify "'out-time'" do
        @step_argument.value = [Time.now]
        @step_argument.save
        @argument.argument_type = "out-time"
        @value = @step_argument.value.first
        script_argument_value_output_display(@step1, @argument).should include("#{@value}")
      end

      specify "'out-list'" do
        @step_argument.value = "request"
        @step_argument.save
        @argument.argument_type = "out-list"
        @value = @step_argument.value
        script_argument_value_output_display(@step1, @argument).should include('request')
      end

      specify "'out-table'" do
        pending "what params for table_type_argument_body"
        @step_argument.value = [{:data => [['adasdas'],['adasdas']], :perPage => 20, :totalItems => 40}]
        @step_argument.save
        @argument.argument_type = "out-table"
        @value = @step_argument.value
        script_argument_value_output_display(@step1, @argument).should include("#{@value}")
      end

      specify "'out-user-single'" do
        @step_argument.value = 'request'
        @step_argument.save
        @argument.argument_type = "out-user-single"
        @value = @step_argument.value
        script_argument_value_output_display(@step1, @argument).should include("#{User.first.login}")
      end

      specify "'out-user-multi'" do
        @step_argument.value = 'request'
        @step_argument.save
        @argument.argument_type = "out-user-multi"
        @value = @step_argument.value
        script_argument_value_output_display(@step1, @argument).should include("#{User.first.login}")
      end

      describe "'out-server-" do
        before(:each) do
          @server = create(:server)
          @env = create(:environment)
          @environment_server = create(:environment_server, :environment => @env,
                                       :server => @server,
                                       :server_aspect => nil)
          @step_argument.value = 'request'
          @step_argument.save
          @value = @step_argument.value
        end

        specify "single'" do
          @argument.argument_type = "out-server-single"
          script_argument_value_output_display(@step1, @argument).should include("#{@server.name}")
        end

        specify "multi'" do
          @argument.argument_type = "out-server-multi"
          script_argument_value_output_display(@step1, @argument).should include("#{@server.name}")
        end
      end

      specify "'out-external-single'" do
        @step_argument.value = 'request'
        @step_argument.save
        @argument.argument_type = "out-external-single"
        @value = @step_argument.value
        script_argument_value_output_display(@step1, @argument).should include("#{@value}")
      end

      specify "'out-external-multi'" do
        @step_argument.value = 'request'
        @step_argument.save
        @argument.argument_type = "out-external-multi"
        @value = @step_argument.value
        script_argument_value_output_display(@step1, @argument).should include("#{@value}")
      end

      specify "'none'" do
        @step_argument.value = [12]
        @step_argument.save
        @argument.argument_type = "none"
        @value = @step_argument.value.first
        script_argument_value_output_display(@step1, @argument).should eql(@value)
      end
    end
  end

  describe "#script_argument_value_input_display" do
    before(:each) do
      create_installed_component
      @script = create(:general_script)
      @argument = @script.arguments.first
    end

    context "argument type " do
      before(:each) { helper.stub(:can?).and_return(true) }

      specify "none" do
        @argument.argument_type = "none"
        helper.script_argument_value_input_display(@step1, @argument, @installed_component).should include("#{@argument.id}")
      end

      specify "in-text" do
        @script.arguments.each{ |el| el.external_resource = 'Res1'
                                     el.save }
        @script2 = create(:general_script, :unique_identifier => 'Res1')
        helper.stub(:should_include_select_tag?).and_return(true)
        helper.stub(:cannot?).and_return(false)
        @argument.argument_type = "in-text"
        helper.script_argument_value_input_display(@step1, @argument, @installed_component).should include("parent_argument=\"true\">")
      end

      specify "in-list-single" do
        @argument.argument_type = "in-list-single"
        @argument.list_pairs = "List_pair"
        helper.script_argument_value_input_display(@step1, @argument, @installed_component).should include("id=\"script_argument_#{@argument.id}\"")
      end

      specify "in-list-multi" do
        @argument.argument_type = "in-list-multi"
        @argument.list_pairs = "List_pair"
        helper.script_argument_value_input_display(@step1, @argument, @installed_component).should include("id=\"script_argument_#{@argument.id}\"")
      end

      specify "in-user-single-select" do
        @argument.argument_type = "in-user-single-select"
        helper.script_argument_value_input_display(@step1, @argument, @installed_component).should include("#{User.first.first_name}")
      end

      specify "in-user-multi-select" do
        @argument.argument_type = "in-user-multi-select"
        helper.script_argument_value_input_display(@step1, @argument, @installed_component).should include("#{User.first.first_name}")
      end

      context "in-server-" do
        before(:each) do
          @server = create(:server)
          @env = create(:environment)
          @environment_server = create(:environment_server, :environment => @env,
                                       :server => @server,
                                       :server_aspect => nil)
        end

        specify "single-select" do
          @argument.argument_type = "in-server-single-select"
          helper.script_argument_value_input_display(@step1, @argument, @installed_component).should include("#{@server.name}")
        end

        specify "multi-select" do
          @argument.argument_type = "in-server-multi-select"
          helper.script_argument_value_input_display(@step1, @argument, @installed_component).should include("#{@server.name}")
        end
      end

      specify "in-date" do
        @argument.argument_type = "in-date"
        helper.script_argument_value_input_display(@step1, @argument, @installed_component, "17/12/2013").should include("12/17/2013")
      end

      specify "in-time" do
        @argument.argument_type = "in-time"
        helper.script_argument_value_input_display(@step1, @argument, @installed_component, Time.now).should include("#{Time.now}")
      end

      specify "in-datetime" do
        @argument.argument_type = "in-datetime"
        helper.script_argument_value_input_display(@step1, @argument, @installed_component, "19/12/2013").should include("12/19/2013")
      end

      specify "in-file" do
        @argument.argument_type = "in-file"
        helper.script_argument_value_input_display(@step1, @argument, @installed_component).should include("<div class='argument_upload_form'>")
      end

      context "in-external-single-select" do
        it "renders tree view" do
          @script.arguments.each{ |el| el.external_resource = 'Res1'
                                       el.save }
          @script.unique_identifier = 'Res1'
          @script.render_as = 'Tree'
          @script.save
          @argument.argument_type = "in-external-single-select"
          helper.script_argument_value_input_display(@step1, @argument, @installed_component, 'Val1').should include("Val1")
        end

        it "renders script_argument_value_single" do
          helper.stub(:log_automation_errors).and_return(true)
          @script.arguments.each{ |el| el.external_resource = 'Res1'
                                       el.save }
          @script2 = create(:general_script, :unique_identifier => 'Res1')
          @script2.arguments.delete_all
          @argument.argument_type = "in-external-single-select"
          helper.script_argument_value_input_display(@step1, @argument, @installed_component, nil, true).should include("<div ><input class=\"step_script_argument\"")
        end

        it "renders input_div" do
          @script.arguments.each{ |el| el.external_resource = 'Res1'
                                       el.save }
          @script2 = create(:general_script, :unique_identifier => 'Res1')
          @argument.argument_type = "in-external-single-select"
          helper.script_argument_value_input_display(@step1, @argument, @installed_component, 'val1').should include("val1")
        end
      end

      context "in-external-multi-select" do
        it "renders tree view" do
          @script.arguments.each{ |el| el.external_resource = 'Res1'
                                   el.save }
          @script.unique_identifier = 'Res1'
          @script.render_as = 'Tree'
          @script.save
          @argument.argument_type = "in-external-multi-select"
          helper.script_argument_value_input_display(@step1, @argument, @installed_component, 'Val1').should include("Val1")
        end

        it "renders script_argument_value_single" do
          helper.stub(:log_automation_errors).and_return(true)
          @script.arguments.each{ |el| el.external_resource = 'Res1'
                                    el.save }
          @script2 = create(:general_script, :unique_identifier => 'Res1')
          @script2.arguments.delete_all
          @argument.argument_type = "in-external-multi-select"
          helper.script_argument_value_input_display(@step1, @argument, @installed_component, nil, true).should include("<div ><input class=\"step_script_argument\"")
        end

        it "renders input_div" do
          @script.arguments.each{ |el| el.external_resource = 'Res1'
                                    el.save }
          @script2 = create(:general_script, :unique_identifier => 'Res1')
          @argument.argument_type = "in-external-multi-select"
          helper.script_argument_value_input_display(@step1, @argument, @installed_component, 'val1').should include("val1")
        end
      end
    end
  end

  it "#script_argument_value_select_tag" do
    @value = 1
    helper.stub(:cannot?).and_return(false)
    @script = create(:bladelogic_script)
    @argument = @script.arguments.first
    helper.script_argument_value_select_tag(@step1, @argument, nil, @value).should include("<select class=\"step_script_argument\" id=\"bladelogic_script_argument_#{@argument.id}\" name=\"argument[#{@argument.id}][]\">")
  end

  describe "#render_table_or_tree_view" do
    before(:each) do
      @value = 1
      @script = create(:general_script)
      @argument = @script.arguments.first
      @script2 = create(:general_script, :render_as => 'Table')
      @script2.arguments.delete_all
      helper.stub(:eval_script).and_return({:perPage => 10, :totalItems => 20})
    end

    it "renders as table" do
      helper.render_table_or_tree_view(@step1, @argument, nil, @value, @script2).should include("#{@value}")
    end

    it "renders as tree" do
      @script2.render_as = 'Tree'
      @script2.save
      helper.render_table_or_tree_view(@step1, @argument, nil, @value, @script2).should include("#{@value}")
    end

    it "renders as text" do
      helper.render_table_or_tree_view(@step1, @argument, nil, @value, @script).should include("#{@value}")
    end
  end

  it "#table_type_argument_body" do
    @value = 1
    @script = create(:general_script)
    @argument = @script.arguments.first
    @hash_data = {:perPage => 10,
                  :totalItems => 20,
                  :data => [['header0', 'header1'],["data0", 'data1']]}
    table_type_argument_body(@argument.id, @hash_data, @value, @step1).should include("<table argument_value=\"#{@value}\"")
  end

  it "#table_type_argument" do
    @value = 1
    @script = create(:general_script)
    @argument = @script.arguments.first
    @hash_data = {:perPage => 10,
                  :totalItems => 20,
                  :data => [['header0', 'header1'],["data0", 'data1']]}
    table_type_argument(@argument, @hash_data, @value, @step1, @script).should include("id=\"table_argument_with_pagination_container_#{@argument.id}\"")
  end

  it "#mapped_table_type_argument" do
    @script = create(:general_script)
    @argument = @script.arguments.first
    @hash_data = {:perPage => 10,
                  :totalItems => 20,
                  :data => [['header0', 'header1'],["data0", 'data1']]}
    mapped_table_type_argument(@argument.id, @hash_data).should include("id=\"table_argument_with_pagination_container_#{@argument.id}\"")
  end

  describe "#script_argument_value_single_select_tag" do
    before(:each) do
      @value = 1
      @script = create(:general_script, :unique_identifier => 'Res1')
      @argument = @script.arguments.first
      @argument.external_resource = 'Res1'
      @argument.save
      @argument2 = @script.arguments.last
      @argument2.external_resource = 'Res2'
      @argument2.save
      @script2 = create(:general_script, :unique_identifier => 'Res2')
      helper.stub(:can?).and_return(true)
      helper.stub(:eval_script).and_return(['0' => :flatten_hashes])
    end

    it "returns select with depends_on" do
      helper.script_argument_value_single_select_tag(@step1, @argument, nil).should include("depends_on")
    end

    it "returns select without depends_on" do
      @script.arguments.delete_all
      helper.script_argument_value_single_select_tag(@step1, @argument, nil).should include("<option value=\"flatten_hashes\">0</option>")
    end
  end

  describe "#script_argument_value_multi_select_tag" do
    before(:each) do
      @value = 1
      @script = create(:general_script, :unique_identifier => 'Res1')
      @argument = @script.arguments.first
      @argument.external_resource = 'Res1'
      @argument.save
      @argument2 = @script.arguments.last
      @argument2.external_resource = 'Res2'
      @argument2.save
      @script2 = create(:general_script, :unique_identifier => 'Res2')
      helper.stub(:can?).and_return(true)
      helper.stub(:eval_script).and_return(['0' => :flatten_hashes])
    end

    it "returns select with depends_on" do
      helper.script_argument_value_multi_select_tag(@step1, @argument, nil).should include("depends_on")
    end

    it "returns select without depends_on" do
      @script.arguments.delete_all
      helper.script_argument_value_multi_select_tag(@step1, @argument, nil).should include("<option value=\"flatten_hashes\">0</option>")
    end
  end

  it "#orig_script_argument_value_input_tag_value" do
    create_installed_component
    @script = create(:general_script)
    @argument = @script.arguments.first
    @argument.stub(:values_from_properties).and_return(['val1'])
    orig_script_argument_value_input_tag_value(@step1, @argument, @installed_component).should eql('val1')
  end

  describe "#step_category_available_for?" do
    it "returns true" do
      @category = create(:category, :categorized_type => 'step')
      step_category_available_for?(nil, 'problem').should eql(true)
    end

    it "returns false" do
      @category = create(:category, :categorized_type => 'step', :associated_events => ['resolve'])
      step_category_available_for?(nil, 'problem').should eql(false)
    end
  end

  describe "#step_row_class" do
    before(:each) do
      helper.stub(:can?).and_return(true)
    end

    context "for step editable by current user" do
      subject(:step_row_classes) { helper.step_row_class(@step1, true, nil, @request1) }

      it "contains 'step'" do
        expect(step_row_classes).to match("step")
      end

      it "contains 'listable'" do
        expect(step_row_classes).to match("listable")
      end

      it "contains 'different_level_from_previous'" do
        expect(step_row_classes).to match("different_level_from_previous")
      end

      it "contains 'incomplete_step'" do
        expect(step_row_classes).to match("incomplete_step")
      end

      it "contains 'unfolded'" do
        expect(step_row_classes).to match("unfolded")
      end

      it "contains 'has_access'" do
        expect(step_row_classes).to match("has_access")
      end
    end

    context "for step with parent" do
      subject(:step_row_classes) { helper.step_row_class(@step2, true, nil) }

      it "contains 'step'" do
        expect(step_row_classes).to match("step")
      end

      it "contains 'different_level_from_previous'" do
        expect(step_row_classes).to match("different_level_from_previous")
      end

      it "contains 'incomplete_step'" do
        expect(step_row_classes).to match("incomplete_step")
      end

      it "contains 'procedure_step'" do
        expect(step_row_classes).to match("procedure_step")
      end

      it "contains 'unfolded'" do
        expect(step_row_classes).to match("unfolded")
      end

      it "contains parent" do
        expect(step_row_classes).to match("parent_#{@step1.id}")
      end
    end

    context "for last step with parent" do
      subject(:step_row_classes) { helper.step_row_class(@step2, true, nil) }
      # @last_proc_step = @step2
      it "contains 'step'" do
        expect(step_row_classes).to match("step")
      end

      it "contains 'different_level_from_previous'" do
        expect(step_row_classes).to match("different_level_from_previous")
      end

      it "contains 'incomplete_step'" do
        expect(step_row_classes).to match("incomplete_step")
      end

      it "contains 'procedure_step'" do
        expect(step_row_classes).to match("procedure_step")
      end

      it "contains 'unfolded'" do
        expect(step_row_classes).to match("unfolded")
      end

      it "contains parent" do
        expect(step_row_classes).to match("parent_#{@step1.id}")
      end

    end
  end

  it "#step_section_row_class" do
    step_section_row_class(@step1, true, nil, true).should eql('container delete_with_parent last')
  end

  describe "#step_type_class" do
    it "returns 'step'" do
      step_type_class(@step1).should eql('step')
    end

    it "returns 'procedure_step'" do
      step_type_class(@step2).should eql('procedure_step')
    end
  end

  describe "#completion_class" do
    it "returns nothing" do
      completion_class(@step1).should eql('')
    end

    it "returns 'completed_step'" do
      @request1.plan_it!
      @request1.start!
      @step1.reload
      @step1.lets_start!
      completion_class(@step1).should eql('completed_step')
    end
  end

  it_should_behave_like("abstract_step_path", 'abstract_request_step_path', 'request_step_path')
  it_should_behave_like("abstract_step_path", 'abstract_edit_request_step_path', 'edit_request_step_path')
  it_should_behave_like("abstract_step_path", 'abstract_update_status_request_step_path', 'update_status_request_step_path')
  it_should_behave_like("abstract_step_path", 'abstract_add_category_request_step_path', 'add_category_request_step_path')
  it_should_behave_like("abstract_step_path", 'abstract_update_position_request_step_path', 'update_position_request_step_path')
  it_should_behave_like("abstract_step_path", 'abstract_toggle_execution_request_step_path', 'toggle_execution_request_step_path')

  describe "step_form_header" do
    context "new record" do
      specify "procedure step" do
        @step1.stub(:new_record?).and_return(true)
        step_form_header(@step1).should eql("New Step 3 ")
      end

      specify "request step" do
        @step2.stub(:new_record?).and_return(true)
        step_form_header(@step2).should eql("New Step 1.1 ")
      end
    end

    it "old record" do
      @step1.stub(:new_record?).and_return(false)
      step_form_header(@step1).should include("Edit Step 1")
    end
  end

  describe "#procedure_step_form_header" do
    before(:each) { @procedure = create(:procedure) }
    it "returns 'New Step'" do
      @step1.stub(:new_record?).and_return(true)
      procedure_step_form_header(@step1, @procedure).should eql('New Step 1 ')
    end

    it "returns 'Edit Step'" do
      procedure_step_form_header(@step1, @procedure).should eql("&nbsp;&nbsp; Edit Step #{@step1.number} ")
    end
  end

  it "#step_reorder_title" do
    step_reorder_title(@step1).should eql('Estimate: none, Complete by: N/A, Version: none, Servers: none')
  end

  it "#refresh_steps_list" do
    helper.stub(:current_user).and_return(create(:user))
    User.stub(:current_user).and_return(create(:user))
    helper.stub(:can?).and_return(true)
    refresh_steps_list(@request1).should include("$('#steps_container').html")
  end

  describe '#procedure_edit_in_place' do
    it 'renders partial' do
      allow(helper).to receive(:can?).and_return(true)
      allow(@step1).to receive(:editable_by?).and_return(true)
      expect(helper.procedure_edit_in_place(@request1, @step1, 'position')).to render_template(partial: 'steps/step_rows/_edit_procedure')
    end

    it 'returns attribute if no permission' do
      allow(helper).to receive(:can?).and_return(false)
      allow(@step1).to receive(:editable_by?).and_return(true)
      expect(helper.procedure_edit_in_place(@request1, @step1, 'position')).to eq @step1.position.to_s
    end

    it 'returns attribute if not editable' do
      allow(helper).to receive(:can?).and_return(true)
      allow(@step1).to receive(:editable_by?).and_return(false)
      expect(helper.procedure_edit_in_place(@request1, @step1, 'position')).to eq @step1.position.to_s
    end
  end

  it "#procedurein_place" do
    procedurein_place(@request1, create(:user), @step1, 'position').should eql("#{@step1.position}")
  end

  it "#link_to_request_with_open_step" do
    helper.stub(:can?).and_return(true)
    helper.link_to_request_with_open_step(@request1, @step1).should eql("<a href=\"/requests/#{@request1.number}?unfolded_steps=#{@step1.id}\">1</a>")
  end

  describe "#step_attribute_value" do
    it "returns attr" do
      step_attribute_value('position').should eql('position')
    end

    it "returns span" do
      step_attribute_value(nil).should eql("<span class=\"no_value\">unspecified</span>")
    end
  end

  it "#version_change_message" do
    version_change_message("2").should eql("Newest version of this installed component is 2")
  end

  describe "results_hyperlink" do
    it "returns nothing" do
      @note = create(:note)
      results_hyperlink(@note).should eql('')
    end

    it "returns error" do
      @note = "[Script output written to:  automation_results/"
      results_hyperlink(@note).should eql("Couldn't locate output file link")
    end

    it "returns link" do
      @note = "[Script output written to:  automation_results/]\n"
      results_hyperlink(@note).should include("Automation run full results")
    end
  end

  describe "#common_owner_type_of" do
    it "returns true" do
      @steps = @request1.steps.where(:id => [@step1.id, @step2.id]).group_by(&:id)
      common_owner_type_of(@steps).should eql(true)
    end

    it "returns false" do
      @step1.owner_id = create(:group).id
      @step1.owner_type = "Group"
      @step1.save
      @steps = @request1.steps.where(:id => [@step1.id, @step2.id]).group_by(&:id)
      common_owner_type_of(@steps).should eql(false)
    end
  end

  it "#common_attribute_id_of" do
    @steps = @request1.steps.where(:id => [@step1.id, @step2.id]).group_by(&:id)
    @step = create(:step)
    common_attribute_id_of(@steps, 'owner_type').should eql(@step.owner_type)
  end

  it "#common_app_id_of" do
    @steps = [@step1, @step2]
    common_app_id_of(@steps).should eql(@app.id)
  end

  it "#common_component_id_of" do
    @steps = @request1.steps.where(:id => [@step1.id, @step2.id]).group_by(&:id)
    @component = create(:component)
    @step = create(:step, :component_id => @component.id)
    common_component_id_of(@steps).should eql(@component.id)
  end

  it "#ics_of_selected_steps" do
    @component = create(:component)
    @step = create(:step, :request => @request1)
    @step.request.stub(:common_components_installed_on_env_of_app).and_return(@component)
    ics_of_selected_steps(@steps).should eql(@component)
  end

  it "#display_note" do
    @note = create(:note, :user => create(:user))
    @note.object.stub(:auto?).and_return(true)
    display_note(@note).should include("<span class='user_date'>#{@note.user.name}")
  end

  it "#link_to_step_of_request" do
    link_to_step_of_request(@step1, "title", @request1).should eql("<a href=\"/requests/#{@request1.number}/edit#step_#{@step1.id}_#{@step1.position}_heading\" target=\"_blank\">title</a>")
  end

  it "#link_to_on_off_step" do
    link_to_on_off_step(@step1).should eql("<a class=\"ON\" href=\"#\" id=\"step_#{@step1.id}_should_execute\" onclick=\"change_step_status($(this)); return false;\">ON</a>")
  end

  describe "#bulk_update_page_title" do
    specify "modify_task_phase" do
      @operation = "modify_task_phase"
      bulk_update_page_title.should include("Modify Step Task/Phase")
    end

    specify "modify_app_component" do
      @operation = "modify_app_component"
      bulk_update_page_title.should include("Modify Step Application and Component")
    end

    specify "modify_assignment" do
      @operation = "modify_assignment"
      bulk_update_page_title.should include("Modify Step Assignment")
    end

    specify "modify_should_execute" do
      @operation = "modify_should_execute"
      bulk_update_page_title.should include("Turn ON/OFF Steps")
    end
  end

  it "#count_of_steps_selected_for_bulk_edit" do
    @steps = [@step1,@step2]
    count_of_steps_selected_for_bulk_edit.should include("#{@steps.count}")
  end

  it "#app_name_for_components" do
    @step1.app_id = @app.id
    app_name_for_components(@step1).should eql(@app.name)
  end

  it "#find_step_from_hash" do
    @steps = {@step1.id => [@step1]}
    find_step_from_hash(@step1.id).should eql(@step1)
  end

  describe "#switch_class_hold_step" do
    it "returns 'hold_column_width'" do
      @request1.plan_it!
      @request1.start_request!
      @request1.put_on_hold!
      switch_class_hold_step(@request1).should eql("hold_column_width")
    end

    it "returns state_column_width" do
      switch_class_hold_step(@request1).should eql("state_column_width")
    end
  end

  describe "#server_is_selected?" do
    before(:each) { @server = create(:server) }

    it "returns true" do
      server_is_selected?(@server, [], []).should be_truthy
    end

    specify "server_aspect" do
      server_is_selected?(@server, [], [@server.id]).should be_truthy
    end

    specify "server" do
      server_is_selected?(@server, [@server.id], []).should be_truthy
    end
  end

  it "#note_content" do
    @note = create(:note)
    note_content(@note).should eql("#{@note.content}")
  end

  describe "#disable_all_form_fields" do
    before(:each) do
      @user = create(:user)
      helper.stub(:current_user).and_return(@user)
    end

    it "returns true" do
      helper.stub(:can?).and_return(false)
      helper.disable_all_form_fields(@step1).should eql(true)
    end
  end

  it "#options_for_users_groups_from_collection_for_select" do
    @group = create(:group)
    @user = create(:user)
    options_for_users_groups_from_collection_for_select([@user], [@group], @step1).should include("#{@group.id}")
  end

  describe "#find_scripts" do
    it "returns nothing" do
      GlobalSettings[:automation_enabled] = false
      find_scripts(@step1).should eql([])
    end

    it "returns Bladelogic scripts" do
      @step1.script_type = "BladelogicScript"
      GlobalSettings[:bladelogic_enabled] = true
      @script = create(:bladelogic_script)
      GlobalSettings.stub(:automation_available?).and_return(true)
      find_scripts(@step1).should include(@script)
    end

    it "returns automation scripts" do
      GlobalSettings[:automation_enabled] = true
      @script = create(:general_script, :automation_type => 'BMC Bladelogic', aasm_state: 'pending')
      @step1.script_type = "General"
      find_scripts(@step1).should include(@script)
    end
  end

  describe "#tree_node_selection_mode" do
    it "returns 1" do
      tree_node_selection_mode("in-external-single-select").should eql(1)
    end

    it "returns 2" do
      tree_node_selection_mode("in-text").should eql(2)
    end
  end

  describe '#step_has_invalid_component?' do
    it 'returns true if component is present in the app' do
      component = create(:component)
      app = create(:app, components: [component])
      procedure = create(:procedure, apps: [app])
      step = create(:step, procedure_id: procedure.id, component: component, request: nil)

      expect(step_has_invalid_component?(procedure, step)).to be_falsey
    end

    it 'returns false if component is not included in the app' do
      component = create(:component)
      app = create(:app)
      procedure = create(:procedure, apps: [app])
      step = create(:step, procedure_id: procedure.id, component: component, request: nil)

      expect(step_has_invalid_component?(procedure, step)).to be_truthy
    end
  end

  describe '#task_column_value' do
    context 'manual' do
      let(:step) { create(:step) }

      it 'return nil when work task is absent' do
        res = task_column_value(step, {})
        expect(res).to be_nil
      end

      it 'return work task name' do
        res = task_column_value(step, {'work_task' => 'WorkTask1'})
        expect(res).to eq 'WorkTask1'
      end
    end

    context 'automation' do
      let(:step) { create(:step_with_script, manual: false) }

      it "return 'SCRIPT DELETED' when script is missing" do
        step.script_id = 0
        res = task_column_value(step, nil)
        expect(res).to eq I18n.t('step.script_deleted')
      end

      it 'return script name' do
        res = task_column_value(step, nil)
        expect(res).to eq step.script.name
      end
    end
  end

  describe '#task_column_title' do
    let(:step) { create(:step) }
    context 'step with protect automation' do
      before(:each) { step.protect_automation_tab = true }
      context 'task_val is nil' do
        it 'return message about protect automation only' do
          res = task_column_title(step, nil)
          expect(res).to eq 'This step have protected automation'
        end
      end
      context 'task_val have value' do
        it 'return message with task_val and about protect automation' do
          res = task_column_title(step, 'Some message')
          expect(res).to eq "Some message\nThis step have protected automation"
        end
      end
    end
    context 'step w/o protect automation' do
      context 'task_val is nil' do
        it 'return empty message' do
          res = task_column_title(step, nil)
          expect(res).to eq ''
        end
      end
      context 'task_val have value' do
        it 'return message with task_val only' do
          res = task_column_title(step, 'Some message')
          expect(res).to eq 'Some message'
        end
      end
    end
  end

  def create_installed_component
    @env = create(:environment)
    @app_env = create(:application_environment, :app => @app,
                      :environment => @env)
    @component = create(:component)
    @app_component = create(:application_component, :app => @app,
                            :component => @component)
    @installed_component = create(:installed_component, :application_environment => @app_env,
                                  :application_component => @app_component)
  end

  describe '#association_or_new_instance' do

    context 'with a step and its valid association' do
      let(:step) { build :step, request: request }
      let(:request) { build :request }

      it 'returns steps requests' do
        expect(helper.association_or_new_instance(step, :request)).to eq request
      end
    end

    context 'with a step and empty association' do
      let(:step) { build :step }

      it 'returns steps requests' do
        expect(helper.association_or_new_instance(step, :request)).to be_an_instance_of Request
      end
    end

    context 'without a step' do
      it 'returns steps requests' do
        expect(helper.association_or_new_instance(nil, :request)).to be_an_instance_of Request
      end
    end

    context 'with non existing association' do
      context 'without a step' do
        it 'raise NameError' do
          expect{(helper.association_or_new_instance(nil, :non_existing_association))}.to raise_error NameError
        end
      end

      context 'with a step' do
        let(:step) { build :step }

        it 'raise NameError' do
          expect{(helper.association_or_new_instance(step, :non_existing_association))}.to raise_error NameError
        end
      end
    end

  end

  describe '#can_show_design_tab?' do
    let(:user) { @user }

    before { helper.stub(:can?).with(:view_step_design_tab, anything).and_return(false) }

    context 'request not created' do
      let(:step) { create :step, request: request }
      let(:request) { create(:request).tap { |request| request.plan_it! } }

      it 'returns false' do
        expect(helper.can_show_design_tab?(step)).to be false
      end
    end

    context 'step not locked' do
      let(:request) { create :request, aasm_state: 'created' }
      let(:step) { create :step, request: request, aasm_state: 'ready' }

      it 'returns false' do
        expect(helper.can_show_design_tab?(step)).to be false
      end
    end

    context 'user' do
      let(:step) { create :step, request: request, aasm_state: 'locked' }

      context 'has no permission, not an owner and not a requestor' do
        let(:request) { create :request, aasm_state: 'created' }

        it 'returns false' do
          expect(helper.can_show_design_tab?(step)).to be false
        end
      end

      context 'has permission' do
        let(:request) { create :request, aasm_state: 'created' }

        it 'returns true' do
          helper.stub(:can?).with(:view_step_design_tab, anything).and_return(true)

          expect(helper.can_show_design_tab?(step)).to be true
        end
      end

      context 'owner' do
        let(:request) { create :request, aasm_state: 'created', owner_id: user.id }

        it 'returns true' do
          expect(helper.can_show_design_tab?(step)).to be true
        end
      end

      context 'requestor' do
        let(:request) { create :request, aasm_state: 'created', requestor_id: user.id }

        it 'returns true' do
          expect(helper.can_show_design_tab?(step)).to be true
        end
      end
    end
  end

  describe '#disabled_step_editing?' do
    context 'user is able to edit step' do
      it 'returns false' do
        helper.stub(:association_or_new_instance).and_return(Request.new)
        helper.stub(:can?).with(:edit_step, anything).and_return(true)
        step = create :step

        expect(helper.disabled_step_editing?(step)).to be_falsey
      end
    end

    context 'step is enabled for editing' do
      it 'returns false' do
        helper.stub(:can?).with(:edit_step, anything).and_return(false)
        step = create :step
        step.stub(:enabled_editing?).with(@user).and_return(true)

        expect(helper.disabled_step_editing?(step)).to be_falsey
      end
    end

    context 'user is not able to edit step and step is not enabled for editing' do
      it 'returns true' do
        helper.stub(:association_or_new_instance).and_return(Request.new)
        helper.stub(:can?).with(:edit_step, anything).and_return(false)
        step = create :step
        step.stub(:enabled_editing?).with(@user).and_return(false)

        expect(helper.disabled_step_editing?(step)).to be_truthy
      end
    end
  end
end
