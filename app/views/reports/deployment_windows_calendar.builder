xml = Builder::XmlMarkup.new

options = { caption: 'Deployment Windows Calendar',
            manageResize: '1',
            dateFormat: 'yyyy-mm-dd',
            palette: '3',
            exportHandler: 'fcExporter1',
            exportEnabled: '1',
            exportAtClient: '1',
            paletteColors: 'FF0000,0372AB,FF5904' }

xml.chart(options) do
  xml.categories do
    presenter.each_category do |category_options|
      xml.category category_options
    end
  end

  xml.processes(align: "left", headerText: "Release Plan") do
    presenter.each_environment do |environment|
      xml.process label: environment.release_plan_diagram_label,
                  id: environment.id,
                  height: '20'
    end
  end

  xml.datatable(showProcessName:'1') do
    xml.datacolumn(width: '150', height: '20', headerText: 'Environment', align: 'left') do
      presenter.each_environment do |environment|
        xml.text label: environment.name,
                 height: '20'
      end
    end
  end

  xml.tasks(showLabels: '1') do
    presenter.each_environment do |environment|
      environment.deployment_windows.each do |deployment_window_presenter|
        xml.task start: deployment_window_presenter.start_at,
                 end: deployment_window_presenter.finish_at,
                 processId: environment.id,
                 height: '10',
                 animation: false,
                 color: deployment_window_presenter.color,
                 toolText: deployment_window_presenter.tool_text,
                 alpha: '50',
                 borderalpha: '',
                 showborder: '',
                 borderthickness: deployment_window_presenter.border_thickness,
                 bordercolor: deployment_window_presenter.border_color,
                 label: deployment_window_presenter.requests_count,
                 showLabel: true,
                 link: "javascript:ReportsDiagram.ContextMenu.show(#{deployment_window_presenter.id},#{deployment_window_presenter.series?});",
                 showAsGroup: deployment_window_presenter.series?,
                 event_id: deployment_window_presenter.id,
                 permitted_actions: deployment_window_presenter.permitted_actions(current_user)
      end
    end
  end

  xml.trendlines do
    xml.line presenter.trendline_attributes
  end
end
