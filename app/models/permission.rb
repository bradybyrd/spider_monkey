class Permission < ActiveRecord::Base
  attr_accessible :id, :name, :action, :subject, :is_instance

  has_many :role_permissions
  has_many :roles, through: :role_permissions
  has_many :permissions, :foreign_key => :parent_id, :order => 'position'

  def init_method_name
    self.subject.downcase + '_' + self.action
  end

  def to_simple_hash
    {id: self.id, subject: self.subject, action: self.action}
  end
end
