require 'spec_helper'

describe FalseClassExtensions do
  class Wrapper
    include FalseClassExtensions
  end

  let(:wrapper) { Wrapper.new }

  it "#to_bool" do
    wrapper.to_bool.should be_falsey
  end

  it "#nil_or_empty?" do
    wrapper.nil_or_empty?.should be_falsey
  end
end
