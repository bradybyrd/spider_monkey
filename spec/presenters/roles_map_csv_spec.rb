require 'spec_helper'

describe RolesMapCsv do
  let(:team) { create(:team) }
  let(:group) { create(:group) }
  let(:user) { create(:user) }
  let(:role) { create(:role) }
  let(:role_map_csv) { RolesMapCsv.new [team], [group], [user] }

  describe '#header' do
    it 'returns headers array' do
      expect(role_map_csv.header).to be_a Array
    end
  end

  describe '#append_rows' do
    it 'appends data to csv object' do
      team.stub(:roles).and_return([role])

      out = CSV.generate do |csv|
        role_map_csv.append_rows([team], csv)
      end

      expect(out.strip).to eq ['Team', team.name, role.name, role.description].join(',')
    end
  end

  describe '#row' do
    it 'returns row data' do
      expect(role_map_csv.row(team, role)).to eq ['Team', team.name, role.name, role.description]
      expect(role_map_csv.row(group, role)).to eq ['Group', group.name, role.name, role.description]
      expect(role_map_csv.row(user, role)).to eq ['User', user.name, role.name, role.description]
    end
  end

  describe '#generate' do
    it 'returns csv report' do
      header = ['Header1', 'Header2']
      role_map_csv.stub(:header).and_return(header)

      expected_output = header.join(',')
      role_map_csv.should_receive(:append_rows).exactly(3).times
      expect(role_map_csv.generate.strip).to eq expected_output
    end
  end
end