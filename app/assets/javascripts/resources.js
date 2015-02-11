////////////////////////////////////////////////////////////////////////////////
// BMC Software, Inc.
// Confidential and Proprietary
// Copyright (c) BMC Software, Inc. 2001-2012
// All Rights Reserved.
////////////////////////////////////////////////////////////////////////////////

$(function() {
	
	if ($('#viewCurrentStepsResources').length > 0){
  	$('#viewCurrentStepsResources').bind('click', function(event) {
    	event.preventDefault();
        //CHCKME,18/01/2012,Sourabh:Is this redundant?Dashboard already has some js which is doing the same
			$('.pageSection').find('li').removeClass('current');
			$(this).parents('li:first').addClass("current");
			$('.left .content').load($('#viewCurrentStepsResources').attr('href'), function() {
	  		$('.all_steps').hide();
		  	$('.requestFilters').hide();
	  	});
  	});		
	}	
  $('body').on('click', 'tr#add_workstream', addWorkstream);
  $('body').on('click', 'a.remove_workstream', removeWorkstream);
  $('form#update_workstreams').livequery(function(){
      $(this).preventLeavingWhenChanged();
  });

  $('body').on('click', '#edit_resource_allocations td a.sync', syncAllocations);

  function addWorkstream() {
    $(this).hide();
    $('tr#new_workstream_row').show().find('select').removeAttr('disabled');
    getTableSection($(this), 'thead').show();
    
    return false;
  }
  
  function removeWorkstream() {
    if (getTableSection($(this), 'tbody tr:visible').length == 1) getTableSection($(this), 'thead').hide();
    $(this).parents('tr:first').hide();
    $('tr#add_workstream').show();
    $(this).hide(); 

    return false;
  }

  function getTableSection(element, selector) {
    return element.parents('table:first').find(selector);
  }

  function syncAllocations() {
    var clickedCellIndex;
    var row = $(this).parents('tr:first');
    var cells = row.find('td');

    cells.each(function(index, cell) {
      if($(cell).find('a.sync').length) {
        clickedCellIndex = index;
      }
    });

    var selectValue = $(cells[clickedCellIndex]).find('select').val();

    cells.each(function(index, cell) {
      if(index >= clickedCellIndex) {
        $(cell).find('select').val(selectValue);
      }
    });

    return false;
  }
	
});
