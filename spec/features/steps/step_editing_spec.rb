require 'spec_helper'

feature "Editing a Step", js: true do
  context "that has 'Package' selected, but no package associated" do
    scenario "shows the dialog correctly" do
      sign_in_as_admin
      request = create_a_request

      step_name = create_a_package_step_with_no_package(request)
      view_step(step_name)

      expect(modal_dialog).to have_title("Edit Step 1")
    end
  end

  def sign_in_as_admin
    sign_in create(:user, :root)
  end

  def create_a_request
    create(:request)
  end

  def create_a_package_step_with_no_package(request)
    step_name = SecureRandom.uuid
    visit request_path(request)
    click_on("New Step")
    fill_in("step_name", with: step_name)
    select("Package", from: "step_related_object_type")
    click_on("Add Step & Close")
    step_name
  end

  def view_step(step_name)
    find(".step_name", text: step_name).click
  end

  def modal_dialog
    find("#facebox")
  end

  def have_title(title)
    have_css("h2", text: title)
  end

  it "step has mutually exclusive package and component" do
    sign_in_as_admin
    app = create(:app, :with_installed_component)
    request = create(:request, apps:[app], environment: app.environments.last)
    step = create(:step, request: request)
    step.related_object_type = "package"
    step.save!

    visit request_path(request)
    view_step step.name
    sleep(3)
    select("Component", from: "step_related_object_type")
    sleep(1)
    component_name = app.installed_components[0].name
    select(component_name, from: "step_component_id")
    sleep(3)
    click_on("Save Step")
    sleep(5)
    expect(find(:xpath, "//td[@class='step_name']/following-sibling::td[1]")).to have_text component_name

    view_step step.name
    sleep(3)
    select("Package", from: "step_related_object_type")
    sleep(1)
    click_on("Save Step")
    sleep(5)
    expect(find(:xpath, "//td[@class='step_name']/following-sibling::td[1]")).to_not have_text component_name
  end

end
