class AccessibleBaseQuery
  attr_reader :user, :action, :subject

  def initialize(user, action = '', subject = '')
    @user = user
    @action = action
    @subject = subject
  end

  def add_permission_scope(relation)
    relation.where(permissions: {action: action, subject: subject}, users: {id: user.id})
  end

  def add_user_scope(relation)
    relation.where(users: {id: user.id})
  end
end