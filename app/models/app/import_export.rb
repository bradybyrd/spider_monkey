class App < ActiveRecord::Base

  acts_as_audited :only => [],  :protect => false

  class << self
    def import(import_file, importing_user, team, content_type)
      begin
        app = App.new
        app_hash = AppHashFactory.build(import_file, content_type)
      rescue => e
        Rails.logger.error("ERROR Application Import: " + e.message + "\n" + e.backtrace.join("\n"))
        app.errors.add(:app, "Import Error: #{e.message}")
      end
      import_app(app, importing_user, team, app_hash)
    end

    def import_app(app, importing_user, team, app_hash)
      if app.errors.present?
        app
      else
        app = App.find_or_initialize_by_name(app_hash.app_params["name"])
        import_app_objects(app, app_hash, importing_user, team)
      end
    end

    def valid_team?(app, team)
      app.new_record? || app.teams.map(&:id).include?(team.id)
    end

    def export(id)
      @app = find(id)
      message = "SS__ Exported application #{@app.name} to file for user #{User.current_user.name}"
      logger.info message
      Audit.export_audit(@app)
      @app
    end

    def build_app_header(app, params, team)
      if valid_team?(app, team)
        app.update_attributes!(params)
        team.app_ids += [app.id]
        app
      else
        raise I18n.t(:'app_import.team_error')
      end
    end

    def import_app_objects(app, app_hash, importing_user, team)
      begin
        ActiveRecord::Base.transaction do
          app = build_app_header(app, app_hash.app_params, team)
          ComponentImport.new(app_hash.components, app)
          @env_import = EnvironmentImport.new(app_hash.environments, app)
          InstalledComponent.import_app(app_hash.installed_components, app)
          Package.import_app(app_hash.packages, app)
          ApplicationPackage.import_app(app_hash.application_packages, app)
          BusinessProcessImport.new(app_hash.processes, app).call
          Request.import_app(app_hash.requests, app, importing_user)
          ProcedureImport.new(app_hash.procedures, app).call
          VersionTagImport.new(app_hash.version_tags, app)
          RouteImport.new(app_hash.routes, app)
          Audit.import_audit(app)
        end
        @env_import.deployment_windows.construct_all
      rescue => e
        Rails.logger.error("ERROR Application Import: " + e.message + "\n" + e.backtrace.join("\n"))
        app.errors.add(:app, "Import Error: #{e.message}")
      end
      app
    end
 end
end
