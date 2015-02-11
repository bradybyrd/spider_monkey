class BusinessProcessImport

  attr_reader :processes, :app

  def initialize(processes, app)
    @processes = processes || []
    @app = app
  end

  def call
    processes.map do |process_params|
      build_process_from_params(process_params)
    end
  end

  private

  def build_process_from_params(process_params)
    BusinessProcess.where(name: process_params['name']).first_or_create! do |process|
      process.label_color = process_params['label_color']
      process.apps = [app]
    end
  end

end
