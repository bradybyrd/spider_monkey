////////////////////////////////////////////////////////////////////////////////
// BMC Software, Inc.
// Confidential and Proprietary
// Copyright (c) BMC Software, Inc. 2001-2012
// All Rights Reserved.
////////////////////////////////////////////////////////////////////////////////

$(function() {
  var column_ids = Array();
  var i = 0;
  column_ids[i] = $('#column_destroy_ids');
  
    $('body').on('submit', 'form#pick_columns', function(e) {
        e.preventDefault();
        $.facebox.close();
        StreamStep.reloadPage();
    });

    $('#available_columns ul li').livequery(function(){
        $(this).draggable({
            helper: 'clone'
        });
    });
    $('#current_columns li').livequery(function(){
        $(this).droppable({
            accept: 'li.available_column',
            hoverClass: 'drop_before',
            drop: function(event, ui) {
                $(this).before(ui.draggable);
                var draggable = ui.draggable;
                $('form#create_columns').ajaxSubmit({
                    data: {
                        'column[activity_attribute_column]': draggable.attr('data-activity-attribute-column') || '',
                        'column[insertion_point]': draggable.prevAll('li').length
                    },
                    beforeSend: function() {
                        $('#current_columns').sortable('disable');
                        $('form#pick_columns').find('input[type=submit]').attr('disabled', 'disabled');
                    },
                    success: function(data, textStatus) {
                        $("#current_columns").html(data).sortable("refresh").sortable('enable');
                        $('form#pick_columns').find('input[type=submit]').removeAttr('disabled');
                    }
                });
            }
        });
    });
  $('#current_columns').livequery(function(){
   $(this).sortable({
    items: ':not(.no_drag)',
    stop: function(event, ui) {
      var item = ui.item;
      $('form#update_columns').ajaxSubmit({
        data: { 
          'column_id': item.attr('data-column-id'),
          'column[insertion_point]': item.prevAll('li').length
        },
        beforeSend: function() {
          $('form#pick_columns').find('input[type=submit]').attr('disabled', 'disabled');
        },
        success: function() {
          $('form#pick_columns').find('input[type=submit]').removeAttr('disabled');
        }
      });
    }
   });
  });
  $('body').on('click', '#current_columns a.remove', function() {
    var item = $(this).parent('li');
    /* adding a variable for append object on available_column*/
    var available = $("div#available_columns span ul");
    var dups = item.siblings('.dup[rel='+item.attr('rel')+']');
    if (dups.length < 2) {
      dups.removeClass('dup');
    }
    item.remove();
    available.append("<li class='available_column ui-draggable' data-activity-attribute-column='"+ item.attr('rel') +"'>" + item.attr('rel') +"</li>");
    
    if(i == 0) {
      column_ids[i] = item.attr('data-column-id')}
    else {
      column_ids[i] =  item.attr('data-column-id')}i++;
    $('#column_destroy_ids').attr('value', column_ids);
   
  });

  $('body').on('click', 'th.filterable', function() {
    box = $(this).find('.filter_box');
    closeFilters();
    box.show();
    $(this).addClass('open');
  });

  $('body').on('click', 'th.filterable .clear_filters', function(e) {
    var heading = $(this).parents('th:first');
    if (heading.hasClass('has_selections')) {
      e.stopPropagation();
      heading.find('p').removeClass('selected');
      selectedFilter = $('th.filterable .filter_box').find('p.last-click').attr('data-filter-value');
      $('form.activity_filters').find('input[type=hidden]').each(function() {
        if ($(this).attr('value') == selectedFilter){
          $(this).remove(); 
        }
      });
      toggleClearLink(heading.parents('tr:first'));
      e.preventDefault();
      $('form.activity_filters').submit();
    }
  });

  function closeFilters() {
    var openFilter = $('th.filterable.open');
    openFilter.find('.filter_box').hide();
    openFilter.removeClass('open');
  }

  $('*').click(function(e) {
    if (!$(e.target).is('th.filterable, th.filterable *') && $('th.filterable.open').length) {
      closeFilters();
      e.stopPropagation();
    }
  });

  function toggleClearLink(row) {
    var clear_link = row.find('.submit a.clear_filters');
    var filters_with_selections = row.find('th.filterable:has(p.selected)');

    filters_with_selections.addClass('has_selections');
    row.find('th.filterable:not(:has(p.selected))').removeClass('has_selections');

    if (filters_with_selections.length) {
      $('#submit_filter').addClass('active');
      clear_link.show();
    }
    else {
      $('#submit_filter').removeClass('active');
      clear_link.hide();
    }
  }

  $('.filter_box p:not(.no_filter)').livequery(function(){
    $(this).clickNoKey(function() {
      selectFilter($(this));
      toggleClearLink($(this).parents('tr:first'));
      return false;
    });
  });
  $('.filter_box p').livequery(function(){
    $(this).metaKeyClick(function() {
      $(this).toggleClass('selected');
      $(this).addClass('last-click');
      $(this).siblings().removeClass('last-click');
      toggleClearLink($(this).parents('tr:first'));

      return false;
    });
  });
  function selectFilter(elem) {
    elem.siblings().removeClass('selected last-click')
    elem.addClass('selected last-click');
  }
  
  function clearTextSelectionAround(elem) {
    elem.parent().children().each(function() {elem.parent().append($(this))});
  }

  function selectFilterGroup(elem, other, towardsOther) {
    var towardsElem = towardsOther == 'prev' ? 'next' : 'prev'
    other[towardsElem + 'All']().intersect(elem[towardsOther + 'All']().andSelf()).addClass('selected');
    elem[towardsElem + 'All']().removeClass('selected');
    other[towardsOther + 'All']().removeClass('selected');
  }

  function shiftClickActions(elem) {
    clearTextSelectionAround(elem);

    var prev = elem.prevAll('.last-click:first');
    var next = elem.nextAll('.last-click:first');

    if (prev.length) selectFilterGroup(elem, prev, 'prev');
    else if (next.length) selectFilterGroup(elem, next, 'next');
    else selectFilter(elem);
  }

  $('.filter_box p').livequery(function(){
   $(this).shiftClick(function() {
    shiftClickActions($(this));
    toggleClearLink($(this).parents('tr:first'));
    return false;
   });
  });
  
  $('body').on('click', 'form.activity_filters a.clear_filters', function() {
    var row = $(this).parents('tr:first');
    row.find('.filter_box p').removeClass('selected');
    toggleClearLink(row);
    $(this).parents('form:first').submit();
    return false;
  });

  $('form.activity_filters').submit(function() {
    var form = $(this);
    form.parents('tr:first').find('.filter_box p.selected').each(function() {
      var field = $('<input type="hidden" />');
      field.val($(this).attr('data-filter-value'));
      field.attr('name', 'filters[' + $(this).attr('data-column-id') + '][]');
      form.append(field);
    });

    form.ajaxSubmit({dataType: 'script', complete: function(){
      $('#submit_filter').removeClass('active');
    }});

    return false;
  });
});

$.fn.intersect = function(other) {
  return $(this.get().intersect($(other).get()));
}

$.fn.shiftClick = function(fn) {
  return this.click(function(e) {
    if (e.shiftKey) return fn.apply(this, arguments);
  });
}

$.fn.metaKeyClick = function(fn) {
  return this.click(function(e) {
    if (e.metaKey && !e.shiftKey) return fn.apply(this, arguments);
  });
}

$.fn.clickNoKey = function(fn) {
  return this.click(function(e) {
    if (!(e.shiftKey || e.metaKey)) return fn.apply(this, arguments);
  });
}
