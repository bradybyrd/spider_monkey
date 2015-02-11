def execute(script_params, parent_id, offset, max_records)
  [ {'Select' => ''},
    {'Staged' => 1000},
    {'Assigned' => 2000},
    {'Pending' => 3000},
    {'Work In Progress' => 4000},
    {'Waiting' => 5000},
    {'Closed' => 6000},
    {'Bypassed' => 7000}
  ]
end