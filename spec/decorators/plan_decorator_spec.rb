require 'spec_helper'

describe PlanDecorator do

  context 'buttons' do
    let(:plan){ mock_model Plan }
    subject(:decorator){ PlanDecorator.new(plan) }

    describe '#plan_button' do
      it 'returns plan button with proper CSS class name' do
        expect(decorator.plan_button).to have_css_class('plan_plan')
      end

      it 'returns plan button with proper URL' do
        expect(decorator.plan_button).to have_update_state_url('plan_it')
      end
    end

    describe '#start_button' do
      it 'returns plan button with proper CSS class name' do
        expect(decorator.start_button).to have_css_class('start_plan')
      end

      it 'returns plan button with proper URL' do
        expect(decorator.start_button).to have_update_state_url('start')
      end
    end

    describe '#cancel_button' do
      it 'returns plan button with proper CSS class name' do
        expect(decorator.cancel_button).to have_css_class('cancel_plan')
      end

      it 'returns plan button with proper URL' do
        expect(decorator.cancel_button).to have_update_state_url('cancel')
      end
    end

    describe '#delete_button' do
      it 'returns plan button with proper CSS class name' do
        expect(decorator.delete_button).to have_css_class('delete_plan')
      end

      it 'returns plan button with proper URL' do
        expect(decorator.delete_button).to have_update_state_url('delete')
      end
    end

    describe '#lock_button' do
      it 'returns plan button with proper CSS class name' do
        expect(decorator.lock_button).to have_css_class('lock_plan')
      end

      it 'returns plan button with proper URL' do
        expect(decorator.lock_button).to have_update_state_url('lock')
      end
    end

    describe '#hold_button' do
      it 'returns plan button with proper CSS class name' do
        expect(decorator.hold_button).to have_css_class('hold_plan')
      end

      it 'returns plan button with proper URL' do
        expect(decorator.hold_button).to have_update_state_url('hold')
      end
    end

    describe '#complete_button' do
      it 'returns plan button with proper CSS class name' do
        expect(decorator.complete_button).to have_css_class('complete_plan')
      end

      it 'returns plan button with proper URL' do
        expect(decorator.complete_button).to have_update_state_url('finish')
      end
    end

    describe '#reopen_button' do
      it 'returns plan button with proper CSS class name' do
        expect(decorator.reopen_button).to have_css_class('reopen_plan')
      end

      it 'returns plan button with proper URL' do
        expect(decorator.reopen_button).to have_update_state_url('reopen')
      end
    end

    describe '#archive_button' do
      it 'returns plan button with proper CSS class name' do
        expect(decorator.archive_button).to have_css_class('archive_plan')
      end

      it 'returns plan button with proper URL' do
        expect(decorator.archive_button).to have_update_state_url('archived')
      end
    end

    describe '#unarchive_button' do
      it 'returns plan button with proper CSS class name' do
        expect(decorator.unarchive_button).to have_css_class('unarchive_plan')
      end

      it 'returns plan button with proper URL' do
        expect(decorator.unarchive_button).to have_update_state_url('finish')
      end
    end

    def have_css_class(css_class)
      match(/class=\"#{ css_class }\"/)
    end

    def have_update_state_url(new_state)
      match(/\/plans\/#{ plan.id }\/update_state\?state=#{ new_state }/)
    end
  end

end
