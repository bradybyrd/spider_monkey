class RequestStepsEmailList
  def get(steps = [])
    @steps = steps

    step_owners_emails.compact
  end

  private

  def step_owners_emails
    user_owner_email | group_owner_email | user_through_group_owners_emails
  end

  def user_owner_email
    User.where(id: step_user_owner_ids).uniq.pluck('users.email')
  end

  def group_owner_email
    Group.where(id: step_group_owner_ids).uniq.pluck('groups.email')
  end

  def user_through_group_owners_emails
    User.joins(:groups).where(groups: {id: step_group_owner_ids}).uniq.pluck('users.email')
  end

  def step_user_owner_ids
    @steps.map{|step| step.owner_id if step.owner_type == 'User'}.compact.uniq
  end

  def step_group_owner_ids
    @steps.map{|step| step.owner_id if step.owner_type == 'Group'}.compact.uniq
  end
end