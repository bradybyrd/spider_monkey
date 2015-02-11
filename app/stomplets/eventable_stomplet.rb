if defined? TorqueBox
require 'torquebox-stomp'

#Example of usage at client: js
  # <%
  #   endpoint = TorqueBox.fetch('stomp-endpoint')
  # %>
  # <script src="http://<%= endpoint.host %>:<%= endpoint.port %>/stomp.js"></script>
  # <script type="text/javascript">
  # client = new Stomp.Client( "<%= endpoint.host %>", <%= endpoint.port %>, false );
  # client.connect( function(smth) {
  #   client.subscribe(
  #     "/stomplets/eventable/update/step/request_id=137&phase_id=1",
  #     function(message){
  #       //....do smthng here
  #     }
  #   );
  #   client.subscribe(
  #     "/stomplets/eventable/update/step/request_id=136&phase_id=1&phase_id=2",
  #     function(message){
  #       //....do smthng here
  #     }
  #   );
  # } );
  # client.connect( function(smth) {
  #   client.send( "/stomplets/eventable/update/step/", { event: 'update', id: 116, model: 'step', request_id: "135", phase_id: "1"}, "Some body here" );
  # } );
  # </script>

# use in models in Rails:
  # class ModelName < ActiveRecord::Base
  # ...
  #   acts_as_stomplet_eventable 'request_id'
  # ...
  # end # class


  class EventableStomplet < TorqueBox::Stomp::JmsStomplet

    include TorqueBox::Injectors

    def initialize
      super
    end

    def configure(stomplet_config)
      @destination = fetch(stomplet_config['destination'])
      super
    end

    def on_message(stomp_message, session)
      model_ = stomp_message.headers['model']
      id_ = stomp_message.headers['id']
      send_to( @destination, stomp_message, {id: "#{id_}", model: model_.downcase} )
    end

    def on_subscribe(subscriber)
      model = subscriber.get_parameter('model')
      event = subscriber.get_parameter('event')
      selector = prepare_selector(subscriber.get_parameter('selector'))
      selector = "model = '#{model}' and event = '#{event}' and #{selector}"
      subscribe_to( subscriber, @destination, selector )
      Rails.logger.info "Subscribed #{subscriber} with selector: #{selector.inspect}"
    end

    private

    def prepare_selector(url)
      CGI::parse(url).collect do |k,v|
        # parse operator in || =
        op = v.size > 1 ? 'in' : '='
        # prepare value '1' || ('1', 'yes')
        val = if v.size > 1 # ('1', 'yes')
         "(#{v.collect{|el| "'#{el}'"}.join(',')})"
        else # 'v'
          "'#{v.first}'"
        end
        # join result
        "#{k} #{op} #{val}"
      end.join(' and ')
    end
  end
end # if