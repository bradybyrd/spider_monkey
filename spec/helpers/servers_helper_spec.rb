require "spec_helper"

describe ServersHelper do
  describe '#servers_tab_path' do
    it 'returns servers path by default' do
      allow(helper).to receive(:cannot?).and_return(false)
      expect(helper.servers_tab_path). to eq servers_path
    end

    it 'returns server groups_path' do
      allow(helper).to receive(:cannot?).and_return(true)
      allow(helper).to receive(:can?).with(:list, an_instance_of(ServerGroup)).and_return(true)

      expect(helper.servers_tab_path). to eq server_groups_path
    end

    it 'returns server aspect groups path' do
      allow(helper).to receive(:cannot?).and_return(true)
      allow(helper).to receive(:can?).with(:list, an_instance_of(ServerGroup)).and_return(false)
      allow(helper).to receive(:can?).with(:list, an_instance_of(ServerAspectGroup)).and_return(true)

      expect(helper.servers_tab_path). to eq server_aspect_groups_path
    end
  end
end