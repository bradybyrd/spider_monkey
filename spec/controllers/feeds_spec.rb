require 'spec_helper'

describe FeedsController, :type => :controller do
  it "#index" do
    get :index, {:time_zone => []}
    response.should be_success
  end
end