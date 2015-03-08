require 'spec_helper'
describe ApplicationHelper do

  before(:each) do
    helper.stub(:current_user).and_return(create(:old_user))
    helper.stub(:can?).and_return(true)
  end

  context '#tab_actions' do
    specify 'without prefix' do
      @content_for_tab_actions = 'Content'
      helper.tab_actions(nil).should eql('Content')
    end

    specify 'with prefix' do
      @content_for_step_tab_actions = 'Content'
      helper.tab_actions('step').should eql('Content')
    end
  end

  it '#main_tab' do
    helper.main_tab('Requests', path: '/index').should eql("<li class=\"\"><a href=\"/index\">Requests</a></li>")
  end

  it '#drop_down_for_plans' do
    pending 'Stack level too deep'
    expect(helper.drop_down_for_plans).to render_template(partial: 'plans/_top_tabs')
  end

  it '#drop_down_for_environments' do
    allow(helper).to receive(:cannot?).with(:list, an_instance_of(Server)).and_return(false)
    expect(helper.drop_down_for_environments).to render_template(partial: 'account/_environment_tabs')
  end

  it '#drop_down_for_users' do
    expect(helper.drop_down_for_users).to render_template(partial: 'users/_tabs')
  end

  it '#drop_down_for_reports' do
    expect(helper.drop_down_for_reports).to render_template(partial: 'reports/_tabs')
  end

  it '#drop_down_for_settings' do
    expect(helper.drop_down_for_settings).to render_template(partial: 'account/_tabs')
  end

  it '#drop_down_for_requests' do
    pending 'Stack level too deep'
    helper.drop_down_for_requests.should include('<a href=Calendar')
  end

  context '#main_tab_current?' do
    it 'returns if' do
      helper.main_tab_current?('Requests', if: 'result').should eql('result')
    end

    it 'returns true' do
      helper.main_tab_current?('Requests', or: true).should eql(true)
    end
  end

  context '#sub_tab' do
    it 'returns model' do
      @request1 = create(:request)
      helper.sub_tab(@request1).should eql("<li class=\"\"><a href=\"/requests/#{@request1.number}\">#{@request1.name}s</a></li>")
    end

    it 'returns name' do
      helper.sub_tab('Requests').should eql("<li class=\"\"><a href=\"/requests\">Requests</a></li>")
    end
  end

  it '#next_level_sub_tab' do
    expect(helper.next_level_sub_tab('Requests')).to render_template('account/_tabs')
  end

  it '#sub_tab_html' do
    helper.sub_tab_html('Requests', class: 'class',
                                    selected: 'selected',
                                    path: '/index').should eql("<li class=\"selected class\"><a href=\"/index\">Requests</a></li>")
  end

  it '#plan_sub_tabs' do
    helper.plan_sub_tabs('Requests', '/index', 1).should eql("<li class=\"\"><a href=\"/index\">Requests</a></li>")
  end

  it '#plan_sub_tab_html' do
    helper.plan_sub_tab_html('Requests', '/index', true, nil, 1).should eql("<li class=\"selected\"><a href=\"/index\">Requests</a></li>")
  end

  context '#page_settings' do
    it 'sets page title' do
      page_settings(title: 'Title')
      @page_title.should eql('Title')
    end

    it 'sets page heading' do
      page_settings({heading: 'Head'})
      @page_heading.should eql('Head')
    end

    it 'sets page content class' do
      page_settings({content_class: 'Class'})
      @page_content_class.should eql('Class')
    end

    it 'sets full_screen' do
      page_settings({full_screen: true})
      @full_screen.should be_truthy
    end

    it 'sets store_url' do
      page_settings({store_url: '/index'})
      @store_url.should eql('/index')
    end

    it 'sets custom_heading' do
      page_settings({custom_heading: true})
      @custom_heading.should be_truthy
    end
  end

  context '#flash_div' do
    it 'returns nothing' do
      helper.flash_div(nil).should eql('<div class="flash_messages"></div>')
    end

    it 'returns div' do
      flash[:error] = 'Error'
      helper.flash_div(:error).should eql("<div class=\"flash_messages\"><div id=\"flash_error\"><span>Error</span></div></div>")
    end
  end

  context '#class_for_component_color' do
    before(:each) { @request1 = create(:request) }

    it 'returns color_4' do
      @request1.stub(:should_execute).and_return(false)
      helper.class_for_component_color(@request1).should eql('component_color_4')
    end

    it 'returns color_11' do
      @step = create(:step, request: @request1)
      @step.stub(:should_execute).and_return(true)
      helper.class_for_component_color(@step).should eql('component_color_11')
    end

    it 'returns color of component' do
      @step = create(:step, request: @request1)
      @step.stub(:should_execute).and_return(true)
      @step.component_id = 1
      helper.class_for_component_color(@step).should eql('component_color_1')
    end
  end

  context '#name_of' do
    it 'returns name' do
      @request1 = create(:request)
      helper.name_of(@request1).should eql("#{@request1.name}")
    end

    it 'returns nothing' do
      helper.name_of(@request1).should eql('')
    end
  end

  it '#note_span' do
    helper.note_span('str').should eql("<span class=\"note\">str</span>")
  end

  it '#application_name' do
    application_name.should eql('smart|release')
  end

  it '#navigation_tab' do
    helper.navigation_tab('title', '/index', true).should eql("<li class=\"selected\"><a href=\"/index\">title</a></li>")
  end

  it '#default_format_date' do
    helper.default_format_date(Date.today).should eql(Date.today.strftime(GlobalSettings[:default_date_format]).split(' ')[0])
  end

  context '#load_swfobject_js' do
    specify 'don`t display report`' do
      load_swfobject_js.should eql("<script src=\"/assets/swfobject.js\"></script>")
    end

    specify 'display report' do
      @display_report = true
      load_swfobject_js.should eql("<script src=\"/assets/amcharts/swfobject.js\"></script>")
    end
  end

  context '#include_additional_javascripts' do
    it 'includes requests.js' do
      helper.stub(:params).and_return({controller: 'requests'})
      helper.include_additional_javascripts.should include("<script src=\"/assets/requests.js\"></script>")
    end

    it 'includes shared_resource_automation.js' do
      helper.stub(:params).and_return({controller: 'plans'})
      helper.include_additional_javascripts.should include("<script src=\"/assets/shared_resource_automation.js\"></script>")
    end

    it 'includes activities.js' do
      helper.stub(:params).and_return({controller: 'activities'})
      helper.include_additional_javascripts.should include("<script src=\"/assets/activities.js\"></script>")
    end

    it 'includes resources.js' do
      helper.stub(:params).and_return({controller: 'resources'})
      helper.include_additional_javascripts.should include("<script src=\"/assets/resources.js\"></script>")
    end

    it 'includes properties.js' do
      helper.stub(:params).and_return({controller: 'properties'})
      helper.include_additional_javascripts.should include("<script src=\"/assets/drag_and_drop/draggable_object.js\"></script>")
    end

    it 'includes apps.js' do
      helper.stub(:params).and_return({controller: 'apps'})
      helper.include_additional_javascripts.should include("<script src=\"/assets/apps.js\"></script>")
    end

    it 'includes environment.js' do
      helper.stub(:params).and_return({controller: 'environment'})
      helper.include_additional_javascripts.should include("<script src=\"/assets/parameter_mappings.js\"></script>")
    end

    it 'includes account.js' do
      helper.stub(:params).and_return({controller: 'account'})
      helper.include_additional_javascripts.should include("<script src=\"/assets/unsaved_changes_warning.js\"></script>")
    end

    it 'includes nothing' do
      helper.stub(:params).and_return({controller: 'nothing'})
      helper.include_additional_javascripts.should eql(nil)
    end
  end

  context '#static_javascript_include_tag' do
    it 'returns path with assets' do
      helper.static_javascript_include_tag('requests').should eql("<script src=\"/assets/requests.js\"></script>")
    end

    it 'returns root path' do
      helper.static_javascript_include_tag('/requests').should eql("<script src=\"/requests.js\"></script>")
    end
  end

  context '#absolute_url' do
    it 'returns host with port' do
      helper.request.stub(:port).and_return('8080')
      helper.absolute_url.should eql('test.host:8080')
    end

    it 'returns host without port' do
      helper.absolute_url.should eql('test.host')
    end
  end

  it '#label_as_per_use_case' do
    helper.label_as_per_use_case.should eql('Project')
  end

  it '#activity_or_project?' do
    helper.activity_or_project?.should eql('Project')
  end

  context '#activity_or_project_image?' do
    it 'returns activity.png' do
      helper.stub(:activity_or_project?).and_return('Activity')
      helper.activity_or_project_image?.should include('btn-create-activity.png')
    end

    it 'returns project.png' do
      helper.activity_or_project_image?.should include('btn-create-project.png')
    end
  end

  context '#is_web' do
    specify 'http' do
      helper.is_web('http://root').should eql('root')
    end

    specify 'https' do
      helper.is_web('https://root').should eql('root')
    end
  end

  context '#ordinalize' do
    specify '112th' do
      helper.ordinalize(112).should eql('112th')
    end

    specify '21st' do
      helper.ordinalize(21).should eql('21st')
    end

    specify '22nd' do
      helper.ordinalize(22).should eql('22nd')
    end

    specify '23rd' do
      helper.ordinalize(23).should eql('23rd')
    end

    specify '14th' do
      helper.ordinalize(14).should eql('14th')
    end
  end

  it '#mask_value' do
    helper.mask_value('val').should eql('&lt;private&gt;')
  end

  it '#to_sentence' do
    helper.to_sentence(%w(val1 val2)).should eql('val1 and val2')
  end

  it '#environment_link' do
    @env = create(:environment)
    helper.environment_link(@env).should eql("<a href ='environment/environments/#{@env.id}/edit'>#{@env.name}</a>")
  end

  it '#index_title' do
    helper.index_title('title').should eql('<strong>title</strong>')
  end

  it '#server_link' do
    @server = create(:server)
    helper.server_link(@server).should eql("<a href = 'environment/servers/#{@server.id}/edit'>#{@server.name}</a>")
  end

  context '#paginate_range' do
    before(:each) do
      @plan = create(:plan)
      @plans = Plan.entitled(create(:old_user))
      @plans = @plans.paginate(page: 1, per_page: 25)
    end

    it 'returns Found no matching plans' do
      helper.paginate_range('Plan', @plans, 0).should eql('Found no matching plans.')
    end

    it 'returns Displaying' do
      helper.paginate_range('Plan', @plans , 10).should eql('Displaying 1-10 of 10 plans.')
    end
  end

  it '#complete_image_tag' do
    helper.complete_image_tag('/root').should eql("<img alt=\"Root\" src=\"/root\" />")
  end

  it '#default_logo' do
    helper.default_logo.should eql("<img alt=\"Bmc_logo\" src=\"/assets/bmc_logo.jpg\" />")
  end

  it '#pagination_servers_search_letter' do
    pending "Don't in use and don`t work correctly`"
    @server = create(:server)
    helper.pagination_servers_search_letter(Server, 'Serv').should eql('1')
  end

  it '#search_box' do
    helper.search_box('environment').should include("id=\"search_button\" onclick=\"search();\"")
  end

  context '#generate_link_to_or_not' do
    it 'returns link' do
      helper.generate_link_to_or_not('Name', '/root', true).should eql(link_to 'Name', '/root')
    end

    it 'returns name' do
      helper.generate_link_to_or_not('Name', '/root', false).should eql('Name')
    end
  end

  context '#boolean_to_label' do
    it 'returns yes' do
      helper.boolean_to_label('val1').should eql('Yes')
    end

    it 'returns no' do
      helper.boolean_to_label.should eql('No')
    end
  end

  it '#context_root' do
    helper.context_root.should eql('')
  end

  it '#get_version_from_file' do
    helper.get_version_from_file.should eql('4.6.00.02')
  end

  it '#get_version_and_build_from_file' do
    helper.get_version_and_build_from_file.should start_with('4.6.00')
  end

  context '#convert_seconds_to_hhmm' do
    it 'returns --:--' do
      helper.convert_seconds_to_hhmm(nil).should eql('--:--')
    end

    it 'success' do
      helper.convert_seconds_to_hhmm(4200).should eql('01:10')
    end
  end

  context '#truncate_middle' do
    it 'returns full str' do
      helper.truncate_middle('string', {max: 6}).should eql('string')
    end

    it 'returns ...' do
      helper.truncate_middle('string', {max: 3}).should eql('...')
    end
  end

  describe '#link_to_if_with_custom_text' do
    it 'returns link with link text' do
      link_to_if_with_custom_text(true, 'link_text', 'plain_text', 'path').should eql(link_to 'link_text', 'path')
    end

    it 'returns plain custom text' do
      link_to_if_with_custom_text(false, 'link_text', 'plain_text', 'path').should eql(content_tag :span, 'plain_text')
    end
  end

  describe '#state_indicator_row' do
    context 'user does not have permissions to update state of object' do
      it 'does not show arrows' do
        object = create :procedure
        object.stub(:state_info).and_return({ 'states' => { 'draft' => '',
                                                            'pending' => '',
                                                            'released' => '',
                                                            'retired' => '',
                                                            'archived' => ''},
                                              'previous_state_transition' => 'make_private', #make_private|begin_testing|release|archival|retire|reopen
                                              'next_state_transition' => 'release',
                                              'previous_state' => '',
                                              'next_state' => ''
                                            })
        object.stub(:can_change_aasm_state?).and_return(true)
        user = create(:old_user)
        user.stub(:can?).with(:update_state, object).and_return(false)
        helper.stub(:current_user).and_return(user)

        expect(helper.state_indicator_row(object)).not_to include('&lt;&lt;', '&gt;&gt;')
      end
    end

    context 'user has permissions to update state of object' do
      it 'shows arrows' do
        object = create :procedure
        object.stub(:state_info).and_return({ 'states' => { 'draft' => '',
                                                            'pending' => '',
                                                            'released' => '',
                                                            'retired' => '',
                                                            'archived' => ''},
                                              'previous_state_transition' => 'make_private', #make_private|begin_testing|release|archival|retire|reopen
                                              'next_state_transition' => 'release',
                                              'previous_state' => '',
                                              'next_state' => ''
                                            })
        object.stub(:can_change_aasm_state?).and_return(true)
        user = create(:old_user)
        user.stub(:can?).with(:update_state, object).and_return(true)
        helper.stub(:current_user).and_return(user)

        expect(helper.state_indicator_row(object)).to include('&lt;&lt;', '&gt;&gt;')
      end
    end
  end
end
