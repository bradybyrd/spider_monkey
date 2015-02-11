module Messaging

  include TorqueBox::Injectors if defined? TorqueBox::Injectors
  mattr_accessor :old_object

  def self.included(base)
    base.extend ClassMethods
  end

  def push_msg
    if GlobalSettings.messaging_enabled?
      begin
        @messaging_destionation_path = '/topics/messaging/brpm_event_queue'
        @messaging_destination ||= fetch(@messaging_destionation_path) if defined? TorqueBox::Injectors
        if @messaging_destination
          msg = construct_msg
          @messaging_destination.publish(msg)
        elsif !Rails.env.test?
          logger.error "Couldn't resolve destination by path: #{@messaging_destionation_path}"
        end
      rescue => err
        logger.error "Messaging System Error: #{err.message};\n #{err.backtrace}"
      end
    end
  end

  def construct_msg
    presenter = "V1::#{self.class}Presenter".constantize
    old_obj = retrieve_old_object
    msg = (created_at == updated_at ?
      presenter.new(self, nil, alone: true).to_xml :
      presenter.new(old_obj, nil, alone: true).to_xml + presenter.new(self, nil, alone: true).to_xml)
    doc = Nokogiri::HTML::DocumentFragment.parse msg
    new_node = Nokogiri::XML::Node.new('event', doc)
    new_node.content = (created_at == updated_at ? 'create' : 'update')
    class_name = self.class.name.downcase
    doc.search(class_name).first.before(new_node)
    obj_nodes = doc.search(class_name)
    obj_nodes.first['type'] = 'old'
    obj_nodes.last['type'] = 'new'
    doc.to_xml
  end

  def save_old_object
    if GlobalSettings.messaging_enabled?
      Messaging.old_object ||= {}
      Messaging.old_object[self.class.to_s.to_sym] ||= {}
      Messaging.old_object[self.class.to_s.to_sym][self.id] = self.class.find(self)
    end
  end

  module ClassMethods
    def acts_as_messagable
      before_update :save_old_object
    end
  end

  private

  def retrieve_old_object
    Messaging.old_object[self.class.to_s.to_sym].delete(self.id) if Messaging.old_object && Messaging.old_object[self.class.to_s.to_sym] && Messaging.old_object[self.class.to_s.to_sym][self.id]
  end
end
