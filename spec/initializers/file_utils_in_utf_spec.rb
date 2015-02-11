#encoding: utf-8
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe FileUtilsUTF do
  let(:dir_path)        { File.join(temp_dir, 'some', '应用c', 'cool份灾备path', '备环境应用启c') }
  let(:dir_to_cleanup)  { File.join(temp_dir, 'some') }
  let(:temp_dir) do
    absolute_path = File.expand_path(File.dirname(__FILE__))
    File.join(absolute_path, 'tmp')
  end

  before(:all)  { Dir.mkdir temp_dir rescue 'do nothing if exists' }
  before(:each) { FileUtilsUTF.rm_r dir_to_cleanup if File.directory? dir_to_cleanup}
  after(:all)   { FileUtilsUTF.rm_r temp_dir }

  it 'should create folder with unicode characters' do
    FileUtilsUTF.mkdir_p(dir_path)

    # File.directory?(dir_path) raises exception on Windows
    File.exists?(dir_path).should == true
  end

  it 'should not raise error when creating folder that already exists with unicode characters' do
    FileUtilsUTF.mkdir_p(dir_path)

    expect{ FileUtilsUTF.mkdir_p(dir_path) }.to_not raise_error
  end
end
