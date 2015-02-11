require 'spec_helper'

describe '/v1/apps', import_export: true do
  before :each do
    @user = create(:user)
    create(:team, name: '[default]')
  end

  let(:base_url) { '/v1/apps' }
  let(:json_root) { :app }
  let(:xml_root) { 'app' }
  let(:import_root) { 'app_import/app' }
  let(:params) { {token: @user.api_key} }
  subject { response }


  describe 'import app_import xml with no servers' do
    app_name = "import_app_with_packages_no_servers"
    let(:url) { "#{base_url}/?token=#{@user.api_key}" }

    it_behaves_like 'successful request', type: :xml, method: :post, status: 201 do
      xml_content = File.open("spec/data/#{app_name}.xml", "r").read
      let(:added_app) { App.where(name: app_name).first }
      let(:imported_hash) { Hash.from_xml(xml_content) }
      let(:params) { xml_content }

      subject { response.body }

      it { should have_xpath("#{xml_root}/id").with_text(added_app.id) }
      it { should have_xpath("#{xml_root}/name").with_text(added_app.name) }

      it "has imported packages" do
        imported_packages.each do |xml_package|
          package = Package.where(name: xml_package["name"]).first
          expect(package).to_not be_nil
          expect(package.instance_name_format).to eq xml_package["instance_name_format"]
        end
      end

      it "has package instances" do
        imported_packages.each do |xml_package|
          package = Package.where(name: xml_package["name"]).first
          xml_package["package_instances"].each do |instance_xml|
            instance = package.package_instances.find_by_name(instance_xml["name"])
            expect(instance).to_not be_nil
          end
        end
      end

      it "has package references that were not created" do
        imported_packages.each do |xml_package|
          package = Package.where(name: xml_package["name"]).first
          xml_package["references"].each do |reference_xml|
            reference = package.references.find_by_name(reference_xml["name"])
            expect(reference).to be_nil
          end
        end
      end
    end
  end


  describe 'import app_import xml with servers' do
    app_name = "import_app_with_packages"
    let(:url) { "#{base_url}/?token=#{@user.api_key}" }

    it_behaves_like 'successful request', type: :xml, method: :post, status: 201 do
      xml_content = File.open("spec/data/#{app_name}.xml", "r").read
      let(:added_app) { App.where(name: app_name).first }
      let(:imported_hash) { Hash.from_xml(xml_content) }
      let(:params) { xml_content }

      subject { response.body }

      it { should have_xpath("#{xml_root}/id").with_text(added_app.id) }
      it { should have_xpath("#{xml_root}/name").with_text(added_app.name) }

      it "has imported packages" do
        imported_packages.each do |xml_package|
          package = Package.where(name: xml_package["name"]).first
          expect(package).to_not be_nil
          expect(package.instance_name_format).to eq xml_package["instance_name_format"]
        end
      end

      it "has package instances" do
        imported_packages.each do |xml_package|
          package = Package.where(name: xml_package["name"]).first
          xml_package["package_instances"].each do |instance_xml|
            instance = package.package_instances.find_by_name(instance_xml["name"])
            expect(instance).to_not be_nil
          end
        end
      end

      it "has package references" do
        imported_packages.each do |xml_package|
          package = Package.where(name: xml_package["name"]).first
          xml_package["references"].each do |reference_xml|
            reference = package.references.find_by_name(reference_xml["name"])
            expect(reference).to_not be_nil
          end
        end
      end

      it "has package properties" do
        imported_packages.each do |xml_package|
          package = Package.where(name: xml_package["name"]).first
          xml_package["properties"].each do |properties_xml|
            property = package.properties.find_by_name(properties_xml["name"])
            expect(property).to_not be_nil
          end
        end
      end

      it "has reference override" do
        imported_packages.each do |xml_package|
          package = Package.where(name: xml_package["name"]).first
          xml_package["references"].each do |reference_xml|
            reference = package.references.find_by_name(reference_xml["name"])
            reference_xml["property_values"].each do |properties_xml|
              property_value = reference.property_values.joins(:property).where("properties.name = ?", properties_xml["name"]).first
              expect(property_value).to_not be_nil
              expect(property_value.value).to eq properties_xml["value"]
            end
          end
        end
      end

      it "has package instances property values" do
        imported_packages.each do |xml_package|
          package = Package.where(name: xml_package["name"]).first
          xml_package["package_instances"].each do |instance_xml|
            instance = package.package_instances.find_by_name(instance_xml["name"])
            expect(instance).to_not be_nil
            instance_xml["property_values"].each do |properties_xml|
              property_value = instance.property_values.joins(:property).where("properties.name = ?", properties_xml["name"]).first
              expect(property_value).to_not be_nil
              expect(property_value.value).to eq properties_xml["value"]
            end

          end
        end
      end


    end
  end

  def imported_packages
    imported_hash["app_import"]["app"]["active_packages"]
  end

end
