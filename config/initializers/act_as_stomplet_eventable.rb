require 'eventable_stomplet_binder'

class ActiveRecord::Base
  def self.acts_as_stomplet_eventable(*args)
    eventable = EventableStompletBinder.new(*args)
    after_create eventable
    after_update eventable
    after_destroy eventable
  end
end