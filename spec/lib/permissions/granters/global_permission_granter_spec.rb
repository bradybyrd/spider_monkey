require 'spec_helper'
require 'cancan/matchers'
require 'permissions/permission_granters'

describe GlobalPermissionGranter do
  describe 'grant?' do
    it 'does not raise NotImplementedError' do
      granter = GlobalPermissionGranter.new

      expect { granter.grant?(:any, :any) }.not_to raise_error(NotImplementedError)
    end

    it 'returns true for non model objects' do
      granter = GlobalPermissionGranter.new

      expect(granter.grant?(:view_dashboard, 'main_tab')).to be_truthy
    end

    it 'returns true for model object' do
      granter = GlobalPermissionGranter.new
      app = App.new

      expect(granter.grant?(:create, app)).to be_truthy
    end
  end
end
