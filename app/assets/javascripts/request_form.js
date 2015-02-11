////////////////////////////////////////////////////////////////////////////////
// BMC Software, Inc.
// Confidential and Proprietary
// Copyright (c) BMC Software, Inc. 2001-2012
// All Rights Reserved.
////////////////////////////////////////////////////////////////////////////////

//$(function() {
   $('.request_planned_date').live('change', function(){
        var start_date = new Date(($(this)).datepicker("getDate"));
        
        var current_date = new Date($('#current_date').val());
        //alert($(this).disabled);
        //(($(this).getAttribute('disabled') ==null) || ($(this).getAttribute('disabled') ==false)) 
        current_date.setHours(0);
        current_date.setMinutes(0);
        current_date.setSeconds(0);
        if ( (($(this)).val() != "")){
          if( (start_date < current_date) && !( $('#request_planned_at_to_run_start_at').is(':checked'))   ){
            alert('Request planned Start is before current date.');
              //$('.early_due_date_error').html('Request planned Start is before current date.');
              //$('.early_due_date_error.on_form').show();
            }else{
              //$('.early_due_date_error.on_form').hide();
          }
        }
    });
  $(':input[id^=run_start_at_]' ).live('change', function(){
        var start_date = stitchDate($('#run_start_at'));
        var current_date = new Date($('#current_date').val());
        current_date.setHours(0);
        current_date.setMinutes(0);
        current_date.setSeconds(0);
        if ( ($('#run_start_at').find(':input[id$=date]').val() != "")){
          if(start_date < current_date && !($('#run_start_at_to_planned_at_earliest_request').is(':checked')  ) ){
              alert('You have selected Run Start is before current date.');
              //$('.early_due_date_error').html('Run Start is before current date.');
              //$('.early_due_date_error').show();
            }else{
              //$('.early_due_date_error').hide();
          }
        }
    });

  $(':input[id^=request_scheduled_at_], :input[id^=request_target_completion_at_]').live('change', function(){
    var start_date = stitchDate($('#scheduled_at')), end_date = stitchDate($('#target_completion_at'));
    var current_date = new Date($('#current_date').val());
    if(end_date.getFullYear() == 1970){
       end_date = new Date($('#due_date').val());
     }
    current_date.setHours(0);
    current_date.setMinutes(0);
    current_date.setSeconds(0);
    var showerror=new Boolean(false); 
    if ( ($('#scheduled_at').find(':input[id$=date]').val() != "")){      
        if(start_date < current_date ){
          showerror=new Boolean(true); 
            $('.early_due_date_error').html('Planned Start is before current date.');
        }
    }
    if ( ($('#scheduled_at').find(':input[id$=date]').val() != "") && ($('#target_completion_at').find(':input[id$=date]').val() != "") ){
                    if (end_date < start_date) {
                            if(showerror != false ){
                                  $('.early_due_date_error').html('Planned Start is before current date.<br/>Due by is before Planned Start.');
                             }else{
                                  $('.early_due_date_error').html('Due by is before Planned Start.');                       
                            }
                     showerror=new Boolean(true); 
                    }
      }
    if(showerror !=false){
      $('.early_due_date_error.on_form').show();
    }
    else{
      $('.early_due_date_error.on_form').hide();
    }
  });

  $(':input[id^=request_scheduled_at_]').live('change', function(){
    if ($('p#rescheduled_field').hasClass('old_record')) {
      $('p#rescheduled_field').show();
      if ($('#request_rescheduled').attr('checked') != 'false') {
        $('#request_rescheduled').attr('checked', true);
      }
    }
  });
//});

function stitchDate(container) {
  var date     = new Date(container.find(':input[id$=date]').datepicker('getDate')),
      hour     = container.find(':input[id$=hour]').val(),
      minute   = container.find(':input[id$=minute]').val(),
      meridian = container.find(':input[id$=meridian]').val();
  if (meridian == 'PM')
    hour = ((parseInt(hour) + 12) % 24) || '12';

  date.setHours(hour);
  date.setMinutes(minute);

  return date;
    }
