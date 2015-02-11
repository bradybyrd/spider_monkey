require "spec_helper"

describe ProcessPerformanceHelper do
  context "#full_chart_path" do
    it "returns path with filters" do
      result = helper.full_chart_path('/root', {:filters => {:name => [1]}, :key => 'val1'})
      result.should eql("/root?key=val1&filters[name][]=1&")
    end

    it "returns path" do
      helper.full_chart_path('/root').should eql('/root')
    end
  end

  it '#processes_array' do
    business_process = create(:business_process)
    expect(helper.processes_array).to eq [[business_process.id,
                                          business_process.name,
                                          BusinessProcess::ColorCodes[business_process.id]]]
  end

  context "#current_report?" do
    it "returns current_page" do
      helper.stub(:current_link?).and_return(true)
      helper.current_report?.should eql("current_page")
    end

    it "returns nothing" do
      helper.stub(:current_link?).and_return(false)
      helper.current_report?.should eql("")
    end
  end
end