require "spec_helper"

describe BladelogicScript do
  before(:each) do
    @bladelogic_scr = BladelogicScript.new
  end

  let(:BladelogicScript_with_SharedScript) {
    BladelogicScript.new do
      include BladelogicScript::SharedScript
    end
  }

  it "should have many" do
    @bladelogic_scr.should have_many(:arguments)
    @bladelogic_scr.should have_many(:steps)
  end

  describe "validations" do
    before(:each) { create(:bladelogic_script) }
    it { @bladelogic_scr.should validate_presence_of(:name) }
    it { @bladelogic_scr.should validate_presence_of(:content) }
    it { @bladelogic_scr.should validate_presence_of(:authentication) }
    it { @bladelogic_scr.should validate_uniqueness_of(:name) }
  end

  describe "regular expressions" do
    it { BladelogicScript::OLD_ARGUMENT_REGEX.should == /\s*"""\r?\n(.+?)(\r?\n)+?\s*"""/m }
    it { BladelogicScript::ARGUMENT_REGEX.should == /\s*^###\r?\n(.+?)(\r?\n)+?\s*^###\r?/m }
  end

  describe "#constants" do
    it { BladelogicScript::DEFAULT_BLADELOGIC_SUPPORT_PATH.should == AutomationCommon::DEFAULT_AUTOMATION_SUPPORT_PATH }
    it { BladelogicScript::DEFAULT_BLADELOGIC_SCRIPTS_PATH.should == "#{Rails.root}/public/bladelogic_scripts" }
    it { BladelogicScript::DEFAULT_BLADELOGIC_SCRIPT_HEADER_PATH.should == "#{BladelogicScript::DEFAULT_BLADELOGIC_SUPPORT_PATH}/bladelogic_script_header.py" }
    it { BladelogicScript::DEFAULT_BLADELOGIC_ENV_HEADER_PATH.should == "#{BladelogicScript::DEFAULT_BLADELOGIC_SUPPORT_PATH}/bladelogic_env.py" }
  end

  describe "should serialize data" do
    it { should serialize(:choices).as(Array) }
  end

  describe 'callbacks' do
    it 'should run proper callback before save' do
      bladelogic_scr = create(:bladelogic_script)
      bladelogic_scr.should_receive(:check_content).ordered
      bladelogic_scr.should_receive(:set_script_type).ordered
      bladelogic_scr.send(:save, :validate => false)
    end

    it 'should run proper callback after save' do
      bladelogic_scr = create(:bladelogic_script)
      bladelogic_scr.should_receive(:update_arguments).ordered
      bladelogic_scr.send(:save)
    end

    it "should run proper callback after destroy" do
      bladelogic_scr = BladelogicScript.new
      bladelogic_scr.should_receive(:delete_content)
      bladelogic_scr.send(:destroy)
    end
  end

  it "should have #file_path" do
    @bladelogic_scr.file_path.should == "#{BladelogicScript::DEFAULT_BLADELOGIC_SCRIPTS_PATH}/#{@bladelogic_scr.id}.script"
  end

  it "should not have #project_server" do
    @bladelogic_scr.project_server.should == nil
  end

  it "should have #default_path" do
    @bladelogic_scr.send(:default_path).should == BladelogicScript::DEFAULT_BLADELOGIC_SCRIPTS_PATH
  end

  it "should have #argument_regex" do
    @bladelogic_scr.send(:argument_regex).should == BladelogicScript::ARGUMENT_REGEX
  end

end
