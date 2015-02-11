def execute(script_params, parent_id, offset, max_records)
  set_hudson_config([SS_hudson_dns, SS_hudson_username, SS_hudson_password])
  jobs = get_hudson_jobs
  jobs_hash = {}
  jobs_hash["Select"] = ""
  jobs.each do |job|
    jobs_hash[job] = job
  end
  return [jobs_hash]
end