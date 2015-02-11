require 'spec_helper'

# avoid calling of configure method in TorqueBox::Stomp::JmsStomplet
# from EventableStomplet configure as super
class TorqueBox::Stomp::JmsStomplet
  def configure(*args)
    # do nothing
    @mark_from_redefined_configure_method = true
  end
end
load 'eventable_stomplet.rb'
class EventableStomplet
  def public_prepare_selector(*args)
    prepare_selector(*args)
  end
end

describe EventableStomplet do
  let(:destination){"Some destination"}
  let(:stomplet) do
    res = EventableStomplet.new
    res.instance_variable_set(:@destination, destination)
    res
  end
  let(:model){"Model Name"}
  let(:id_num){12}
  let(:event){"update"}
  let(:selector){"Some selector"}

  describe "configuration" do
    it "should configure destination" do
      stomplet_config = mock 'StompletConfig'
      dest_mock = mock 'Destination'
      stomplet_config.should_receive(:[]).with('destination').and_return(destination)
      stomplet.should_receive(:fetch).with(destination).and_return(dest_mock)
      #TorqueBox::Stomp::JmsStomplet.any_instance.should_receive(:configure).and_return(true)
      stomplet.configure(stomplet_config)

      stomplet.instance_variable_get(:@destination).should == dest_mock
      stomplet.instance_variable_get(:@mark_from_redefined_configure_method).should be true
    end
  end

  describe "on_message" do
    it "process on_message method with id and module" do
      message = mock "Message"
      session = mock "Session"
      message_params = mock "Message Params"
      message_params.should_receive(:[]).with('model').and_return(model)
      message_params.should_receive(:[]).with('id').and_return(id_num)
      message.stub(:headers).and_return(message_params)
      stomplet.should_receive(:send_to).with(destination, message, {:id => "12", :model => "model name"})

      stomplet.on_message(message, session)
    end
  end

  describe "on_subscribe" do
    it "process on_subscribe method with event, module and selector" do
      subscriber = mock "Subscriber"
      subscriber.should_receive(:get_parameter).with('model').and_return(model)
      subscriber.should_receive(:get_parameter).with('event').and_return(event)
      subscriber.should_receive(:get_parameter).with('selector').and_return(selector)

      selector_prepared = "asdf"
      stomplet.should_receive(:prepare_selector).with(selector).and_return(selector_prepared)
      selector_matcher = /model\s*=\s*\'#{model}\'\s+and\s+event\s*=\s*\'#{event}\'\sand\s#{selector_prepared}/
      stomplet.should_receive(:subscribe_to).with(subscriber, destination, selector_matcher)

      stomplet.on_subscribe(subscriber)
    end
  end

  describe "prepare_selector" do
    let(:url){"v1=1&v2=string&v1=11&v3=21"}
    subject(:prepared_selector){stomplet.public_prepare_selector url}
    # test in clouse
    it{should match /v1\s+in\s+\(\'1\',\s*\'11\'\)\s+/}
    #test string
    it{should match /v2\s*=\s*\'string\'\s+/}
    #test number
    it{should match /v3\s*=\s*\'21\'/}
    #test and
    it{prepared_selector.split(/\s+and\s+/).size.should == 3}
  end
end