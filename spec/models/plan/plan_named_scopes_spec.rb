require 'spec_helper'

describe Plan do
  describe '#entitled' do
    it 'returns all the plans for root user' do
      create :plan, name: 'I am so tired of writing specs for other people...'
      user = build :user, :root

      expect(Plan.entitled(user)).to eq Plan.all
    end

    it 'returns all the planes for user having list permissions' do
      create :plan, name: 'Like, really. It is getting annoying'
      user = create :user, :with_role_and_group
      add_permission(user, 'View Plans list')

      expect(Plan.entitled(user)).to eq Plan.all
    end
  end

  def add_permission(user, name)
    permissions_list = PermissionsList.new
    permissions = user.groups.first.roles.first.permissions
    permissions << create(:permission, permissions_list.permission(name))
  end
end