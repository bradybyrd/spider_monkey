################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

require File.dirname(__FILE__) + '/../spec_helper'

describe StepScriptArgument do
  before(:each) do
    @step_script_argument = StepScriptArgument.new
  end

  it { @step_script_argument.should belong_to(:step) }

  it { @step_script_argument.should belong_to(:script_argument) }
  it {  should respond_to :argument }
  describe "delegations" do
    it "delegate argument to script argument" do
      @script_argument = create(:step_script_argument, :value => Time.now.to_s+"argument")
      @step_script_argument.script_argument = @script_argument
      @script_argument.should_receive(:argument)
      @step_script_argument.argument
    end
  end
end
