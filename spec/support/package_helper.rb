module PackageHelper
  def fill_in_reference_form(attributes)
    fill_in 'Name', with: attributes[:name]
    select attributes[:server], from: 'Server'
    fill_in 'Uri', with: attributes[:uri]
  end

  def populate_server_list_with(server)
    allow(Server).to receive(:by_ability).and_return([server])
  end
end
