   xml = Builder::XmlMarkup.new
   
   unit = session[:scale_unit].present? ? session[:scale_unit] : 'm'
   options = {:caption=>'Environment Calendar', :manageResize => '1', :dateFormat => 'yyyy-mm-dd', :palette => '3', :exportHandler => 'fcExporter1', :exportEnabled => '1', :exportAtClient => '1'}
   
   screen_width = @width.blank? ? 1024 : @width
   usable_width = screen_width

   month_def_width = 200
   day_def_width = 75
   week_def_width = 200
   
   no_of_months_to_show = (usable_width/month_def_width).floor
   no_of_days_to_show = (usable_width/day_def_width).floor
   no_of_weeks_to_show = (usable_width/week_def_width).floor
   
   if session[:env_start].blank? and session[:env_end].blank?
    if unit == "m"
      first_date_last_month = (Time.now).at_end_of_month
      first_date_begin_month = first_date_last_month.months_ago(no_of_months_to_show - 1).at_beginning_of_month
    else
      first_date = Time.now - (3 * 24 * 60 * 60)
      first_date_begin_month = first_date
      first_date_last_month = Time.now + (3 * 24 * 60 * 60)
    end
  else
  
        if(unit == "m")
          if @beginning_of_calendar.present? and @end_of_calendar.blank?
            first_date_begin_month = @environment_calendar["p"].blank? ? Date.generate_from(@beginning_of_calendar).to_time.at_beginning_of_month : session[:env_start].at_beginning_of_month   
            first_date_last_month = first_date_begin_month.months_since(no_of_months_to_show - 1).at_end_of_month
          elsif @beginning_of_calendar.blank? and @end_of_calendar.present?
            first_date_last_month = @environment_calendar["p"].blank? ? Date.generate_from(@end_of_calendar).to_time.at_end_of_month : session[:env_end].at_end_of_month    
            first_date_begin_month = first_date_last_month.months_ago(no_of_months_to_show - 1).at_beginning_of_month
          elsif @beginning_of_calendar.present? and @end_of_calendar.present?
            if((@beginning_of_calendar.to_date > session[:env_start].at_beginning_of_month.to_date) && (@end_of_calendar.to_date < session[:env_end].at_end_of_month.to_date))
             first_date_begin_month = Date.generate_from(@beginning_of_calendar).to_time.at_beginning_of_month
             first_date_last_month = Date.generate_from(@beginning_of_calendar).to_time.at_beginning_of_month.months_since(no_of_months_to_show - 1).at_end_of_month
            else
             first_date_begin_month = @environment_calendar["p"].blank? ? Date.generate_from(@beginning_of_calendar).to_time.at_beginning_of_month : session[:env_start].at_beginning_of_month
             first_date_last_month = first_date_begin_month.months_since(no_of_months_to_show - 1).at_end_of_month
            end 
          elsif @beginning_of_calendar.blank? and @end_of_calendar.blank?
            first_date_begin_month = session[:env_start].at_beginning_of_month
            first_date_last_month = first_date_begin_month.months_since(no_of_months_to_show - 1).at_end_of_month
          end
      elsif(unit == "d")
          if @beginning_of_calendar.present? and @end_of_calendar.blank?
          first_date_begin_month = @environment_calendar["p"].blank? ? Date.generate_from(@beginning_of_calendar).to_time : session[:env_start]   
          first_date_last_month = (first_date_begin_month + (no_of_days_to_show * 24 * 60 * 60))
        elsif @beginning_of_calendar.blank? and @end_of_calendar.present?
          first_date_last_month = @environment_calendar["p"].blank? ? Date.generate_from(@end_of_calendar).to_time : session[:env_end]    
          first_date_begin_month = first_date_last_month.ago(no_of_days_to_show * 24 * 60 * 60)
        elsif @beginning_of_calendar.present? and @end_of_calendar.present?
          if((@beginning_of_calendar.to_date > session[:env_start].to_date) && (@end_of_calendar.to_date < session[:env_end].to_date))
           first_date_begin_month = Date.generate_from(@beginning_of_calendar).to_time
           first_date_last_month = Date.generate_from(@beginning_of_calendar).to_time + (no_of_days_to_show * 24 * 60 * 60)
          else
           first_date_begin_month = @environment_calendar["p"].blank? ? Date.generate_from(@beginning_of_calendar).to_time : session[:env_start]
           first_date_last_month = (first_date_begin_month + (no_of_days_to_show * 24 * 60 * 60))
          end 
        elsif @beginning_of_calendar.blank? and @end_of_calendar.blank?
          first_date_begin_month = session[:env_start]
          first_date_last_month = session[:env_start] + (no_of_days_to_show * 24 * 60 * 60)
        end
      elsif(unit == "w")
          if @beginning_of_calendar.present? and @end_of_calendar.blank?
          first_date_begin_month = @environment_calendar["p"].blank? ? Date.generate_from(@beginning_of_calendar).to_time : session[:env_start]   
          first_date_last_month = (first_date_begin_month + (no_of_weeks_to_show * 7 * 24 * 60 * 60))
        elsif @beginning_of_calendar.blank? and @end_of_calendar.present?
          first_date_last_month = @environment_calendar["p"].blank? ? Date.generate_from(@end_of_calendar).to_time : session[:env_end]    
          first_date_begin_month = first_date_last_month.weeks_ago(no_of_weeks_to_show)
        elsif @beginning_of_calendar.present? and @end_of_calendar.present?
          if((@beginning_of_calendar.to_date > session[:env_start].to_date) && (@end_of_calendar.to_date < session[:env_end].to_date))
           first_date_begin_month = Date.generate_from(@beginning_of_calendar).to_time
           first_date_last_month = Date.generate_from(@beginning_of_calendar).to_time + (no_of_weeks_to_show * 7 * 24 * 60 * 60)
          else
           first_date_begin_month = @environment_calendar["p"].blank? ? Date.generate_from(@beginning_of_calendar).to_time : session[:env_start]
           first_date_last_month = (first_date_begin_month + (no_of_weeks_to_show * 7 * 24 * 60 * 60))
          end 
        elsif @beginning_of_calendar.blank? and @end_of_calendar.blank?
          first_date_begin_month = session[:env_start]
          first_date_last_month = session[:env_start] + (no_of_weeks_to_show * 7 * 24 * 60 * 60)
        end
      end
     
  end
   
    if @environment_calendar["p"] == "L" and (unit == "m")
      first_date_begin_month = first_date_begin_month.months_ago(1)
      first_date_last_month = first_date_last_month.months_ago(1)
    elsif @environment_calendar["p"] == "L" and (unit == "d")
      first_date_begin_month = first_date_begin_month - (24 * 60 * 60)
      first_date_last_month = first_date_last_month - (24 * 60 * 60)
    elsif @environment_calendar["p"] == "R" and (unit == "m")
      first_date_begin_month = first_date_begin_month.months_since(1)
      first_date_last_month = first_date_last_month.months_since(1)
    elsif @environment_calendar["p"] == "R" and (unit == "d")
      first_date_begin_month = first_date_begin_month + (24 * 60 * 60)
      first_date_last_month = first_date_last_month + (24 * 60 * 60)
    elsif @environment_calendar["p"] == "L" and (unit == "w")
      first_date_begin_month = first_date_begin_month - (7 * 24 * 60 * 60)
      first_date_last_month = first_date_last_month - (7 * 24 * 60 * 60)
    elsif @environment_calendar["p"] == "R" and (unit == "w")
      first_date_begin_month = first_date_begin_month + (7 * 24 * 60 * 60)
      first_date_last_month = first_date_last_month + (7 * 24 * 60 * 60)
    end

    @environment_calendar.delete("p") if @environment_calendar["p"].present?
    
   session[:env_start] = first_date_begin_month
   session[:env_end] = first_date_last_month
   
   fdate = first_date_begin_month
   ldate = first_date_last_month
   
    xml.chart(options) do
      
   if unit == "m"
     xml.categories do
#      puts " %%%%%%%%%%%%%%%%%%% Total range --- #{first_date_begin_month} to #{first_date_last_month}" 
      while first_date_last_month > first_date_begin_month do
#        puts " In env_cal month xml.categories loop ==== #{first_date_begin_month.to_date} ------to #{first_date_begin_month.end_of_month.to_date}" 
        xml.category(:start => first_date_begin_month.to_date, :end => first_date_begin_month.end_of_month.to_date, :label=> first_date_begin_month.strftime("%b '%y"))
        first_date_begin_month = first_date_begin_month.next_month
      end
     end
   elsif unit == "d" 
     xml.categories do
#       puts "%%%%%%%%%%%%%%%%%%% Total range --- #{first_date_begin_month} to #{first_date_last_month}"
      while first_date_last_month > first_date_begin_month do
#        puts " In env_cal day xml.categories loop ==== #{first_date_begin_month.to_date} ------to #{first_date_begin_month.end_of_day.to_date}"
        xml.category(:start => first_date_begin_month.beginning_of_day.to_date, :end => first_date_begin_month.end_of_day.to_date, :label=> first_date_begin_month.strftime("%d %b '%y"))
        first_date_begin_month = first_date_begin_month.tomorrow
      end
     end
   elsif unit == "w" 
     xml.categories do
#       puts "%%%%%%%%%%%%%%%%%%% Total range --- #{first_date_begin_month} to #{first_date_last_month}"
      while first_date_last_month > first_date_begin_month do
#        puts " In env_cal week xml.categories loop ==== #{first_date_begin_month.to_date} ------to #{first_date_begin_month.end_of_day.to_date}"
        week_start = first_date_begin_month.beginning_of_day.to_date
        week_end = first_date_begin_month.beginning_of_day.since(7*24*60*60).to_date
        xml.category(:start => week_start, :end => week_end, :label=> week_start.strftime("%d %b")+ "-" + (week_end - 1).strftime("%d %b '%y"))
        first_date_begin_month = first_date_begin_month.since(7*24*60*60)
      end
     end
   end
      
      xml.processes(:align => "left", :headerText =>"Environment") do 
       @environment_calendar.each_pair do |hash_key, hash_value| 
            plan_id_array = hash_value.last if (hash_value && hash_value.last.present?)
          
          if plan_id_array && plan_id_array.size > 0  
            plan_id_array.each do |plan_id| 
              xml.process(:label=> hash_key.name, :id=> hash_key.name + plan_id.to_s)
            end 
          else
             xml.process(:label=> hash_key.name, :id=> hash_key.name + "_blank")
          end
          
        end
      end
      
      xml.datatable(:showProcessName =>'1') do #fontColor='333333' fontSize='11' isBold='1' headerFontColor='000000' headerFontSize='11' >
       xml.datacolumn(:width =>'150', :headerText =>'Release Plan', :align =>'left') do # headerfontSize='16' headerAlign='left' headerfontcolor='99cc00'  bgColor='99cc00' bgAlpha='65'>
        
         # All plan names for each environment.
         @environment_calendar.each_pair do |hash_key, hash_value|
          plan_id_array = hash_value.last if (hash_value && hash_value.last.present?)
          
          if plan_id_array && plan_id_array.size > 0  
            plan_id_array.each do |plan_id| 
              xml.text(:label => Plan.find(plan_id).name)
            end 
          else
             xml.text(:label => "-")
          end
          
       end
       
       end
     end
      
      color_hash = {}
      plans_array = []
      
      xml.tasks() do 
       initial_width = 0

       @environment_calendar.each_pair do |hash_key, hash_value|
       
         if hash_value.blank?
#           xml.task(:start => session[:env_start], :end => session[:env_start], :label=> "", :showLabel=>'0', :processId => hash_key.name, :height => '1', :color => 'FFFFFF')
         else
       
          plan_id_array = hash_value.last if (hash_value && hash_value.last.present?)
          hash_value.delete_at(hash_value.size - 1)
       
          hash_value.each do |hv| 
            plan = hv[2]
            plans_array << hv[2]
            
            plan_name = hv[2].name if hv[2].present? and plan_name.blank?
            color_hash[plan_name] = FusionChart::Colors.sample if (plan_name.present? and (hv[2].name!= plan_name or color_hash[plan_name].blank?))
            
            initial_width = initial_width + 35
            
            if hv[0].blank? and hv[1].blank?
              startdate = (hv[2].release_date - hv[2].release_date.days_to_week_start) if hv[2].release_date.present?
              enddate = hv[2].release_date if hv[2].release_date.present?
            elsif hv[0].present? and hv[1].blank?
              startdate = hv[0]
              enddate = hv[2].release_date if hv[2].release_date.present? 
            elsif hv[0].blank? and hv[1].present?
              startdate = hv[1] - hv[1].days_to_week_start
              enddate = hv[1]
            end
            skip_plan = true if plan.present? && plan.plan_env_app_dates.all?{|d| d.planned_start.blank? && d.planned_complete.blank?}
            
            tool_tip_text = "Application \n\t-" 
            app = App.find(hv[4])
            
            components_str = []
            
            app.application_environments.each do |app_env|
              app_env.installed_components.each do |ic|
                components_str << installed_component_name(ic) if ic
              end
            end
            
            components_str.uniq!
            
            tool_tip_text = tool_tip_text + app.name + "\n\nComponents \n\t-" + components_str.join("\n\t-") 
            
            start_date = hv[0].present? ? hv[0] : startdate
            end_date = hv[1].present? ? hv[1] : enddate
         
         if start_date.present? && end_date.present? && !skip_plan  
           app_name = App.find(hv[4]).name[0..15]
              
          if plan_id_array && plan_id_array.size > 0  
           plan_id_array.each do |plan_id|  # Check this logic               
                         
            if(start_date >= fdate.to_date && end_date <= ldate.to_date)
              xml.task(:start => start_date, :end => end_date.to_time.tomorrow.to_date, :processId => hash_key.name + plan_id.to_s, :height => '20', :animation => '1', :color => color_hash[plan_name], :toolText => tool_tip_text, :alpha => "60", :borderalpha => "100", :showborder => "1", :borderthickness => "2", :bordercolor => "000000") if hv[2].id == plan_id               
            elsif(start_date >= fdate.to_date && end_date >= ldate.to_date && start_date <= ldate.to_date)
              xml.task(:start => start_date, :end => ldate, :processId => hash_key.name + plan_id.to_s, :height => '20', :animation => '1', :color => color_hash[plan_name], :toolText => tool_tip_text, :alpha => "60", :borderalpha => "100", :showborder => "1", :borderthickness => "2", :bordercolor => "000000") if hv[2].id == plan_id
            elsif(start_date <= fdate.to_date && end_date <= ldate.to_date && end_date >= fdate.to_date)
              xml.task(:start => fdate, :end => end_date.to_time.tomorrow.to_date, :processId => hash_key.name + plan_id.to_s, :height => '20', :animation => '1', :color => color_hash[plan_name], :toolText => tool_tip_text, :alpha => "60", :borderalpha => "100", :showborder => "1", :borderthickness => "2", :bordercolor => "000000") if hv[2].id == plan_id             
            elsif(start_date <= fdate.to_date && end_date >= ldate.to_date)
              xml.task(:start => fdate, :end => ldate, :processId => hash_key.name + plan_id.to_s, :height => '20', :animation => '1', :color => color_hash[plan_name], :toolText => tool_tip_text, :alpha => "60", :borderalpha => "100", :showborder => "1", :borderthickness => "2", :bordercolor => "000000") if hv[2].id == plan_id
            end
           
           end
          
          else
            if(start_date >= fdate.to_date && end_date <= ldate.to_date)
              xml.task(:start => start_date, :end => end_date.to_time.tomorrow.to_date, :processId => hash_key.name + "_blank", :height => '20', :animation => '1', :color => color_hash[plan_name], :toolText => tool_tip_text, :alpha => "60", :borderalpha => "100", :showborder => "1", :borderthickness => "2", :bordercolor => "000000") if hv[2].id == plan_id               
            elsif(start_date >= fdate.to_date && end_date >= ldate.to_date && start_date <= ldate.to_date)
              xml.task(:start => start_date, :end => ldate, :processId => hash_key.name + "_blank", :height => '20', :animation => '1', :color => color_hash[plan_name], :toolText => tool_tip_text, :alpha => "60", :borderalpha => "100", :showborder => "1", :borderthickness => "2", :bordercolor => "000000") if hv[2].id == plan_id
            elsif(start_date <= fdate.to_date && end_date <= ldate.to_date && end_date >= fdate.to_date)
              xml.task(:start => fdate, :end => end_date.to_time.tomorrow.to_date, :processId => hash_key.name + "_blank", :height => '20', :animation => '1', :color => color_hash[plan_name], :toolText => tool_tip_text, :alpha => "60", :borderalpha => "100", :showborder => "1", :borderthickness => "2", :bordercolor => "000000") if hv[2].id == plan_id             
            elsif(start_date <= fdate.to_date && end_date >= ldate.to_date)
              xml.task(:start => fdate, :end => ldate, :processId => hash_key.name + "_blank", :height => '20', :animation => '1', :color => color_hash[plan_name], :toolText => tool_tip_text, :alpha => "60", :borderalpha => "100", :showborder => "1", :borderthickness => "2", :bordercolor => "000000") if hv[2].id == plan_id
            end
          end
         
         end 
            
            plan_name = hv[2].name if (hv[2].present? and hv[2].name!= plan_name)
          end
        end # end for if hash_value.blank?  
        initial_width = 0
       end 
      end
      
        xml.trendlines() do
        
           if(Date.today > fdate.to_date && Date.today < ldate.to_date)
             xml.line(:start => Date.today.strftime('%Y-%m-%d'), :color => 'FF0000', :displayValue => "Today", :thickness => "3", :dashed => "1", :dashLen => "10", :dashGap => "10")
           end
           
           plans_array = plans_array.uniq 
           plans_array.each do |plan|
             if(plan.release_date.present? && plan.release_date >= Date.today && plan.release_date >= fdate.to_date && plan.release_date <= ldate.to_date) 
               display_value = (plan.release_date == Date.today) ? " " : plan.release_date.strftime('%d')  
               xml.line(:start => plan.release_date.strftime('%Y-%m-%d'), :displayValue => display_value, :color => color_hash["#{plan.name}"], :thickness => "3", :dashed => "0", :alpha => "60")
             end
           end
           
           plans = Plan.entitled(User.current_user).includes(:plan_env_app_dates).all
           plans.each do |plan|
             if plan.plan_env_app_dates.blank? and plan.release_date.present?
               if(plan.release_date >= Date.today && plan.release_date >= fdate.to_date && plan.release_date <= ldate.to_date) 
                 xml.line(:start => plan.release_date.strftime('%Y-%m-%d'), :displayValue => plan.release_date.strftime('%d'), :color => 'FF0000', :thickness => "2", :dashed => "0")
               end  
             end
           end
             
        end
      
    end