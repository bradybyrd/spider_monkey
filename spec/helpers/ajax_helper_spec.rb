require "spec_helper"

describe AjaxHelper do
  before(:all) { @server_level = create(:server_level) }

  it "#select_current_tab" do
    helper.select_current_tab("obj").should include("obj.addClass('selected');")
  end

  it "#tab_for_server_level" do
    helper.tab_for_server_level(@server_level).should include("{ return $(this).find('a').html() == '#{@server_level.name}' }")
  end

  it "#server_level_groups_tab" do
    helper.server_level_groups_tab.should eql("$('.server_tabs #server_aspect_groups_tab')")
  end

  it "#click_server_tab" do
    helper.click_server_tab('obj').should eql("obj.find('a').click();")
  end

  it "#set_document_title" do
    helper.set_document_title('title').should eql("document.title = 'title';")
  end

  it "#set_cancel_link_for_server_level" do
    helper.set_cancel_link_for_server_level(@server_level).should include("{ return $(this).find('a').html() == '#{@server_level.name}' })")
  end

  it "#server_level_after_create_actions" do
    helper.stub(:can?).and_return(true)
    helper.server_level_after_create_actions(@server_level).should include("$.getScript(\"/environment/server_levels/#{@server_level.id}\"")
  end

  it "#server_aspect_after_save_actions" do
    helper.stub(:can?).and_return(true)
    helper.server_aspect_after_save_actions(@server_level, 1, nil).should include("$.getScript(\"/environment/server_levels/#{@server_level.id}?page=1\"")
  end

  it "#close_facebox" do
    helper.close_facebox.should eql("$.facebox.close();")
  end

  it "#image_tag_wait" do
    helper.image_tag_wait.should include('assets/waiting.gif')
  end

  it "#facebox_tag" do
    helper.facebox_tag.should include("<div class='facebox_hide facebox_overlayBG'")
  end

  it "#select_clear_links" do
    result = helper.select_clear_links(1)
    result.should include("Select All")
    result.should include("Clear")
  end

  it "#select_clear_chk" do
    result = helper.select_clear_chk(1)
    result.should include("Select All")
    result.should include("Clear")
  end

  context "#toggel_inbound_outbound_section_links" do
    it "returns hide" do
      helper.toggel_inbound_outbound_section_links.should eql("$('#inbound_outbound_request_links').hide();")
    end

    it "returns show" do
      helper.toggel_inbound_outbound_section_links(false).should eql("$('#inbound_outbound_request_links').show();")
    end
  end
end
