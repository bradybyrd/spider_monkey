RSpec::Matchers.define :be_ok do
  match do |actual|
    actual == 200
  end
end

RSpec::Matchers.define :part_of_groups do |groups|
  match do |user|
    actual_groups = user.groups.map(&:name)
    groups & actual_groups == groups
  end
end


# RSpec matcher to spec delegations.
#
# Usage:
#
#     describe Post do
#       it { should delegate(:name).to(:author).with_options(:prefix => true, :allow_nil => true} # post.author_name
#       it { should delegate(:month).to(:created_at) }
#       it { should delegate(:year).to(:created_at) }
#     end

RSpec::Matchers.define :delegate do |method|
  match do |delegator|
    @method = @prefix ? :"#{@to}_#{method}" : method
    @delegator = delegator
    begin
      @delegator.send(@to)
    rescue NoMethodError
      raise "#{@delegator} does not respond to #{@to}!"
    end
    @delegator.stub(@to).and_return double('receiver')
    @delegator.send(@to).stub(method).and_return :called
    @delegator.send(@method) == :called
  end

  description do
    "delegate :#{@method} to its #{@to}#{@prefix ? ' with prefix' : ''}"
  end

  failure_message_for_should do |text|
    "expected #{@delegator} to delegate :#{@method} to its #{@to}#{@prefix ? ' with prefix' : ''}"
  end

  failure_message_for_should_not do |text|
    "expected #{@delegator} not to delegate :#{@method} to its #{@to}#{@prefix ? ' with prefix' : ''}"
  end

  chain(:to) { |receiver| @to = receiver }
  chain(:with_options) { |options = {}| @prefix = options[:prefix] }
end

RSpec::Matchers.define :validate_permissions_per_environments do
  match do |subject|
    User.any_instance.stub(:cannot?).and_return(true)

    subject.check_permissions = true
    subject.valid?
    subject.errors[:base].join(' , ').should =~ /#{I18n.t('permissions.action_not_permitted', action: 'create', subject: subject.class.to_s)}/

    subject.check_permissions = false
    subject.valid?
    expect(subject.errors[:base]).to be_empty

    User.any_instance.stub(:cannot?).and_return(false)

    subject.save(validate: false)
    subject.check_permissions = true
    subject.valid?
    subject.errors[:base].join(' , ').should =~ /#{I18n.t('permissions.action_not_permitted', action: 'edit', subject: subject.class.to_s)}/

    subject.check_permissions = false
    subject.valid?
    expect(subject.errors[:base]).to be_empty
  end

  failure_message_for_should do
    "expected to validate permissions per application environments of #{subject.class.to_s}"
  end

  failure_message_for_should_not do
    "expected to validate permissions per application environments of #{subject.class.to_s}"
  end

  description do
    "validates permissions per application environments of #{subject.class.to_s}"
  end
end
