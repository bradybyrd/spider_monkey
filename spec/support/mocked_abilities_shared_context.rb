shared_context 'mocked abilities' do |ability, action, subject|
  before do
    @ability = Object.new
    @ability.extend(CanCan::Ability)

    case ability
    when :can
      @ability.can(action, subject) { true }
    when :cannot
      @ability.cannot(action, subject) { true }
    else
    end

    @controller.stub(:current_ability).and_return(@ability)

    MainTabs.stub(:root_path).and_return(root_path)
  end
end
