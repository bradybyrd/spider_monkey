#encoding: utf-8
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe FileInUTF do
  before(:each) do
    @content  = 'Unicode chars: 灾备环境应用启动'

    @file     = File.new('test', 'w')
    @file.puts @content
    @file.close
  end

  after(:all) do
    File.delete('test')
  end

  it 'should open file successfully' do
    output = FileInUTF.open('test', 'r').read
    output.chomp.should == @content
  end

  it 'should open and write to file' do
    filestream = FileInUTF.open('test', 'a+')
    filestream.puts @content
    filestream.close

    output =  FileInUTF.open('test').read
    output.chomp.should == @content + "\n" + @content
  end

  it 'should create new file' do
    FileInUTF.open('utf-file', 'w+') do |f|
      f.puts "灾备 = 2"
    end

    output = FileInUTF.open('utf-file').read
    output.chomp.should == "灾备 = 2"
  end
end