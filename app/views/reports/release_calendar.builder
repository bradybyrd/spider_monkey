xml = Builder::XmlMarkup.new

unit = session[:scale_unit].present? ? session[:scale_unit] : 'm'
options = {:caption=>'Release Calendar', :manageResize => '1', :dateFormat => 'yyyy-mm-dd', :palette => '3', :exportHandler => 'fcExporter1', :exportEnabled => '1', :exportAtClient => '1'}

screen_width = @width.blank? ? 1024 : @width
usable_width = screen_width

month_def_width = 200
day_def_width = 75
week_def_width = 200

no_of_months_to_show = (usable_width/month_def_width).floor
no_of_days_to_show = (usable_width/day_def_width).floor
no_of_weeks_to_show = (usable_width/week_def_width).floor

if session[:rel_start].blank? and session[:rel_end].blank?
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
      first_date_begin_month = @release_calendar["p"].blank? ? Date.generate_from(@beginning_of_calendar).to_time.at_beginning_of_month : session[:rel_start].at_beginning_of_month
      first_date_last_month = first_date_begin_month.months_since(no_of_months_to_show - 1).at_end_of_month
    elsif @beginning_of_calendar.blank? and @end_of_calendar.present?
      first_date_last_month = @release_calendar["p"].blank? ? Date.generate_from(@end_of_calendar).to_time.at_end_of_month : session[:rel_end].at_end_of_month
      first_date_begin_month = first_date_last_month.months_ago(no_of_months_to_show - 1).at_beginning_of_month
    elsif @beginning_of_calendar.present? and @end_of_calendar.present?
      if((@beginning_of_calendar.to_date > session[:rel_start].at_beginning_of_month.to_date) && (@end_of_calendar.to_date < session[:rel_end].at_end_of_month.to_date))
        first_date_begin_month = Date.generate_from(@beginning_of_calendar).to_time.at_beginning_of_month
        first_date_last_month = Date.generate_from(@beginning_of_calendar).to_time.at_beginning_of_month.months_since(no_of_months_to_show - 1).at_end_of_month
      else
        first_date_begin_month = @release_calendar["p"].blank? ? Date.generate_from(@beginning_of_calendar).to_time.at_beginning_of_month : session[:rel_start].at_beginning_of_month
        first_date_last_month = first_date_begin_month.months_since(no_of_months_to_show - 1).at_end_of_month
      end
    elsif @beginning_of_calendar.blank? and @end_of_calendar.blank?
      first_date_begin_month = session[:rel_start].at_beginning_of_month
      first_date_last_month = first_date_begin_month.months_since(no_of_months_to_show - 1).at_end_of_month
    end
  elsif(unit == "d")
    if @beginning_of_calendar.present? and @end_of_calendar.blank?
      first_date_begin_month = @release_calendar["p"].blank? ? Date.generate_from(@beginning_of_calendar).to_time : session[:rel_start]
      first_date_last_month = (first_date_begin_month + (no_of_days_to_show * 24 * 60 * 60))
    elsif @beginning_of_calendar.blank? and @end_of_calendar.present?
      first_date_last_month = @release_calendar["p"].blank? ? Date.generate_from(@end_of_calendar).to_time : session[:rel_end]
      first_date_begin_month = first_date_last_month.ago(no_of_days_to_show * 24 * 60 * 60)
    elsif @beginning_of_calendar.present? and @end_of_calendar.present?
      if((@beginning_of_calendar.to_date > session[:rel_start].to_date) && (@end_of_calendar.to_date < session[:rel_end].to_date))
        first_date_begin_month = Date.generate_from(@beginning_of_calendar).to_time
        first_date_last_month = Date.generate_from(@beginning_of_calendar).to_time + (no_of_days_to_show * 24 * 60 * 60)
      else
        first_date_begin_month = @release_calendar["p"].blank? ? Date.generate_from(@beginning_of_calendar).to_time : session[:rel_start]
        first_date_last_month = (first_date_begin_month + (no_of_days_to_show * 24 * 60 * 60))
      end
    elsif @beginning_of_calendar.blank? and @end_of_calendar.blank?
      first_date_begin_month = session[:rel_start]
      first_date_last_month = session[:rel_start] + (no_of_days_to_show * 24 * 60 * 60)
    end
  elsif(unit == "w")
    if @beginning_of_calendar.present? and @end_of_calendar.blank?
      first_date_begin_month = @release_calendar["p"].blank? ? Date.generate_from(@beginning_of_calendar).to_time : session[:rel_start]
      first_date_last_month = (first_date_begin_month + (no_of_weeks_to_show * 7 * 24 * 60 * 60))
    elsif @beginning_of_calendar.blank? and @end_of_calendar.present?
      first_date_last_month = @release_calendar["p"].blank? ? Date.generate_from(@end_of_calendar).to_time : session[:rel_end]
      first_date_begin_month = first_date_last_month.weeks_ago(no_of_weeks_to_show)
    elsif @beginning_of_calendar.present? and @end_of_calendar.present?
      if((@beginning_of_calendar.to_date > session[:rel_start].to_date) && (@end_of_calendar.to_date < session[:rel_end].to_date))
        first_date_begin_month = Date.generate_from(@beginning_of_calendar).to_time
        first_date_last_month = Date.generate_from(@beginning_of_calendar).to_time + (no_of_weeks_to_show * 7 * 24 * 60 * 60)
      else
        first_date_begin_month = @release_calendar["p"].blank? ? Date.generate_from(@beginning_of_calendar).to_time : session[:rel_start]
        first_date_last_month = (first_date_begin_month + (no_of_weeks_to_show * 7 * 24 * 60 * 60))
      end
    elsif @beginning_of_calendar.blank? and @end_of_calendar.blank?
      first_date_begin_month = session[:rel_start]
      first_date_last_month = session[:rel_start] + (no_of_weeks_to_show * 7 * 24 * 60 * 60)
    end
  end

end

if @release_calendar["p"] == "L" and (unit == "m")
  first_date_begin_month = first_date_begin_month.months_ago(1).at_beginning_of_month
  first_date_last_month = first_date_last_month.months_ago(1).at_end_of_month
elsif @release_calendar["p"] == "L" and (unit == "d")
  first_date_begin_month = first_date_begin_month - (24 * 60 * 60)
  first_date_last_month = first_date_last_month - (24 * 60 * 60)
elsif @release_calendar["p"] == "R" and (unit == "m")
  first_date_begin_month = first_date_begin_month.months_since(1).at_beginning_of_month
  first_date_last_month = first_date_last_month.months_since(1).at_end_of_month
elsif @release_calendar["p"] == "R" and (unit == "d")
  first_date_begin_month = first_date_begin_month + (24 * 60 * 60)
  first_date_last_month = first_date_last_month + (24 * 60 * 60)
elsif @release_calendar["p"] == "L" and (unit == "w")
  first_date_begin_month = first_date_begin_month - (7 * 24 * 60 * 60)
  first_date_last_month = first_date_last_month - (7 * 24 * 60 * 60)
elsif @release_calendar["p"] == "R" and (unit == "w")
  first_date_begin_month = first_date_begin_month + (7 * 24 * 60 * 60)
  first_date_last_month = first_date_last_month + (7 * 24 * 60 * 60)
end

@release_calendar.delete("p") if @release_calendar["p"].present?

session[:rel_start] = first_date_begin_month
session[:rel_end] = first_date_last_month

fdate = first_date_begin_month
ldate = first_date_last_month

xml.chart(options) do

  if unit == "m"
    xml.categories do
      #    logger.info " %%%%%%%%%%%%%%%%%%% Total range --- #{first_date_begin_month} to #{first_date_last_month}"
      while first_date_last_month > first_date_begin_month do
        #      logger.info " In rel_cal month xml.categories loop ==== #{first_date_begin_month.to_date} ------to #{first_date_begin_month.end_of_month.to_date}"
        xml.category(:start => first_date_begin_month.to_date,
                     :end => first_date_begin_month.end_of_month.to_date,
                     :label=> first_date_begin_month.strftime("%b '%y"))
        first_date_begin_month = first_date_begin_month.next_month
      end
    end
  elsif unit == "d"
    xml.categories do
      #     logger.info " 1st logger %%%%%%%%%%%%%%%%%%% Total range --- #{first_date_begin_month} to #{first_date_last_month}"
      while first_date_last_month > first_date_begin_month do
        #      logger.info " In rel_cal day xml.categories loop ==== #{first_date_begin_month.to_date} ------to #{first_date_begin_month.end_of_day.to_date}"
        xml.category(:start => first_date_begin_month.beginning_of_day.to_date, :end => first_date_begin_month.end_of_day.to_date, :label=> first_date_begin_month.strftime("%d %b '%y"))
        first_date_begin_month = first_date_begin_month.tomorrow
      end
    end
  elsif unit == "w"
    xml.categories do
      #     logger.info "%%%%%%%%%%%%%%%%%%% Total range --- #{first_date_begin_month} to #{first_date_last_month}"
      while first_date_last_month > first_date_begin_month do
        #      logger.info " In rel_cal week xml.categories loop ==== #{first_date_begin_month.to_date} ------to #{first_date_begin_month.end_of_day.to_date}"
        week_start = first_date_begin_month.beginning_of_day.to_date
        week_end = first_date_begin_month.beginning_of_day.since(7*24*60*60).to_date
        xml.category(:start => week_start, :end => week_end, :label=> week_start.strftime("%d %b")+ "-" + (week_end - 1).strftime("%d %b '%y"))
        first_date_begin_month = first_date_begin_month.since(7*24*60*60)
      end
    end
  end

##### ##### ##### ##### #####
#####       DATA        #####
##### ##### ##### ##### #####

  xml.processes(:align => "left", :headerText =>"Release Plan") do
    @release_calendar.each_pair do |hash_key, hash_value|
      env_id_array = hash_value.last if (hash_value && hash_value.last.present?)

      if env_id_array && env_id_array.size > 0
        env_id_array.each do |env_id|
          xml.process(:label=> hash_key.name, :id=> hash_key.name + env_id.to_s)
        end
      else
        xml.process(:label=> hash_key.name, :id=> hash_key.name + "_blank")
      end

    end
  end

  xml.datatable(:showProcessName =>'1') do #fontColor='333333' fontSize='11' isBold='1' headerFontColor='000000' headerFontSize='11' >
    xml.datacolumn(:width =>'150', :headerText =>'Environment', :align =>'left') do # headerfontSize='16' headerAlign='left' headerfontcolor='99cc00'  bgColor='99cc00' bgAlpha='65'>

      # All plan names for each environment.
      @release_calendar.each_pair do |hash_key, hash_value|
        env_id_array = hash_value.last if (hash_value && hash_value.last.present?)

        if env_id_array && env_id_array.size > 0
          env_id_array.each do |env_id|
            xml.text(:label => Environment.find_by_id(env_id).try(:name))
          end
        else
          xml.text(:label => "-")
        end

      end

    end
  end



  color_hash = {}

  xml.tasks() do
    initial_width = 0

    @release_calendar.each_pair do |hash_key, hash_value|

      if hash_value.blank?
        # xml.task(:start => session[:rel_start], :end => session[:rel_start], :label=> "", :showLabel=>'0', :processId => hash_key.name, :height => '1', :color => 'FFFFFF')
      else
        no_of_taskbars = hash_value.count
        no_of_taskbars_shown = 0

        env_id_array = hash_value.last if (hash_value && hash_value.last.present?)
        hash_value.delete_at(hash_value.size - 1)


        hash_value.each do |hv|
          no_of_taskbars_shown = no_of_taskbars_shown + 1
          initial_width = initial_width + 35

          env_name = hv[2].name if hv[2].name.present? and env_name.blank?
          color_hash[env_name] = FusionChart::Colors.sample if (env_name.present? and (hv[2].name!= env_name or color_hash[env_name].blank?))

          if hv[0].blank? and hv[1].blank?
            startdate = (hash_key.release_date - hash_key.release_date.days_to_week_start) if hash_key.release_date.present?
            enddate = hash_key.release_date if hash_key.release_date.present?
          elsif hv[0].present? and hv[1].blank?
            startdate = hv[0]
            enddate = hash_key.release_date if hash_key.release_date.present?
          elsif hv[0].blank? and hv[1].present?
            startdate = hv[1] - hv[1].days_to_week_start
            enddate = hv[1]
          end

          start_date = hv[0].present? ? hv[0] : startdate
          end_date = hv[1].present? ? hv[1] : enddate

          if start_date.present? and end_date.present?
            app_name = App.find(hv[4]).name[0..15]
            tool_text = start_date.strftime("%d %b '%y") + " to " + end_date.strftime("%d %b '%y") + " , " + app_name

            if env_id_array && env_id_array.size > 0
              env_id_array.each do |env_id|  # Check this logic

                if(start_date >= fdate.to_date && end_date <= ldate.to_date)
                  xml.task(:start => start_date, :end => end_date.to_time.tomorrow.to_date, :processId => hash_key.name + env_id.to_s, :height => '20', :animation => '1', :color => color_hash[env_name], :toolText => tool_text, :alpha => "60", :borderalpha => "100", :showborder => "1", :borderthickness => "2", :bordercolor => "000000") if hv[2].id == env_id
                elsif(start_date >= fdate.to_date && end_date >= ldate.to_date && start_date <= ldate.to_date)
                  xml.task(:start => start_date, :end => ldate, :processId => hash_key.name + env_id.to_s, :height => '20', :animation => '1', :color => color_hash[env_name], :toolText => tool_text, :alpha => "60", :borderalpha => "100", :showborder => "1", :borderthickness => "2", :bordercolor => "000000") if hv[2].id == env_id
                elsif(start_date <= fdate.to_date && end_date <= ldate.to_date && end_date >= fdate.to_date)
                  xml.task(:start => fdate, :end => end_date.to_time.tomorrow.to_date, :processId => hash_key.name + env_id.to_s, :height => '20', :animation => '1', :color => color_hash[env_name], :toolText => tool_text, :alpha => "60", :borderalpha => "100", :showborder => "1", :borderthickness => "2", :bordercolor => "000000") if hv[2].id == env_id
                elsif(start_date <= fdate.to_date && end_date >= ldate.to_date)
                  xml.task(:start => fdate, :end => ldate, :processId => hash_key.name + env_id.to_s, :height => '20', :animation => '1', :color => color_hash[env_name], :toolText => tool_text, :alpha => "60", :borderalpha => "100", :showborder => "1", :borderthickness => "2", :bordercolor => "000000") if hv[2].id == env_id
                end

                if (hash_key.release_date.present? && hash_key.release_date >= Date.today && hash_key.release_date >= fdate.to_date && hash_key.release_date <= ldate.to_date)
                  xml.task(:start => hash_key.release_date, :end => hash_key.release_date.tomorrow, :processId => hash_key.name + env_id.to_s, :height => '20', :animation => '1', :color => "FF0000", :toolText => "Release date - " + hash_key.release_date.strftime("%d %b '%y"), :alpha => "20", :borderalpha => "100", :showborder => "1", :borderthickness => "1", :bordercolor => "000000")
                end

              end

            else
              if(start_date >= fdate.to_date && end_date <= ldate.to_date)
                xml.task(:start => start_date, :end => end_date.to_time.tomorrow.to_date, :processId => hash_key.name + "_blank", :height => '20', :animation => '1', :color => color_hash[env_name], :toolText => tool_text, :alpha => "60", :borderalpha => "100", :showborder => "1", :borderthickness => "2", :bordercolor => "000000") if hv[2].id == env_id
              elsif(start_date >= fdate.to_date && end_date >= ldate.to_date && start_date <= ldate.to_date)
                xml.task(:start => start_date, :end => ldate, :processId => hash_key.name + "_blank", :height => '20', :animation => '1', :color => color_hash[env_name], :toolText => tool_text, :alpha => "60", :borderalpha => "100", :showborder => "1", :borderthickness => "2", :bordercolor => "000000") if hv[2].id == env_id
              elsif(start_date <= fdate.to_date && end_date <= ldate.to_date && end_date >= fdate.to_date)
                xml.task(:start => fdate, :end => end_date.to_time.tomorrow.to_date, :processId => hash_key.name + "_blank", :height => '20', :animation => '1', :color => color_hash[env_name], :toolText => tool_text, :alpha => "60", :borderalpha => "100", :showborder => "1", :borderthickness => "2", :bordercolor => "000000") if hv[2].id == env_id
              elsif(start_date <= fdate.to_date && end_date >= ldate.to_date)
                xml.task(:start => fdate, :end => ldate, :processId => hash_key.name + "_blank", :height => '20', :animation => '1', :color => color_hash[env_name], :toolText => tool_text, :alpha => "60", :borderalpha => "100", :showborder => "1", :borderthickness => "2", :bordercolor => "000000") if hv[2].id == env_id
              end

              if (hash_key.release_date.present? && hash_key.release_date >= Date.today && hash_key.release_date >= fdate.to_date && hash_key.release_date <= ldate.to_date)
                xml.task(:start => hash_key.release_date, :end => hash_key.release_date.tomorrow, :processId => hash_key.name + "_blank", :height => '20', :animation => '1', :color => "FF0000", :toolText => "Release date - " + hash_key.release_date.strftime("%d %b '%y"), :alpha => "20", :borderalpha => "100", :showborder => "1", :borderthickness => "1", :bordercolor => "000000")
              end

            end

          end

          env_name = hv[2].name if (hv[2].name.present? and hv[2].name!= env_name)
        end

      end # end for if hash_value.blank?
      initial_width = 0
    end
  end


  xml.trendlines() do
    if(Date.today > fdate.to_date && Date.today < ldate.to_date)
      xml.line(:start => Date.today.strftime('%Y-%m-%d'), :color => 'FF0000', :displayValue => "Today", :thickness => "2", :dashed => "1")
    end
  end

end
