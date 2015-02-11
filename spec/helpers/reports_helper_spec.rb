require "spec_helper"

describe ReportsHelper do
  it "#report_period_options" do
    periods = ["last week", "last 2 weeks", "last month", "last 3 months", "last year"]
    result = helper.report_period_options
    periods.each { |el| result.should include("<option value=\"#{el}\">#{el}</option>")}
  end

  describe "#filter_x_axis" do
    it "returns 'Month'" do
      helper.filter_x_axis({:precision => nil}, 'precision').should eql('Month')
    end

    it "returns 'Part of'" do
      helper.filter_x_axis({:pre => nil}, 'pre').should eql('Part of')
    end
  end

  describe "#load_reports_js" do
    specify "volume_report" do
      helper.load_reports_js('volume_report').should include('/FusionCharts/FusionCharts')
    end

    specify "problem_trend_report" do
      helper.load_reports_js('problem_trend_report').should include('FusionChartsExportComponent')
    end

    specify "time_of_problem" do
      helper.load_reports_js('time_of_problem').should include('PowerCharts/Charts/FusionCharts')
    end

    specify "time_to_complete" do
      helper.load_reports_js('time_to_complete').should include('FusionChartsExportComponent')
    end
  end

  describe "#report_title" do
    it "returns Process Reports" do
      helper.report_title(nil).should eql("Process Reports")
    end

    it "returns Release Calendar Report" do
      helper.report_title('release_calendar').should eql("Release Calendar Report")
    end

    it "returns Environment Calendar Report" do
      helper.report_title("environment_calendar").should eql("Environment Calendar Report")
    end
  end

  describe "#select_group_on" do
    it "returns 'part of'" do
      helper.select_group_on(nil).should eql('part of')
    end

    it "returns group on value" do
      helper.select_group_on({:group_on => 'some'}).should eql('some')
    end
  end

  describe "#select_precision" do
    it "returns 'month'" do
      helper.select_precision(nil).should eql('month')
    end

    it "returns precision value" do
      helper.select_precision({:precision => 'some'}).should eql('some')
    end
  end

  describe "@selected_date" do
    it "returns date" do
      GlobalSettings.create
      date = Date.today.strftime(GlobalSettings[:default_date_format])
      helper.selected_date(Date.today).should eql(date)
    end

    it "returns nil" do
      helper.selected_date(nil).should eql(nil)
    end
  end
end
