require 'spec_helper'

# avoid calling of configure method in TorqueBox::Stomp::JmsStomplet
# from EventableStomplet configure as super
# class TorqueBox::Stomp::JmsStomplet
#   def configure(*args)
#     # do nothing
#     @mark_from_redefined_configure_method = true
#   end
# end
load 'eventable_stomplet.rb'
class EventableStompletBinder
  def public_prepare_attributes(*args)
    prepare_attributes(*args)
  end
  def public_publish(*args)
    publish(*args)
  end
end

describe EventableStompletBinder do
  let(:model) {mock "Some Model"}

  let(:binder) do
    EventableStompletBinder.any_instance.stub(:fetch).with('/topics/stomplets/event_bindable').and_return destination
    EventableStompletBinder.new(attributes, renderer)
  end

  let(:attributes){["Attribute1", "Attribute2"]}
  let(:renderer){mock "Renderer"}
  let(:destination){"Some destination"}

  it "should get destination by fetch method" do
    binder.instance_variable_get(:@destination).should == destination
  end

  it{binder.instance_variable_get(:@attributes).should == attributes}
  it{binder.instance_variable_get(:@renderer).should == renderer}

  describe "events" do
    let(:events){%w[create update destroy]}
    let(:events_hash){Hash[events.collect{|e| ["after_#{e}",e]}]}

    it "events should call publish with appropriate args" do
    model.stub(:changed).and_return ["updated_at", "some other attribute"]
      events_hash.each do |k,v|
        binder.should_receive(:publish).with(model, {:event => v})
        binder.send(k, model)
      end
    end

    it "shouldn't push message when changed only updated_at" do
      model.stub(:changed).and_return ["updated_at"]
      binder.should_not_receive(:publish).with(any_args)
      binder.after_update(model)
    end
  end
end
