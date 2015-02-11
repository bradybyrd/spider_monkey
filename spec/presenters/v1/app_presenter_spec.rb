require 'spec_helper'
require 'nokogiri'

describe V1::AppsPresenter do
  describe '#to_xml', import_export: true do
    context 'without Request Templates' do
      it 'not include procedures at all' do
        options = { export_xml: true, optional_components: {} }
        presenter = V1::AppsPresenter.new application_with_procedures, template=nil, options

        doc = Nokogiri::XML presenter.to_xml

        expect(doc.css('app > active-procedures')).to be_empty
      end
    end

    context 'with Request Templates' do
      it 'includes active procedure' do
        active_procedure = create :procedure, :with_steps
        draft_procedure = create :procedure, :draft
        archived_procedure = create :procedure, :archived
        application_with_procedures = create :app, procedures: [ active_procedure,
                                                                 draft_procedure,
                                                                 archived_procedure ]
        options = { export_xml: true, optional_components: [:req_templates] }

        presenter = create_app_presenter_for(application_with_procedures, options)

        expect(procedure_names_list).to include active_procedure.name
      end

      it 'does not include draft procedure' do
        active_procedure = create :procedure, :with_steps
        draft_procedure = create :procedure, :draft
        archived_procedure = create :procedure, :archived
        application_with_procedures = create :app, procedures: [ active_procedure,
                                                                 draft_procedure,
                                                                 archived_procedure ]
        options = { export_xml: true, optional_components: [:req_templates] }

        presenter = create_app_presenter_for(application_with_procedures, options)

        expect(procedure_names_list).not_to include draft_procedure.name
      end

      it 'does not include archived procedure' do
        active_procedure = create :procedure, :with_steps
        draft_procedure = create :procedure, :draft
        archived_procedure = create :procedure, :archived
        application_with_procedures = create :app, procedures: [ active_procedure,
                                                                 draft_procedure,
                                                                 archived_procedure ]
        options = { export_xml: true, optional_components: [:req_templates] }

        presenter = create_app_presenter_for(application_with_procedures, options)

        expect(procedure_names_list).not_to include archived_procedure.name
      end

      it 'includes name field' do
        options = { export_xml: true, optional_components: [:req_templates] }

        presenter = create_app_presenter_for(application_with_procedures, options)

        expect(@doc.css('app > active-procedures > active-procedure > name')).not_to be_empty
      end

      it 'includes aasm_state field' do
        options = { export_xml: true, optional_components: [:req_templates] }

        presenter = create_app_presenter_for(application_with_procedures, options)

        expect(@doc.css('app > active-procedures > active-procedure > aasm-state')).not_to be_empty
      end

      it 'includes description field' do
        options = { export_xml: true, optional_components: [:req_templates] }

        presenter = create_app_presenter_for(application_with_procedures, options)

        expect(@doc.css('app > active-procedures > active-procedure > description')).not_to be_empty
      end

      it 'includes steps' do
        options = { export_xml: true, optional_components: [:req_templates] }

        presenter = create_app_presenter_for(application_with_procedures, options)

        expect(@doc.css('app > active-procedures > active-procedure > steps > step').size).to eq(2)
      end

      def procedure_names_list
        @doc.css('app > active-procedures > active-procedure > name').map { |element| element.children.text }
      end
    end

    def application_with_procedures
      create :app, procedures: [ active_procedure,
                                 draft_procedure,
                                 archived_procedure ]
    end

    def active_procedure
      create(:procedure, :with_steps)
    end

    def draft_procedure
      create(:procedure, :draft)
    end

    def archived_procedure
      create(:procedure, :archived)
    end

    def create_app_presenter_for(application, options)
      presenter = V1::AppsPresenter.new application, template=nil, options
      @doc = Nokogiri::XML presenter.to_xml
      presenter
    end
  end
end
