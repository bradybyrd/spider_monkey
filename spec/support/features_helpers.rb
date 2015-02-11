shared_examples "list page" do |options = {}|
  it "displays a page", :smoke => true do
    options[:url] ||= url
    sign_in_and_visit(options[:url])

    unless options[:skip_content_test]
      page.should have_content(main_page_content) unless main_page_content.nil?
      main_page_fields.each do |m|
        page.should have_content(object.send(m))
      end
    end
  end
end

shared_examples "edit page" do |options = {}|
  it "displays a page", :smoke => true do
    options[:url] ||= url
    sign_in_and_visit(options[:url])

    unless options[:skip_content_test]
      edit_page_fields.each do |m|
        selector = calculate_field_selector(m)
        page.should have_selector(selector)
        element = page.first(selector)
        element.value.to_s.should == object.send(m[:name]).to_s
      end
    end
  end
end

shared_examples "show page" do |options = {}|
  it "displays a page", :smoke => true do
    options[:url] ||= url
    sign_in_and_visit(options[:url])

    unless options[:skip_content_test]
      page.should have_content(main_page_content) unless main_page_content.nil?
      main_page_fields.each do |m|
        page.should have_content(object.send(m))
      end
    end
  end
end


shared_examples "new page" do |options = {}|
  it "displays a page", :smoke => true do
    options[:url] ||= url
    sign_in_and_visit(options[:url])

    unless options[:skip_content_test]
      new_page_fields.each do |m|
        selector = calculate_field_selector(m)
        page.should have_selector(selector)
        element = page.first(selector)
        element.value.to_s.should == ""
      end
    end
  end
end

module ValidUserRequestHelper
  def valid_user
    @user = create(:user)
  end

  def sign_in_as_valid_user
    sign_in(valid_user)
  end

  def sign_in(user)
    ## TODO This should work with single post request, but it doesn't and I can't figure out why
    # post_via_redirect 'session.user', 'user[login]' => valid_user.login,
    # 'user[password]' => 'secret', 'authentication' => 'basic'
    ## So instead I'm doing get, fill a form and click 'Log In'. Urgh!
    visit '/login'

    close_ssl_certificate_popup if js_driver?

    fill_in 'Login', with: user.login
    fill_in 'Password', with: user.password

    click_button 'Log In'

    ## we may use warden helper to authorize instead of the above
    ## but it requires shared db connection which seems not to be very reliable
    # login_as user
  end

  def sign_in_and_visit(url)
    sign_in_as_valid_user

    visit url
    page.status_code.should be_ok
  end

  def calculate_field_selector(field)
    id = "\##{ActiveModel::Naming.param_key(object)}_#{field[:name]}".downcase
    # if field[:required]
    #   id << ".required"
    # else
    #   id << ".optional"
    # end
    id
  end

  def close_ssl_certificate_popup
    if first(:css, "#facebox .popup a[href$='stomp.js']")
      find("#facebox .popup .fb-header a.close_facebox_button[href='#']").click
    end
  end

  def js_driver?
    Capybara.current_driver == Capybara.javascript_driver
  end
end

module PoltergeistShortcutsHelper
  def browser
    page.save_and_open_page
  end

  def screen(number = 1, model = 'screen', path = Rails.root)
    page.save_screenshot("#{path}/#{model}_#{number}_#{Time.now.to_i}.png")
  end
end
