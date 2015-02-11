if OracleAdapter
  # get oracle to treat most fields with date in the name as rails dates
  ActiveRecord::ConnectionAdapters::OracleEnhancedAdapter.emulate_dates_by_column_name = true 
end

