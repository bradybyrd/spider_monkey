################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2014
# All Rights Reserved.
################################################################################

require 'spec_helper'

describe GlobalSettings do
  before(:each) do
    GlobalSettings.instance.destroy
    GlobalSettings.clear_local_instance
  end

  it 'should be valid by default' do
    expect(GlobalSettings.instance).to be_valid
  end

  it 'should return 1000 as the default base_request_number' do
    GlobalSettings[:base_request_number].should eql(1000)
  end

  it 'should have default authentication enabled by default' do
    expect(GlobalSettings.default_authentication_enabled?).to be_truthy
    expect(GlobalSettings.ldap_enabled?).to be_falsey
    expect(GlobalSettings.cas_enabled?).to be_falsey
  end

  it 'should have limit_versions disabled by default' do
    expect(GlobalSettings.limit_versions?).to be_falsey
  end

  it 'should have messaging_enabled disabled by default' do
    expect(GlobalSettings.messaging_enabled?).to be_falsey
  end

  it 'should have one click step completion disabled by default' do
    expect(GlobalSettings.one_click_completion?).to be_falsey
  end

  it 'should have default date format and timezone' do
    GlobalSettings[:default_date_format].should_not be_nil
    GlobalSettings[:timezone].should_not be_nil
  end

  it 'should have forgot password enabled by default' do
    expect(GlobalSettings.forgot_password?).to be_truthy
  end

  it 'should not have company name or logo information by default' do
    GlobalSettings[:default_logo].should be_nil
    #GlobalSettings[:company_name].should be_nil
    #GlobalSettings[:calendar_preferences.should_not be_nil
  end

  it 'should have automation disabled by default' do
    expect(GlobalSettings.bladelogic_enabled?).to be_falsey
    expect(GlobalSettings.capistrano_enabled?).to be_falsey
    expect(GlobalSettings.hudson_enabled?).to be_falsey
  end

  it 'should have bladelogic settings nil by default' do
    GlobalSettings[:bladelogic_ip_address].should be_nil
    GlobalSettings[:bladelogic_username].should be_nil
    GlobalSettings[:bladelogic_rolename].should be_nil
    GlobalSettings[:bladelogic_password].should be_nil
    GlobalSettings[:bladelogic_profile].should be_nil
  end

  it 'should have ldap settings nil by default' do
    GlobalSettings[:ldap_host].should satisfy{|s| [nil, ''].include?(s)}
    GlobalSettings[:ldap_port].should satisfy{|s| [nil, ''].include?(s)}
    GlobalSettings[:ldap_component].should satisfy{|s| [nil, ''].include?(s)}
  end

  it 'should have cas settings nil by default' do
    GlobalSettings[:cas_server].should satisfy{|s| [nil, ''].include?(s)}
  end

  it 'should be able to return set values' do
    GlobalSettings[:session_key] = 'A sample session key'
    GlobalSettings[:base_url] = 'http://localhost:3000/'

    GlobalSettings[:session_key].should == 'A sample session key'
    GlobalSettings[:base_url].should == 'http://localhost:3000/'
    GlobalSettings['base_url'].should == 'http://localhost:3000/'

    GlobalSettings['base_url'] = 'http://localhost:5000/'
    GlobalSettings[:base_url].should == 'http://localhost:5000/'
  end

  it 'should validate unspecified ldap settings' do
    GlobalSettings.instance.authentication_mode = 1
    GlobalSettings.instance.should_not be_valid

    GlobalSettings.instance.update_attributes!(authentication_mode: 1,
                                               ldap_host: 'LDAP Host',
                                               ldap_component: 'LDAP Component')

    GlobalSettings.instance.should be_valid

    expect(GlobalSettings.ldap_enabled?).to be_truthy
    expect(GlobalSettings.cas_enabled?).to be_falsey
    expect(GlobalSettings.sso_enabled?).to be_falsey
    expect(GlobalSettings.default_authentication_enabled?).to be_falsey

    GlobalSettings[:ldap_host].should == 'LDAP Host'
    GlobalSettings[:ldap_component].should == 'LDAP Component'

    GlobalSettings[:ldap_port] = 'LDAP Port'
    GlobalSettings[:ldap_port].should == 'LDAP Port'
  end

  it 'should validate unspecified or incorrect cas settings' do
    GlobalSettings.instance.authentication_mode = 2
    GlobalSettings.instance.should_not be_valid

    GlobalSettings.instance.update_attributes!(authentication_mode: 2,
                                               cas_server: 'http://www.google.com')
    GlobalSettings.instance.should be_valid

    expect(GlobalSettings.cas_enabled?).to be_truthy
    expect(GlobalSettings.ldap_enabled?).to be_falsey
    expect(GlobalSettings.sso_enabled?).to be_falsey
    expect(GlobalSettings.default_authentication_enabled?).to be_falsey
  end

  it 'should be able to set and get forgot password' do
    GlobalSettings[:authentication_mode] = 0
    GlobalSettings.instance.should be_valid

    GlobalSettings[:ldap_host].should == ''
    GlobalSettings[:ldap_component].should == ''
    GlobalSettings[:ldap_port].should == ''

    GlobalSettings[:cas_server].should == ''

    expect(GlobalSettings.cas_enabled?).to be_falsey
    expect(GlobalSettings.ldap_enabled?).to be_falsey
    expect(GlobalSettings.default_authentication_enabled?).to be_truthy
    expect(GlobalSettings.sso_enabled?).to be_falsey

    expect(GlobalSettings.forgot_password?).to be_truthy

    GlobalSettings[:forgot_password] = false
    expect(GlobalSettings.forgot_password?).to be_falsey
    expect(GlobalSettings[:forgot_password]).to be_falsey
  end

  it 'should be able to set and get authentication mode sso' do
    GlobalSettings[:authentication_mode] = 3
    expect(GlobalSettings.cas_enabled?).to be_falsey
    expect(GlobalSettings.ldap_enabled?).to be_falsey
    expect(GlobalSettings.default_authentication_enabled?).to be_falsey
    expect(GlobalSettings.sso_enabled?).to be_truthy
  end


  it 'should retain automations settings' do
    expect(GlobalSettings.automation_enabled?).to be_falsey
    GlobalSettings[:automation_enabled] = true
    expect(GlobalSettings.automation_enabled?).to be_truthy

    GlobalSettings.bladelogic_enabled?.should be_nil
    GlobalSettings[:bladelogic_enabled].should be_nil

    GlobalSettings.capistrano_enabled?.should be_nil
    GlobalSettings[:capistrano_enabled].should be_nil

    GlobalSettings.hudson_enabled?.should be_nil
    GlobalSettings[:hudson_enabled].should be_nil

    GlobalSettings[:bladelogic_ip_address] = '10.20.20.20'
    GlobalSettings[:bladelogic_username] = 'BLAdmin'
    GlobalSettings[:bladelogic_password] = 'password'

    expect(GlobalSettings.bladelogic_ready?).to be_falsey

    GlobalSettings[:bladelogic_enabled] = true

    GlobalSettings[:bladelogic_profile] = 'BLProfile'
    GlobalSettings[:bladelogic_rolename] = 'BLAdmins'

    GlobalSettings[:bladelogic_ip_address].should == '10.20.20.20'
    GlobalSettings[:bladelogic_username].should == 'BLAdmin'
    GlobalSettings[:bladelogic_password].should == 'password'
    GlobalSettings[:bladelogic_profile].should == 'BLProfile'
    GlobalSettings[:bladelogic_rolename].should == 'BLAdmins'

    expect(GlobalSettings.bladelogic_ready?).to be_truthy

    #
    # Rajesh: TODO: Add more tests for checking automation available
    #
  end

  it 'should not able to retain its company profile' do
    GlobalSettings[:default_logo] = 'Logo.png'
    GlobalSettings[:company_name] = 'RJ Test Company'
    GlobalSettings[:calendar_preferences] = 'Foo Preferences'

    GlobalSettings[:default_logo].should == 'Logo.png'
    GlobalSettings[:company_name].should == 'RJ Test Company'
    GlobalSettings[:calendar_preferences].should == 'Foo Preferences'
  end

  it 'should be able to retain timezone and date format settings' do
    GlobalSettings.human_date_format.should_not be_nil
    GlobalSettings.instance.update_attributes!(default_date_format: '%d/%m/%Y %I:%M %p',
                                               timezone: 'Asia/Kolkata')
    GlobalSettings[:default_date_format].should == '%d/%m/%Y %I:%M %p'
    GlobalSettings[:timezone].should == 'Asia/Kolkata'
  end

  it 'should be able update and retain base_request_number' do
    GlobalSettings[:base_request_number] = 20000
    GlobalSettings[:base_request_number].should == 20000
  end

  it 'should be able to update and retain the limit_versions setting' do
    GlobalSettings[:limit_versions] = true
    expect(GlobalSettings.limit_versions?).to be_truthy
    expect(GlobalSettings[:limit_versions]).to be_truthy
  end

  it 'should be able to update and retain the messaging_enabled setting' do
    GlobalSettings[:messaging_enabled] = true
    expect(GlobalSettings.messaging_enabled?).to be_truthy
    expect(GlobalSettings[:messaging_enabled]).to be_truthy
  end

end
