require 'spec_helper'

describe FeedsController, type: :controller do
  it '#index' do
    get :index, {time_zone: []}
    expect(response).to be_success
  end
end