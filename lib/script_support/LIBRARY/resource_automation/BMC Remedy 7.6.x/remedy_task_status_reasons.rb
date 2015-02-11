###
# status:
#   name: Status
#   type: in-external-single-select
#   external_resource: remedy_task_statuses
#   required: yes
###
def execute(script_params, parent_id, offset, max_records)
  if script_params['status'] == '1000'
    [ {'Select' => ''},
      {'Staging in Progress' => 5000},
      {'Staging Complete' => 6000}
    ]
  elsif script_params['status'] == '3000'
    [ {'Select' => ''},
      {'Assignment' => 4000},
      {'Error' => 9000}
    ]
  elsif script_params['status'] == '5000'
    [ {'Select' => ''},
      {'Acknowledgment' => 7000},
      {'Completion' => 8000}
    ]
  elsif script_params['status'] == '6000'
    [ {'Select' => ''},
      {'Success' => 1000},
      {'Failed' => 2000},
      {'Canceled' => 3000}
    ]
  else
    [ {'Select' => ''}]
  end
end