shared_examples 'successful request' do |options = {}|
  let(:headers) { send "#{options[:type]}_headers".to_sym } if options[:type]
  let(:params) { options[:params] } if options[:params]
  before(:each) { perform_request(options) }
  if options[:status]
    specify { expect(response.status).to eq options[:status] }
  else
    specify { expect(response.status).to be_ok }
  end
  if options[:type]
    it "should have content type #{options[:type]}" do
      expect(response.content_type).to(send "be_#{options[:type]}".to_sym)
    end
  end
end

shared_examples 'has valid resource data' do |options = {}|
  let(:result) do
    if options[:type] == :json
      JSON.parse(response.body)[options[:resource].to_s].first
    else
      Hash.from_xml(response.body)['request'][options[:resource].to_s].first
    end
  end

  it "should return proper #{options[:resource].to_s} data" do
    resource_attributes.each do |attribute|
      expect(result[attribute.to_s]).to eq real_resource.send(attribute)
    end
  end
end

shared_examples 'creating request with params that fails validation' do
  it 'response status should be 422 using mimetype JSON' do
    params = { json_root => param }.to_json

    jpost params

    expect(response.status).to eq 422
  end

  it 'response status should be 422 using mimetype XML' do
    params = param.to_xml(root: xml_root)

    xpost params

    expect(response.status).to eq 422
  end
end

shared_examples 'editing request with params that fails validation' do
  it 'response status should be 422 using mimetype JSON' do
    params = { json_root => param }.to_json

    jput params

    expect(response.status).to eq 422
  end

  it 'response status should be 422 using mimetype XML' do
    params = param.to_xml(root: xml_root)

    xput params

    expect(response.status).to eq 422
  end
end

shared_examples 'creating request with invalid params' do
  let(:param) { {invalid: 'param'} }

  it 'response status should be 500 using mimetype JSON' do
    params = { json_root => param }.to_json

    jpost params

    expect(response.status).to eq 500
  end


  it 'response status should be 500 using mimetype XML' do
    params = param.to_xml(root: xml_root)

    xpost params

    expect(response.status).to eq 500
  end
end

shared_examples 'editing request with invalid params' do
  let(:url) { "#{base_url}/#{@entity.id}?token=#{@user.api_key}" }

  before(:each) do
    @entity = create(json_root)
  end

  let(:param) { {invalid: 'param'} }

  it 'response status should be 500 using mimetype JSON' do
    params = { json_root => param }.to_json

    jput params

    expect(response.status).to eq 500
  end

  it 'response status should be 500 using mimetype XML' do
    params = param.to_xml(root: xml_root)

    xput params

    expect(response.status).to eq 500
  end
end

shared_examples 'with `toggle_archive` param' do |options = {}|
  let(:entity)         { create(json_root) }
  let(:url)            { "#{base_url}/#{entity.id}?token=#{@user.api_key}" }
  let(:json_params)    { {toggle_archive: true}.to_json }
  let(:xml_params)     { create_xml {|xml| xml.toggle_archive true} }
  let(:updated_entity) { (options[:custom_entity] || json_root.to_s.camelize.constantize).find(entity.id) }

  context 'set from archived to unarchived' do

    before(:each) { entity.archive }

    context 'JSON' do

      before(:each) { jput json_params }

      subject { response.body }

      specify { expect(response.code).to eq '202' }

      it 'should update entity with `archive_number` to nil' do
        expect(subject).to have_json('*.archive_number').with_value(nil)
      end

      it 'should update entity with `archived_at` to nil' do
        expect(subject).to have_json('*.archived_at').with_value(nil)
      end

      it 'should update entity archived value to false' do
        expect(updated_entity.archived?).to be_falsey
      end
    end

    context 'XML' do

      before(:each) { xput xml_params }

      subject { response.body }

      specify { expect(response.code).to eq '202' }

      it 'should update entity with `archive-number` to nil' do
        expect(subject).to have_xpath("#{xml_root}/archive-number").with_text(nil)
      end

      it 'should update entity with `archived-at` to nil' do
        expect(subject).to have_xpath("#{xml_root}/archived-at").with_text(nil)
      end

      it 'should update entity archived value to false' do
        expect(updated_entity.archived?).to be_false
      end
    end
  end

  context 'set from unarchived to archived' do

    context 'JSON' do

      before(:each) {
        if entity.respond_to?('aasm_state')
          entity.aasm_state = 'retired'
          entity.save
        end
        jput json_params
      }

      subject { response.body }

      specify { expect(response.code).to eq '202' }

      it 'should update entity with `archive_number`' do
        expect(subject).to have_json('string.archive_number')
      end

      it 'should update entity with `archived_at`' do
        expect(subject).to have_json('string.archived_at')
      end

      it 'should update entity archived value' do
        expect(updated_entity.archived?).to be_truthy
      end
    end

    context 'XML' do

      before(:each) {
        if entity.respond_to?('aasm_state')
          entity.aasm_state = 'retired'
          entity.save
        end
        xput xml_params
      }

      subject { response.body }

      specify { expect(response.code).to eq '202' }

      it 'should update entity with `archive-number`' do
        expect(subject).to have_xpath("#{xml_root}/archive-number")
      end

      it 'should update entity with `archived-at`' do
        expect(subject).to have_xpath("#{xml_root}/archived-at")
      end

      it 'should update entity archived value' do
        expect(updated_entity.archived?).to be_truthy
      end
    end
  end
end

shared_examples 'change `active` param' do
  let(:entity)         { create(json_root) }
  let(:url)            { "#{base_url}/#{entity.id}?token=#{@user.api_key}" }
  let(:updated_entity) { json_root.to_s.camelize.constantize.find(entity.id) }
  let(:params)         { {active: active_value} }
  let(:json_params)    { {json_root => params}.to_json }
  let(:xml_params)     { params.to_xml(root: xml_root) }

  context 'set from inactive to active' do

    before(:each) { entity.deactivate! }

    let(:active_value) { true }

    context 'JSON' do

      before(:each) { jput json_params }

      subject { response.body }

      specify { expect(response.code).to eq '202' }

      it 'should update entity with `active` to true' do
        expect(subject).to have_json('boolean.active').with_value(true)
      end

      it 'should update entity active value to true' do
        expect(updated_entity.active).to be_truthy
      end
    end

    context 'XML' do

      before(:each) { xput xml_params }

      subject { response.body }

      specify { expect(response.code).to eq '202' }

      it 'should update entity with `active` to true' do
        expect(subject).to have_xpath("#{xml_root}/active").with_text('true')
      end

      it 'should update entity active value to true' do
        expect(updated_entity.active).to be_truthy
      end
    end
  end

  context 'set from active to inactive' do

    let(:active_value) { false }

    context 'JSON' do

      before(:each) { jput json_params }

      subject { response.body }

      specify { expect(response.code).to eq '202' }

      it 'should update entity with `active` to false' do
        expect(subject).to have_json('boolean.active').with_value(false)
      end

      it 'should update entity active value to false' do
        expect(updated_entity.active).to be_falsey
      end
    end

    context 'XML' do

      before(:each) { xput xml_params }

      subject { response.body }

      specify { expect(response.code).to eq '202' }

      it 'should update entity with `active` to false' do
        expect(subject).to have_xpath("#{xml_root}/active").with_text('false')
      end

      it 'should update entity active value to false' do
        expect(updated_entity.active).to be_falsey
      end
    end
  end
end

shared_examples 'entity with include_exclude support' do

  context 'with-out include_exclude filter return all' do
    subject { response.body }

    it 'using mimetype JSON' do
      jget
      expect(response.status).to eq 200

      excludes.each do |elem|
        expect(subject).to have_json("object > *.#{elem}")
      end
    end

    it 'using mimetype XML' do
      xget
      expect(response.status).to eq 200

      excludes.each do |elem|
        expect(subject).to have_xpath("#{xml_root}/#{elem.dasherize}")
      end
    end
  end

  context 'with include_exclude filter return filtered' do
    let(:param) { { filters: { include_except: excludes.join(', ') } } }
    subject { response.body }

    it 'using mimetype JSON' do
      jget param
      expect(response.status).to eq 200

      excludes.each do |elem|
        expect(subject).to_not have_json("object > *.#{elem}")
      end
    end

    it 'using mimetype XML' do
      xget param
      expect(response.status).to eq 200

      excludes.each do |elem|
        expect(subject).to_not have_xpath("#{xml_root}/#{elem.dasherize}")
      end
    end
  end
end

def tested_formats
  %w(json xml)
end

def test_batch_of_requests(methods_urls, options={})
  options[:mimetypes]     = options[:mimetypes].to_a unless options[:mimetypes].is_a? Array
  options[:mimetypes].delete_if { |mimetype| !defined?(eval "#{mimetype}_headers") }

  # should include 1 `nil` to be iterated if mimetype was not specified
  options[:mimetypes]     << nil                     if options[:mimetypes].empty?
  mimetypes               = options[:mimetypes]

  options[:response_code] = options[:response_code].to_i

  methods_urls.each do |method, urls|
    urls.each do |url|
      mimetypes.each do |mimetype|

        it "should return response code #{options[:response_code]} for #{method.upcase} #{url} #{mimetype.upcase if mimetype}" do
          # token is supposed to be always as GET param
          url_with_token = "#{url}?token=#{token}"
          params  ||= {}

          request = []
          request << "#{method.to_s} url_with_token"
          request << 'params'
          request << "#{mimetype}_headers"  if mimetype

          eval request.join(', ')

          expect(response.status).to eq options[:response_code]

          yield response, options if block_given?
        end

      end
    end
  end
end

%w-get post put delete-.each do |method|
  tested_formats.each do |mimetype|
    str         = []
    method_name = "#{mimetype}_#{method}"
    prefix      =  mimetype[0] # first letter of mimetype
    args        = 'params = {}'

    str << "def #{method_name}(#{args})"
    str <<  "#{method} url, params, #{mimetype}_headers"
    str << 'end'
    str << "alias :#{prefix}#{method} :#{method_name}"

    eval str.join("\n")
  end
end

module APISpecHelper

  def json_headers
    {
        'HTTP_ACCEPT' => 'application/json',
        'CONTENT_TYPE' => 'application/json'
    }
  end

  def xml_headers
    {
        'HTTP_ACCEPT' => 'text/xml',
        'CONTENT_TYPE' => 'text/xml'
    }
  end

  def create_xml(&block)
    ::Nokogiri::XML::Builder.new(&block).to_xml
  end

  def perform_request(options)
    method = options[:method] || :get
    send method, url, params, headers
  end

  def have_json(query)
    JSONMatcher.new(query)
  end

  def have_xpath(xpath)
    XPathMatcher.new(xpath)
  end

  class JSONMatcher
    attr_reader :query, :value, :target, :real_value, :multivalues
    def initialize(query)
      @query = query
    end

    def with_value(value)
      @value = value
      self
    end

    def with_values(values)
      @multivalues = true
      @value = values
      self
    end

    def matches?(target)
      @target     = ActiveSupport::JSON.decode(target)
      @real_value = JSONSelect(query).matches(self.target)

      if real_value.empty?
        false
      elsif !value
        return true
      else
        if @multivalues
          return real_value.sort == value.sort
        else
          @real_value = @real_value.first #JSONSelect(query).match(self.target)
          return real_value == value
        end
      end
    end

    def failure_message
      if value
        "expected `#{@target}` to have `#{value}` at `#{query}`, but it has `#{real_value}`"
      else
        "expected `#{@target}` to match `#{query}`"
      end
    end

    def negative_failure_message
      if value
        "expected `#{@target}` to dont have `#{value}` at `#{query}`, but it has `#{real_value}`"
      else
        "expected `#{@target}` to match `#{query}`"
      end
    end

    def description
      return "match #{query}" unless value
      "have #{value} at #{query}"
    end

  end

  class XPathMatcher
    attr_reader :query, :value, :target, :real_value, :multivalues
    def initialize(query)
      @query = query
    end

    def with_text(value)
      @value = value.to_s
      self
    end

    def with_texts(values)
      @multivalues = true
      @value = values.map{|v| v.to_s}
      self
    end

    def matches?(xml)
      # certain fields may be serialized with invalid xml
      # symbols: `?`, `!`, etc.. Remove them before creating
      # xml from string
      xml = xml.gsub(/\b+\?|!/, '')
      @target     = ::Nokogiri.XML(xml)
      @real_value = @target.xpath(query)

      if real_value.empty?
        false
      elsif !value
        return true
      else
        if multivalues
          real_values = real_value.collect{|node| node.text}

          return real_values.sort == @value.sort
        else
          @real_value = real_value.first
          return real_value.text == value
        end
      end
    end

    def failure_message
      "expected `#{@target}` to match `#{query}`" unless value
      "expected `#{@target}` to have `#{value}` at `#{query}`, but it has `#{real_value}`"
    end

    def description
      return "match #{query}" unless value
      "have #{value} at #{query}"
    end
  end
end
