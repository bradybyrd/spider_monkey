def execute(script_params, parent_id, offset, max_records)
  [ {'Select' => ''},
    {'Draft' => 0},
    {'Request For Authorization' => 1},
    {'Request For Change' => 2},
    {'Planning In Progress' => 3},
    {'Scheduled For Review' => 4},
    {'Scheduled For Approval' => 5},
    {'Scheduled' => 6},
    {'Implementation In Progress' => 7},
    {'Pending' => 8},
    {'Rejected' => 9},
    {'Completed' => 10},
    {'Closed' => 11},
    {'Cancelled' => 12}
  ]
end