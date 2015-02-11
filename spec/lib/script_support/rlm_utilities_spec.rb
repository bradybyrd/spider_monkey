require 'spec_helper'
require File.expand_path(File.join('lib', 'script_support', 'rlm_utilities.rb'))

describe RlmUtilities do
  let(:rlm_base_url) { 'base_url' }
  let(:rlm_username) { 'username' }
  let(:rlm_password) { 'password' }
  let(:package) { double('package') }
  let(:instance) { double('instance') }
  let(:repo) { double('repo') }
  let(:package_instance) { double('package_instance') }
  let(:deploy_instance) { double('deploy_instance') }
  let(:route) { double('route') }
  let(:request_environment) { double('request_environment') }
  let(:command) { 'command' }
  let(:environment_id) { 1 }
  let(:argument) { 'argument' }
  let(:channels) { 'channel1,channel2' }

  #######Getter methods#####

  describe 'dynamic methods' do
    it '.get_all_packages' do
      RlmUtilities.stub(:get_all_items_list).with(rlm_base_url, rlm_username, rlm_password, 'package list')
      expect{ RlmUtilities.get_all_packages(rlm_base_url, rlm_username, rlm_password)
            }.not_to raise_error
    end

    it '.get_all_repos' do
      RlmUtilities.stub(:get_all_items_list).with(rlm_base_url, rlm_username, rlm_password, 'repo list', 'Ready')
      expect{ RlmUtilities.get_all_repos(rlm_base_url, rlm_username, rlm_password)
            }.not_to raise_error
    end

    it '.get_all_routes' do
      RlmUtilities.stub(:get_all_items_list).with(rlm_base_url, rlm_username, rlm_password, 'route list')
      expect{ RlmUtilities.get_all_routes(rlm_base_url, rlm_username, rlm_password)
            }.not_to raise_error
    end

    it '.get_all_environments' do
      RlmUtilities.stub(:get_all_items_list).with(rlm_base_url, rlm_username, rlm_password, 'environment list')
      expect{ RlmUtilities.get_all_environments(rlm_base_url, rlm_username, rlm_password)
            }.not_to raise_error
    end

    it '.get_package_instances' do
      RlmUtilities.stub(:get_all_package_items_list).with(rlm_base_url, rlm_username, rlm_password, package, 'instance package list', 'Ready')
      expect{ RlmUtilities.get_package_instances(rlm_base_url, rlm_username, rlm_password, package)
            }.not_to raise_error
    end

    it '.get_repo_instances' do
      RlmUtilities.stub(:get_all_package_items_list).with(rlm_base_url, rlm_username, rlm_password, package, 'instance repo list', 'Ready', nil, '0')
      expect{ RlmUtilities.get_repo_instances(rlm_base_url, rlm_username, rlm_password, package)
            }.not_to raise_error
    end

    it '.get_package_properties' do
      RlmUtilities.stub(:get_all_package_items_list).with(rlm_base_url, rlm_username, rlm_password, package, 'package property list')
      expect{ RlmUtilities.get_package_properties(rlm_base_url, rlm_username, rlm_password, package)
            }.not_to raise_error
    end

    it '.get_package_content_references' do
      RlmUtilities.stub(:get_all_package_items_list).with(rlm_base_url, rlm_username, rlm_password, package, 'package reference list')
      expect{ RlmUtilities.get_package_content_references(rlm_base_url, rlm_username, rlm_password, package)
            }.not_to raise_error
    end

    it '.get_package_instance_properties' do
      RlmUtilities.stub(:get_all_package_items_list).with(rlm_base_url, rlm_username, rlm_password, instance, 'instance property list')
      expect{ RlmUtilities.get_package_instance_properties(rlm_base_url, rlm_username, rlm_password, instance)
            }.not_to raise_error
    end

    it '.get_repo_instance_properties' do
      RlmUtilities.stub(:get_all_package_items_list).with(rlm_base_url, rlm_username, rlm_password, instance, 'instance property list')
      expect{ RlmUtilities.get_repo_instance_properties(rlm_base_url, rlm_username, rlm_password, instance)
            }.not_to raise_error
    end

    it '.get_repo_properties' do
      RlmUtilities.stub(:get_all_package_items_list).with(rlm_base_url, rlm_username, rlm_password, instance, 'repo property list')
      expect{ RlmUtilities.get_repo_properties(rlm_base_url, rlm_username, rlm_password, instance)
            }.not_to raise_error
    end

    it '.get_package_instance_content_references' do
      RlmUtilities.stub(:get_all_package_items_list).with(rlm_base_url, rlm_username, rlm_password, instance, 'instance artifact list')
      expect{ RlmUtilities.get_package_instance_content_references(rlm_base_url, rlm_username, rlm_password, instance)
            }.not_to raise_error
    end

    it '.get_repo_instance_content_references' do
      RlmUtilities.stub(:get_all_package_items_list).with(rlm_base_url, rlm_username, rlm_password, instance, 'instance artifact list')
      expect{ RlmUtilities.get_repo_instance_content_references(rlm_base_url, rlm_username, rlm_password, instance)
            }.not_to raise_error
    end
  end

  describe '.get_root_repo_instance_content_references' do
    context 'when references present' do
      it 'returns a hash with references' do
        RlmUtilities.stub(:get_all_package_items_list).with(rlm_base_url, rlm_username, rlm_password, instance, 'instance artifact list', nil, 'tree') do
          [ {key: 'value' }]
        end
        RlmUtilities.stub(:parse_repo_references).and_return({key: 'value'})
        result = RlmUtilities.get_root_repo_instance_content_references(rlm_base_url, rlm_username, rlm_password, instance)
        expect(result).to eq({ key: 'value' })
      end
    end

    context 'when references blank' do
      it 'returns blank hash' do
        RlmUtilities.stub(:get_all_package_items_list).with(rlm_base_url, rlm_username, rlm_password, instance, 'instance artifact list', nil, 'tree') do
          nil
        end
        result = RlmUtilities.get_root_repo_instance_content_references(rlm_base_url, rlm_username, rlm_password, instance)
        expect(result).to eq({})
      end
    end
  end

  describe '.get_root_repo_content_references' do
    context 'when references present' do
      it 'returns a hash with references' do
        RlmUtilities.stub(:get_all_package_items_list).with(rlm_base_url, rlm_username, rlm_password, instance, 'repo artifact list', nil, 'tree') do
          [{ key: 'value' }]
        end
        RlmUtilities.stub(:parse_repo_references).and_return({key: 'value'})
        result = RlmUtilities.get_root_repo_content_references(rlm_base_url, rlm_username, rlm_password, instance)
        expect(result).to eq({ key: 'value' })
      end
    end

    context 'when references blank' do
      it 'returns blank hash' do
        RlmUtilities.stub(:get_all_package_items_list).with(rlm_base_url, rlm_username, rlm_password, instance, 'repo artifact list', nil, 'tree') do
          nil
        end
        result = RlmUtilities.get_root_repo_content_references(rlm_base_url, rlm_username, rlm_password, instance)
        expect(result).to eq({})
      end
    end
  end

  it '.parse_repo_references' do
    expect(RlmUtilities.parse_repo_references([{'key=1' => 'value'}])).to eq({'key' => 'value=1'})
  end

  it '.get_package_instance_status' do
    RlmUtilities.stub(:get_status).with(rlm_base_url, rlm_username, rlm_password, 'instance status', package_instance)
    expect{ RlmUtilities.get_package_instance_status(rlm_base_url, rlm_username, rlm_password, package_instance)
          }.not_to raise_error
  end

  it '.get_repo_instance_status' do
    RlmUtilities.stub(:get_status).with(rlm_base_url, rlm_username, rlm_password, 'instance status', package_instance)
    expect{ RlmUtilities.get_repo_instance_status(rlm_base_url, rlm_username, rlm_password, package_instance)
          }.not_to raise_error
  end

  it '.get_deploy_status' do
    RlmUtilities.stub(:get_status).with(rlm_base_url, rlm_username, rlm_password, 'deploy status', package_instance)
    expect{ RlmUtilities.get_deploy_status(rlm_base_url, rlm_username, rlm_password, package_instance)
          }.not_to raise_error
  end

  it '.get_route_environments' do
    RlmUtilities.stub(:get_environments_by).with(route, rlm_base_url, rlm_username, rlm_password, 'route environment list', request_environment)
    expect{ RlmUtilities.get_route_environments(rlm_base_url, rlm_username, rlm_password, route, request_environment)
          }.not_to raise_error
  end

  describe '.get_environment_channels' do
    context 'with blank environment_id' do
      it 'returns blank array' do
        expect(RlmUtilities.get_environment_channels(rlm_base_url, rlm_username, rlm_password, nil)).to eq([])
      end
    end

    context 'with blank response' do
      it 'returns blank array' do
        RlmUtilities.stub(:send_xml_request).with(rlm_base_url, rlm_username, rlm_password,
                                                  'environment channel list', [environment_id]) do
          {'result' => [{ 'response' => '' }]}
        end
        expect(RlmUtilities.get_environment_channels(rlm_base_url, rlm_username, rlm_password, environment_id)).to eq([])
      end
    end

    context 'with valid data' do
      it 'returns hash with totalItems, perPage and data keys' do
        RlmUtilities.stub(:send_xml_request).with(rlm_base_url, rlm_username, rlm_password,
                                                  'environment channel list', [environment_id]) do
          {'result' => [{ 'response' => [{'id' => 1, 'value' => 'val1' }] }]}
        end
        result = RlmUtilities.get_environment_channels(rlm_base_url, rlm_username, rlm_password, environment_id)
        expect(result).to eq({ totalItems: 1, perPage: 10, data: [['', 'Channel Name'], [1, 'val1']] })
      end
    end
  end

  it '.get_route_type' do
    RlmUtilities.stub(:get_status).with(rlm_base_url, rlm_username, rlm_password, command, route)
    expect{ RlmUtilities.get_route_type(rlm_base_url, rlm_username, rlm_password, command, route)
          }.not_to raise_error
  end

  describe '.get_all_instance_routes' do
    context 'with valid data' do
      it 'returns routes' do
        RlmUtilities.stub(:send_xml_request).with(rlm_base_url, rlm_username, rlm_password, 'instance route get', [instance]) do
          {'result' => [{'response' => [{ 'id' => 1, 'value' => 'val1' }] }]}
        end
        result = RlmUtilities.get_all_instance_routes(rlm_base_url, rlm_username, rlm_password, instance)
        expect(result).to eq([{ 'val1' => 1}])
      end

      it 'returns blank hash' do
        RlmUtilities.stub(:send_xml_request).with(rlm_base_url, rlm_username, rlm_password, 'instance route get', [instance]) do
          {'result' => [{'response' => ['No route assigned to that instance']}]}
        end
        result = RlmUtilities.get_all_instance_routes(rlm_base_url, rlm_username, rlm_password, instance)
        expect(result).to eq([])
      end
    end
  end

  describe '.get_all_items_list' do
    context 'command eql package_list' do
      it 'returns item list' do
        RlmUtilities.stub(:send_xml_request).with(rlm_base_url, rlm_username, rlm_password, 'package list', [argument]) do
          {'result' => [{ 'response' => [{ 'id' => 1, 'value' => 'val1' }] }]}
        end
        result = RlmUtilities.get_all_items_list(rlm_base_url, rlm_username, rlm_password, 'package list', argument)
        expect(result).to eq([{ 'val1' => '1*val1' }])
      end
    end

    context 'command not eql package_list' do
      it 'returns item list' do
        RlmUtilities.stub(:send_xml_request).with(rlm_base_url, rlm_username, rlm_password, command, [argument]) do
          {'result' => [{'response' => [{ 'id' => 1, 'value' => 'val1' }]}]}
        end
        result = RlmUtilities.get_all_items_list(rlm_base_url, rlm_username, rlm_password, command, argument)
        expect(result).to eq([{ 'val1' => 1 }])
      end
    end
  end

  describe '.get_all_package_items_list' do
    context 'package not present' do
      it 'raise error' do
        expect{ RlmUtilities.get_all_package_items_list(rlm_base_url, rlm_username, rlm_password, nil, command)
              }.to raise_error('No valid package name/ID provided.')
      end
    end

    context 'when type nil' do
      it 'returns data like table' do
        xml_to_hash_respponse = {'result' => [{'response' => [{ 'id' => 1, 'value' => 'val1' }]}]}
        RlmUtilities.stub(:send_xml_request).with(rlm_base_url, rlm_username, rlm_password, 'package reference list', [package, nil, nil]) do
          xml_to_hash_respponse
        end
        result = RlmUtilities.get_all_package_items_list(rlm_base_url, rlm_username, rlm_password, package, 'package reference list')
        expect(result).to eq({ totalItems: 1, perPage: 10, data: [['', 'Reference Name', 'Reference URL'], %w(val1 val1 val1)]})
      end
    end

    context 'when type tree' do
      it 'returns data like tree' do
        xml_to_hash_respponse = {'result' => [{'response' => [{ 'id' => 1, 'value' => 'val1' }]}]}
        RlmUtilities.stub(:send_xml_request).with(rlm_base_url, rlm_username, rlm_password, command, [package, nil, nil]) do
          xml_to_hash_respponse
        end
        result = RlmUtilities.get_all_package_items_list(rlm_base_url, rlm_username, rlm_password, package, command, nil, 'tree')
        expect(result).to eq([{ 'val1' => 1}])
      end
    end
  end

  describe '.get_status' do
    it 'returns instance status' do
      RlmUtilities.stub(:send_xml_request).with(rlm_base_url, rlm_username, rlm_password, command, [1]) do
        {'result' => [{'response' => [{ 'value' => 'ready:1' }]}]}
      end
      result = RlmUtilities.get_status(rlm_base_url, rlm_username, rlm_password, command, 1)
      expect(result).to eq('ready')
    end
  end

  describe '.get_environments_by' do
    context 'when value is inherited from request' do
      it 'returns environments' do
        RlmUtilities.stub(:send_xml_request).with(rlm_base_url, rlm_username, rlm_password, command, [argument]) do
          {'result' => [{'response' => [{ 'value' => 'val1', 'id' => 1 }]}]}
        end
        result = RlmUtilities.get_environments_by(argument, rlm_base_url, rlm_username, rlm_password, command, request_environment)
        expect(result).to eq([{ 'val1' => 1 }])
      end
    end

    context 'when value is not inherited from request' do
      it 'returns environments' do
        RlmUtilities.stub(:send_xml_request).with(rlm_base_url, rlm_username, rlm_password, command, [argument]) do
          {'result' => [{'response' => [{ 'value' => request_environment, 'id' => 1 }]}]}
        end
        result = RlmUtilities.get_environments_by(argument, rlm_base_url, rlm_username, rlm_password, command, request_environment)
        expect(result).to eq([{ "#{request_environment}(inherited from request)" => "1-inherited" }])
      end
    end
  end

  describe '.get_logs' do
    context 'when data valid' do
      it 'returns response' do
        RlmUtilities.stub(:send_xml_request).with(rlm_base_url, rlm_username, rlm_password, command, [1, 0]) do
          {'result' => [{'response' => [{ 'value' => 'val1', 'id' => 1 }]}]}
        end
        result = RlmUtilities.get_logs(rlm_base_url, rlm_username, rlm_password, 1, command)
        expect(result).to eq("---\n- value: val1\n  id: 1\n")
      end

      it 'returns nil' do
        RlmUtilities.stub(:send_xml_request).with(rlm_base_url, rlm_username, rlm_password, command, [1, 0]) do
          {'result' => [{'response' => [{}]}]}
        end
        result = RlmUtilities.get_logs(rlm_base_url, rlm_username, rlm_password, 1, command)
        expect(result).to be_nil
      end
    end
  end

  describe '.get_instance_logs' do
    context 'when response empty' do
      it 'returns nil' do
        RlmUtilities.stub(:send_xml_request).with(rlm_base_url, rlm_username, rlm_password, command, [1]) do
          {'result' => [{'response' => [{}]}]}
        end
        result = RlmUtilities.get_instance_logs(rlm_base_url, rlm_username, rlm_password, 1, command)
        expect(result).to be_nil
      end
    end

    context 'when response present' do
      it 'returns response like yaml' do
        RlmUtilities.stub(:send_xml_request).with(rlm_base_url, rlm_username, rlm_password, command, [1]) do
          {'result' => [{'response' => [{ 'value' => 'val1', 'id' => 1 }]}]}
        end
        result = RlmUtilities.get_instance_logs(rlm_base_url, rlm_username, rlm_password, 1, command)
        expect(result).to eql("---\n- value: val1\n  id: 1\n")
      end
    end
  end

  describe '.get_deployment_logs' do
    context 'when data valid' do
      it 'returns response' do
        RlmUtilities.stub(:get_hash_response) { [{ id: 1, logs: 'logs' }] }
        result = RlmUtilities.get_deployment_logs(rlm_base_url, rlm_username, rlm_password, 1)
        expect(result).to eq("---\n- :id: 1\n  :logs: logs\n\n\n")
      end

      it 'returns nil' do
        RlmUtilities.stub(:get_hash_response) { nil }
        result = RlmUtilities.get_deployment_logs(rlm_base_url, rlm_username, rlm_password, 1)
        expect(result).to be_nil
      end
    end
  end

  describe '.get_hash_response' do
    context 'when response present' do
      it 'returns response' do
        RlmUtilities.stub(:send_xml_request).with(rlm_base_url, rlm_username, rlm_password, command, [1, 0]) do
          {'result' => [{'response' => [{ :data => 'data' }]}]}
        end
        result = RlmUtilities.get_hash_response(rlm_base_url, rlm_username, rlm_password, 1, command, 0)
        expect(result).to eql([{ data: 'data' }])
      end
    end

    context 'when response empty' do
      it 'returns nil' do
        RlmUtilities.stub(:send_xml_request).with(rlm_base_url, rlm_username, rlm_password, command, [1, 1]) do
          {'result' => [{'response' => [{}]}]}
        end
        result = RlmUtilities.get_hash_response(rlm_base_url, rlm_username, rlm_password, 1, command, 1)
        expect(result).to be_nil
      end
    end
  end

  ###########Setter methods#########

  describe '.create_package_instance' do
    context 'package not present' do
      it 'raise error' do
        expect{ RlmUtilities.create_package_instance(rlm_base_url, rlm_username, rlm_password, nil)
              }.to raise_error('No valid package name/ID provided.')
      end
    end

    context 'when data valid' do
      it 'returns data like table' do
        RlmUtilities.stub(:send_xml_request).with(rlm_base_url, rlm_username, rlm_password, 'instance create package', [package, nil]) do
          {'result' => [{'response' => [{ 'value' => 'val1' }]}]}
        end
        result = RlmUtilities.create_package_instance(rlm_base_url, rlm_username, rlm_password, package)
        expect(result).to eq([{ 'value' => 'val1' }])
      end
    end
  end

  describe '.create_repo_instance' do
    context 'package not present' do
      it 'raise error' do
        expect{ RlmUtilities.create_repo_instance(rlm_base_url, rlm_username, rlm_password, nil)
              }.to raise_error('No valid Repo name/ID provided.')
      end
    end

    context 'when data valid' do
      it 'returns data like table' do
        RlmUtilities.stub(:send_xml_request).with(rlm_base_url, rlm_username, rlm_password, 'instance create repo', [repo, nil]) do
          {'result' => [{'response' => [{ 'value' => 'val1' }]}]}
        end
        result = RlmUtilities.create_repo_instance(rlm_base_url, rlm_username, rlm_password, repo)
        expect(result).to eq([{ 'value' => 'val1' }])
      end
    end
  end

  describe '.deploy_package_instance' do
    let(:command) { "instance deploy #{instance} #{route} #{request_environment} -c #{channels.gsub(/,/, ' ')}" }

    context 'when response present' do
      it 'returns response' do
        RlmUtilities.stub(:send_xml_request).with(rlm_base_url, rlm_username, rlm_password, command, nil) do
          {'result' => [{'response' => [{ 'id' => 1 }]}]}
        end
        result = RlmUtilities.deploy_package_instance(rlm_base_url, rlm_username, rlm_password, instance, route, request_environment, channels)
        expect(result).to eql(1)
      end
    end

    context 'when response empty' do
      it 'returns nil' do
        RlmUtilities.stub(:send_xml_request).with(rlm_base_url, rlm_username, rlm_password, command, nil) do
          {'result' => [{'response' => [{}]}]}
        end
        result = RlmUtilities.deploy_package_instance(rlm_base_url, rlm_username, rlm_password, instance, route, request_environment, channels)
        expect(result).to be_nil
      end
    end
  end

  ########Convertors##########

  describe '.display_output_as_table_format' do
    let(:table_header_1) { 'table_header_1' }
    let(:table_header_2) { 'table_header_2' }

    context 'when response present' do
      it 'returns response like table' do
        hash_response = {'result' => [{'response' => [{ 'value' => 'name=url' }]}]}
        result = RlmUtilities.display_output_as_table_format(hash_response, table_header_1, table_header_2)
        expect(result).to eq({ totalItems: 1, perPage: 10, data: [['', 'table_header_1', 'table_header_2'], %w(name name url)] })
      end
    end

    context 'when response blank' do
      it 'return blank array' do
        hash_response = {'result' => [{'response' => [{  }]}]}
        result = RlmUtilities.display_output_as_table_format(hash_response, table_header_1, table_header_2)
        expect(result).to eq([])
      end
    end
  end

  it '.rlm_set_q_property_value' do
    entity = 'entity'
    property_name = 'DE_name'
    property_value = 'val1'
    RlmUtilities.stub(:send_xml_request).with(rlm_base_url, rlm_username, rlm_password, command, [entity, property_name, "\"#{property_value.gsub("\"", "\"\"")}\"", nil])
    result = RlmUtilities.rlm_set_q_property_value(rlm_base_url, rlm_username, rlm_password, entity, command, property_name, property_value, nil)
    expect(result).to be_truthy
  end

  describe '.send_xml_request' do
    let!(:request) { RestClient.stub(:post) { 'success' } }

    context 'when response status Ok' do
      it 'returns response' do
        xml_to_hash_response = {'result' => [{ 'rc' => '0', 'message' => 'Ok' }]}
        XmlSimple.stub(:xml_in) { xml_to_hash_response }
        result = RlmUtilities.send_xml_request(rlm_base_url, rlm_username, rlm_password, command)
        expect(result).to eq(xml_to_hash_response)
      end
    end

    context 'when response status error' do
      it 'raise error' do
        url = "#{rlm_base_url}/index.php/api/processRequest.xml"
        XmlSimple.stub(:xml_in) { { 'result' => [ {'rc' => '1', 'message' => 'Error'}] }}
        expect{ RlmUtilities.send_xml_request(rlm_base_url, rlm_username, rlm_password, command)
              }.to raise_error("Error while posting to URL #{url}: Error")
      end
    end
  end

  describe '.write_logs_to_file' do
    context 'when success' do
      it 'returns log file path' do
        instance_id = 1
        result_dir = '/opt'
        instance_logs = 'Some_logs'
        File.stub(:directory?) { true }
        file = double('file')
        File.stub(:new) { file }
        file.should_receive(:write).with(instance_logs)
        file.should_receive(:close).once
        result = RlmUtilities.write_logs_to_file(instance_id, result_dir, instance_logs)
        expect(result).to eq("#{result_dir}/rlm_instance_logs/#{instance_id}.txt")
      end
    end
  end
end