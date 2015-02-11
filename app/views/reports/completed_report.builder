# This code will not be usefull now and will be removed as per new reports

# xml.instruct! :xml, :version=>"1.0", :encoding=>"UTF-8"

# xml.chart do
# 	xml.series do
# 		@completed_report.each_with_index do |data, index|
# 			xml.value data[:app],  :xid => index
# 		end
# 	end
# 	xml.graphs do
# 		FusionChart::NonFunctionalRequests.each_with_index do |p, i|
# 			xml.graph :gid => i, :title => p[:title], :color => p[:color]  do
# 				@completed_report.each_with_index do |data, index|
# 					xml.value data[:requests][i], :xid => index, :color => p[:color], :url => "javascript:displayRequests(#{data[:request_ids]})"
# 				end
# 			end
# 		end
# 	end
# end
# session[:restore_report] = session[:completed_report] || session[:restore_report]
# session[:completed_report] = nil

