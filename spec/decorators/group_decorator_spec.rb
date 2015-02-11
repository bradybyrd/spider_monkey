require 'spec_helper'

describe GroupDecorator do

  describe '#link' do
    let(:group){ mock_model Group }
    subject(:decorator){ GroupDecorator.new(group) }

    it 'returns edit link to object with object name' do
      url = double('URL')
      expect(h).to receive(:edit_group_path).with(group).and_return(url)
      link = double('Link')
      expect(h).to receive(:link_to).with(group.name, url).and_return(link)

      expect(decorator.link).to eq(link)
    end
  end

end
