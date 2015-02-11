def execute(script_params, parent_id, offset, max_records)
  [ {'Select' => ''},
    {'Emergency' => 1000},
    {'Expedited' => 2000},
    {'Latent' => 3000},
    {'Normal' => 4000},
    {'No Impact' => 5000},
    {'Standard' => 6000}
  ]
end