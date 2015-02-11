require 'spec_helper'

describe FusionChartsHelper do
  let(:wrapper){
    class MyModuleWrapper
      include FusionChartsHelper
      include ActionView::Helpers::TextHelper

      def logger
      end

      def output_buffer=(some)
        some
      end
    end
    MyModuleWrapper.new
  }

  before(:each) { wrapper.logger.stub(:info).and_return(true) }

  describe "#render_chart" do
    before(:each) do
      buffer = mock_model("Buffer")
      wrapper.stub(:output_buffer).and_return(buffer)
      wrapper.stub(:save_concat).and_return(buffer)
      buffer.stub(:<<).and_return(true)
    end

    specify "with str_data" do
      result = wrapper.render_chart('chart', '/root', 'data', '1', 100, 100, false, false, {:w_mode => true, :color => 'black'})
      result.should be_truthy
    end

    specify "str_data nil" do
      result = wrapper.render_chart('chart', '/root', '', '1', 100, 100, false, false, {:w_mode => true, :color => 'black'})
      result.should be_truthy
    end
  end

  describe "#render_chart_html" do
    before(:each) do
      buffer = mock_model("Buffer")
      wrapper.stub(:output_buffer).and_return(buffer)
      wrapper.stub(:save_concat).and_return(buffer)
      buffer.stub(:<<).and_return(true)
    end

    specify "with str_data" do
      result = wrapper.render_chart_html('chart', '/root', 'data', '1', 100, 100, false, false, {:w_mode => true, :color => 'black'})
      result.should be_truthy
    end

    specify "str_data nil" do
      result = wrapper.render_chart_html('chart', '/root', '', '1', 100, 100, false, false, {:w_mode => true, :color => 'black'})
      result.should be_truthy
    end
  end

  it "# render_chart_get_xml_from_action" do
    buffer = mock_model("Buffer")
    wrapper.stub(:render_component).and_return('new')
    wrapper.stub(:output_buffer).and_return(buffer)
    buffer.stub(:<<).and_return(true)
    wrapper.render_chart_get_xml_from_action('chart', 'Request', 'new', {}, '1', 100, 100).should be_truthy
  end

  it "#enable_FC_print_manager_js" do
    wrapper.stub(:safe_concat).and_return("<% script type='text/javascript' %><% !--\n FusionCharts.printManager.enabled(true);\n// --%>\n<% /script %>")
    wrapper.enable_FC_print_manager_js.should include("FusionCharts.printManager.enabled(true);")
  end

  describe "#add_cache_to_data_url" do

    specify "url with arg" do
      wrapper.add_cache_to_data_url('/root?one').should include('/root?one&FCCurrTime=')
    end

    specify "url without arg" do
      wrapper.add_cache_to_data_url('/root').should include('/root?FCCurrTime=')
    end
  end

  it "#get_UTF8_BOM" do
    wrapper.get_UTF8_BOM.should_not include('\xEF\xBB')
  end
end
