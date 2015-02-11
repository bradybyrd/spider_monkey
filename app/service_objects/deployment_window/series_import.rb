module DeploymentWindow
  class SeriesImport

    def initialize
      @series_constructs = []
    end

    def add(series_hash, env)
      @series_hash = series_hash || {}
      @env = env
      @series_constructs += series_constructs_list
    end

    def construct_all
      @series_constructs.map do |construct|
        series_construction(construct)
      end
    end

    private

    def series_constructs_list
      @series_hash.map do |series_params|
        construct = build_constructs(series_params)
        if construct.present? && !construct.valid?
          raise 'Deployment Window Series ' + construct.errors.full_messages.to_sentence
        end
        construct
      end.compact
    end

    def build_constructs(params)
      if series_valid?(params) && !existing_constructs?(params)
        series = DeploymentWindow::Series.find_or_initialize_by_name(params['name'])
        series.is_import = true
        params = build_series_params(params.symbolize_keys, series)
        DeploymentWindow::SeriesConstruct.new(params, series)
      end
    end

    def existing_constructs?(params)
      @series_constructs.each do |construct|
        if construct.series[:name] == params['name']
          construct.series.environment_ids |= [@env.id]
          return true
        end
      end
      false
    end

    def series_new?(construct)
      construct.series.new_record?
    end

    def series_construction(construct)
      success = series_new?(construct) ? construct.create : construct.update
      if success
        construct.series
      else
        raise construct.series.errors.messages[:base].to_s
      end
    end

    def build_series_params(params, series)
      params[:frequency] = params.delete(:schedule_data).first['json_string']
      params = find_creator(params)
      params[:environment_ids] = series.environments.map(&:id) | [@env.id]
      parse_time_params(params, series)
    end

    def find_creator(params)
      if params.has_key?(:creator) && user_hash = params.delete(:creator)
        user = User.find_by_last_name_and_first_name(user_hash['last_name'], user_hash['first_name'])
        params[:created_by] = user.id if user
      end
      params
    end

    def parse_time_params(params, series)
      [:start_at, :finish_at].each do |key|
        if start_date_frozen?(key, series)
          params.delete(key)
        else
          params = set_date(params, key, series)
        end
      end
      ::MappedParams::Multiparameters.({ deployment_window_series: params }, DeploymentWindow::Series)
    end

    def set_date(params, key, series)
      date = date_from_params(params, key)
      params[:"#{key}(4i)"] = date.strftime('%H')
      params[:"#{key}(5i)"] = date.strftime('%M')
      if need_to_change_start?(params, key, series)
        date = DateTime.now.tomorrow.in_time_zone(GlobalSettings[:timezone])
      end
      params[key] = date.strftime('%m/%d/%Y')
      params
    end

    def date_from_params(params, key)
      if params[key].is_a? String
        params[key] = Time.parse(params[key])
      end
      params[key].in_time_zone(GlobalSettings[:timezone])
    end

    def start_date_frozen?(key, series)
      key == :start_at && !series.new_record?
    end

    def need_to_change_start?(params, key, series)
      key == :start_at && params[key].to_date <= DateTime.now.to_date && series.new_record?
    end

    def series_valid?(params)
      ((params['behavior'] == 'allow' && @env.deployment_policy == 'closed') ||
      (params['behavior'] == 'prevent' && @env.deployment_policy == 'opened')) &&
      params['finish_at'].to_date > DateTime.now.to_date
    end
  end
end