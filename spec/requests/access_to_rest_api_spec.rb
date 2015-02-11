require 'spec_helper'

describe 'REST API' do
  it 'allows any user from root group to use it' do
    non_root_group  = create :group, root: false
    root_group      = create :group, root: true
    root_user       = create :user, groups: [non_root_group, root_group]
    token           = root_user.api_key
    url             = "v1/users?token=#{token}"

    get url, json_headers

    expect(response.status).not_to eq 403
  end

  it 'denies any user from not root group to use it' do
    user  = create :user, :non_root
    token = user.api_key
    url   = "v1/users?token=#{token}"

    get url, json_headers

    expect(response.status).to eq 403
  end
end