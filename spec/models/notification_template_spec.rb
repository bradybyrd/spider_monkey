################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################
require 'spec_helper'

describe NotificationTemplate do
  before(:each) do
    @notification_template = NotificationTemplate.new
    @sample_attributes = {
      :title => 'Sample template',
      :format => 'text/html',
      :active => true,
      :event => 'user_created',
      :subject => 'my subject',
      :body => 'This is my template, {{ user_name }}'
    }
  end

  it 'should be valid' do
    @notification_template.update_attributes(@sample_attributes)
    @notification_template.should be_valid
  end

  it 'should require an title' do
    @sample_attributes[:title] = nil
    @notification_template.update_attributes(@sample_attributes)
    @notification_template.should_not be_valid
  end

  it 'should require a format' do
    @sample_attributes[:format] = nil
    @notification_template.update_attributes(@sample_attributes)
    @notification_template.should_not be_valid
  end

  it 'should require a supported format' do
    @sample_attributes[:format] = 'custom_format'
    @notification_template.update_attributes(@sample_attributes)
    @notification_template.should_not be_valid
  end

  it 'should require an event' do
    @sample_attributes[:event] = nil
    @notification_template.update_attributes(@sample_attributes)
    @notification_template.should_not be_valid
  end

  it 'should require a supported event' do
    @sample_attributes[:event] = 'my custom event'
    @notification_template.update_attributes(@sample_attributes)
    @notification_template.should_not be_valid
  end

  it 'should require an active choice' do
    @sample_attributes[:active] = nil
    @notification_template.update_attributes(@sample_attributes)
    @notification_template.should_not be_valid
  end

  it 'should not allow two templates to be active for the same event' do
    @notification_template.update_attributes(@sample_attributes)
    @notification_template.active.should == true
    @sample_attributes[:title] = 'Duplicate template'
    @notification_template2 = NotificationTemplate.create(@sample_attributes)
    @notification_template2.should be_valid
    @notification_template2.active.should == true
    # need to avoid the cached object
    new_value = NotificationTemplate.inactive.first
    @notification_template.id.should == new_value.id
  end

  describe 'attribute normalizations' do
    it { should normalize_attribute(:title).from('  Hello  ').to('Hello') }
    it { should normalize_attribute(:description).from('  Hello  ').to('Hello') }
    it { should normalize_attribute(:subject).from('  Hello  ').to('Hello') }
    it { should normalize_attribute(:format).from('  Hello  ').to('Hello') }
    it { should normalize_attribute(:event).from('  Hello  ').to('Hello') }
  end

  describe '#filtered' do

    before(:all) do
      NotificationTemplate.delete_all
      @nt1 = create_notification_template
      @nt2 = create_notification_template(:title => 'Inactive Notification Template', :active => false)
      @nt3 = create_notification_template(:title => 'Some Notification Template')
      @active = [@nt1, @nt3]
      @inactive = [@nt2]
    end

    after(:all) do
      NotificationTemplate.delete_all
    end

    it_behaves_like 'active/inactive filter' do

      it 'cumulative filter active by default' do
        result = described_class.filtered(:title => 'Some Notification Template')
        result.should match_array([@nt3])
      end

      it 'empty cumulative filter active by default' do
        result = described_class.filtered(:title => 'Inactive Notification Template')
        result.should be_empty
      end

      it 'cumulative filter inactive' do
        result = described_class.filtered(:inactive => true, :title => 'Inactive Notification Template')
        result.should match_array([@nt2])
      end
    end

  end

  protected

  def create_notification_template(options = nil)
    create(:notification_template, options)
  end

end
