require 'spec_helper'

describe "steps/step_rows/step_section" do

  let(:app){create(:app, :with_installed_component)}
  let(:request){create(:request, apps:[app], environment: app.environments.last)}
  let(:package){create(:package)}

  before(:each) do
    view.stub(:current_user) { User.current_user }
    Ability.any_instance.stub(:can?).and_return(true)
    @controller.stub(:current_ability).and_return(Ability.new(User.current_user))
  end

  it "renders form with component information" do
    step = create(:step, request: request, component: app.installed_components.first.application_component.component)
    step.related_object_type = "component"

    render partial: "steps/step_rows/step_section", formats: "html", locals: {step: step, request: request}
    expect(rendered).to include(app.installed_components.first.application_component.component.name)
  end

  it "renders form with package information, latest instance" do
    step = create_package_step(false, true)

    render partial: "steps/step_rows/step_section", formats: "html", locals: {step: step, request: request}

    expect(rendered).to include(package.name)
    expect(rendered).to include(I18n.t("step.latest"))
  end

  it "renders form with package information, create new instance" do
    step = create_package_step(true, false)

    render partial: "steps/step_rows/step_section", formats: "html", locals: {step: step, request: request}
    expect(rendered).to include(package.name)
    expect(rendered).to include(I18n.t("step.create_new"))
  end

  it "renders form with package information, with select" do
    step = create_package_step(false, false)

    render partial: "steps/step_rows/step_section", formats: "html", locals: {step: step, request: request}

    expect(rendered).to include(package.name)
    expect(rendered).to include(I18n.t("select"))
  end

  def create_package_step(create_new,latest)
    create(:step,
                  request: request,
                  related_object_type: "package",
                  package: package,
                  create_new_package_instance: create_new,
                  latest_package_instance: latest
    )

  end

end
