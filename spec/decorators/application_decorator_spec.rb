require 'spec_helper'

describe ApplicationDecorator do

  describe '#association_expandable_links' do
    let(:object){ double 'Object' }
    subject{ ApplicationDecorator.new(object).association_expandable_links(links) }

    context 'when number of links passed is greater than ApplicationDecorator::NUMBER_OF_LINKS_TO_SHOW' do
      let(:links){ (0...ApplicationDecorator::NUMBER_OF_LINKS_TO_SHOW).map{ |i| "Link #{ i }" } }

      it 'returns comma separated list of links' do
        expect(subject).to match(links.join(', '))
      end

      it 'visible links are in VISIBLE_EXPANDABLE_LINKS_CLASS' do
        expect(subject).to match(ApplicationDecorator::VISIBLE_EXPANDABLE_LINKS_CLASS)
      end

      it 'does not return "Show more" link' do
        expect(subject).not_to match(ApplicationDecorator::SHOW_MORE_LINK_CLASS)
      end
    end

    context 'when number of links passed is lesser than ApplicationDecorator::NUMBER_OF_LINKS_TO_SHOW' do
      let(:links){ (0...ApplicationDecorator::NUMBER_OF_LINKS_TO_SHOW+2).map{ |i| "Link #{ i }" } }

      it 'returns comma separated list of visible links' do
        expect(subject).to match(links[0...ApplicationDecorator::NUMBER_OF_LINKS_TO_SHOW].join(', '))
      end

      it 'returns comma separated list of hidden links' do
        expect(subject).to match(links[ApplicationDecorator::NUMBER_OF_LINKS_TO_SHOW..-1].join(', '))
      end

      it 'visible links are wrapped in VISIBLE_EXPANDABLE_LINKS_CLASS' do
        expect(subject).to match(ApplicationDecorator::VISIBLE_EXPANDABLE_LINKS_CLASS)
      end

      it 'hidden links are wrapped in HIDDEN_EXPANDABLE_LINKS_CLASS' do
        expect(subject).to match(ApplicationDecorator::HIDDEN_EXPANDABLE_LINKS_CLASS)
      end

      it 'returns "Show more" link' do
        expect(subject).to match(ApplicationDecorator::SHOW_MORE_LINK_CLASS)
      end
    end
  end

end
