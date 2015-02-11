def execute(script_params, parent_id, offset, max_records)
  [ {'Select' => ''},
    {'Draft' => 10},
    {'Assigned' => 20},
    {'Pending' => 30},
    {'In Progress' => 40},
    {'Completed' => 50},
    {'Canceled' => 70},    
    {'Closed' => 80}
  ]
end