require 'spec_helper'

# Specs in this file have access to a helper object that includes
# the PackageInstancesHelper. For example:
#
# describe PackageInstancesHelper do
#   describe "string concat" do
#     it "concats two strings with spaces" do
#       expect(helper.concat_strings("this","that")).to eq("this that")
#     end
#   end
# end
describe PackageInstancesHelper do
  it "generates a list of linked request numbers this package was on" do
    allow(helper).to receive(:can?).and_return(true)
    package_instance = create(:package_instance)
    create_pair(:step, package_instance: package_instance)
    request_links = request_links_for(package_instance)

    recent_activity = helper.recent_activity_for(package_instance)

    expect(recent_activity).to eq "#{request_links.first} and #{request_links.second}"
  end

  it "links to a request if the request can be accessed" do
    allow(helper).to receive(:can?).and_return(true)

    response = helper.link_request_if_accessible(:foo)

    expect(response).to eq '<a href="/requests/foo">foo</a>'
  end

  it "does not link to a request if the request cannot be accessed" do
    allow(helper).to receive(:can?).and_return(false)

    response = helper.link_request_if_accessible(:foo)

    expect(response).to be_nil
  end

  it "checks the permissions for viewing requests lists" do
    allow(Request).to receive(:new).and_return(:new)
    allow(helper).to receive(:can?).and_return(true)

    expect(helper.requests_accessible?).to be_truthy
    expect(helper).to have_received(:can?).with(:view_requests_list, :new)
  end

  def request_links_for(package_instance)
    request_numbers = package_instance.requests.map(&:number)
    request_numbers.map do |request_number|
      link_to request_number, request_path(request_number)
    end
  end
end
