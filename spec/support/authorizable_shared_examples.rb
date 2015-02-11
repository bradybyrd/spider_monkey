shared_examples 'main tabs authorizable' do |options|
  controller_action = options[:controller_action]
  ability_object = options[:ability_object]
  params = options[:params] || {}

  # context 'authorized' do
  #   include_context 'mocked abilities', :can, :view, ability_object

  #   it 'succeds', authorization: ability_object do
  #     get controller_action, params
  #     expect(response.status).to eq 200
  #     # expect(response).to be_authorized
  #   end
  # end

  context 'unauthorized' do
    include_context 'mocked abilities', :cannot, :view, ability_object

    it 'redirects', type: :authorization,
                    authorization: ability_object,
                    custom_roles: true do
      get controller_action, params
      expect(response).to redirect_to root_path
    end
  end
end

shared_examples 'authorizable' do |options|
  let(:http_method)       { options[:http_method] || :get }
  let(:controller_action) { options[:controller_action] }
  let(:type)              { options[:type] }
  let(:params)            { options[:params] || {} } unless respond_to?(:params)

  let(:attributes_to_send) {
    [ http_method, controller_action, params ]
      .tap { |attributes| attributes.unshift(type) if type.present? }
  }

  before do
    sign_in create :old_user, root: false, admin: false
  end

  ability_action     = options[:ability_action]
  subject            = options[:subject]

  # context 'authorized' do
  #   include_context 'mocked abilities', :can, ability_action, subject

  #   it 'succeds', authorization: ability_action do
  #     send *attributes_to_send
  #     # expect(response.status).to eq 200
  #     # expect(response).to be_authorized
  #     # controller.should_receive(:authorize!).with(ability_action, subject)
  #     # controller.should_not_receive(:access_denied!)
  #     expect(controller).to_not raise_error(CanCan::AccessDenied)
  #   end
  # end

  context 'unauthorized' do
    include_context 'mocked abilities', :cannot, ability_action, subject

    it 'redirects', type: :authorization,
                    authorization: ability_action,
                    custom_roles: true do
      send *attributes_to_send
      if type == :xhr
        expect(response).to render_template 'misc/redirect'
      else
        expect(response).to redirect_to root_path
      end
    end
  end
end
