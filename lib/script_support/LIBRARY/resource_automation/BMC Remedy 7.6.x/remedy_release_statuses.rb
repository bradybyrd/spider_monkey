def execute(script_params, parent_id, offset, max_records)
  [ {'Select' => ''},
    {'Draft' => 1000},
    {'Registered' => 2000},
    {'Pending' => 3000},
    {'Initiation Approval' => 3100},
    {'Planning Approval' => 3200},
    {'Build Approval' => 3300},
    {'Test Approval' => 3400},
    {'Deployment Approval' => 3500},
    {'Close Down Approval' => 3600},
    {'In Progress' => 4000},
    {'Rejected' => 5000},
    {'Completed' => 6000},
    {'Cancelled' => 7000},
    {'Closed' => 8000}
  ]
end
