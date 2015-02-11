xml.instruct! :xml, :version=>"1.0", :encoding=>"UTF-8"

xml.chart do
	xml.series do
		@problem_time.each_with_index do |data, index|
			xml.value data[:app],  :xid => index
		end
	end
	xml.graphs do
		AmChart::ProblemTypes.each_with_index do |p, i|
			xml.graph :gid => i, :title => p[:title], :color => p[:color]  do
				@problem_time.each_with_index do |data, index|
					xml.value data[:problem_time][i], :xid => index, :color => p[:color], :url => "j-displayRequests(#{data[:request_ids]})"
				end
			end
		end
	end
end
session[:restore_report] = session[:problem_time] || session[:restore_report]
session[:problem_time] = nil

