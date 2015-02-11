////////////////////////////////////////////////////////////////////////////////
// BMC Software, Inc.
// Confidential and Proprietary
// Copyright (c) BMC Software, Inc. 2001-2012
// All Rights Reserved.
////////////////////////////////////////////////////////////////////////////////

$(function() {
	$('#list_list_item_ids').val('');
});

find_value_strategy = {
    archive: function(list_item_ids){
        $('#list_list_item_ids').find(':selected').each(function(i, selected){
            $("#list_item_list_item_ids").append($(selected));
            list_item_ids[i] = $(selected).val();
        });
    },
    unarchive: function(list_item_ids){
        $('#list_item_list_item_ids').find(':selected').each(function(i, selected){
            var archivedItemText = $(selected).text().trim();

            if(!list.alreadyAdded(archivedItemText)){
                $("#list_list_item_ids").append($(selected));
            }
            else{
                list_item_ids[i] = $(selected).val();
                return false;
            }

            list_item_ids[i] = $(selected).val();
        });
    },
    newItem: function(){
        var canAdd          = true;
        var newItemText     = $.trim(listItem.valueItem.val());
        var newItemKeyText  = listItem.valueItemKey.length > 0 ? $.trim(listItem.valueItemKey.val()) : null;
        var keyOrValue      = list.type() == list.hash ? newItemKeyText : newItemText;

        // validate if fields are not empty
        if(listItem.valueIsEmpty(newItemKeyText)){
            canAdd = false;
            alert('Please enter the Title of List item to add');
        }
        else if(listItem.valueIsEmpty(newItemText)){
            canAdd = false;
            alert('Please enter the Value of List item to add.');
        }
        // check for duplications
        else if(list.alreadyAdded(keyOrValue)){
            canAdd = false;
        }

        // add new item
        if(canAdd) { find_value_strategy.newItemStrategy.add(newItemText); }
    },

    newItemStrategy: {
        add: function(newItem){
            if(list.type() == list.numeric){
                find_value_strategy.newItemStrategy.numeric(newItem);
            }
            else if(list.type() == list.text){
                find_value_strategy.newItemStrategy.text(newItem);
            }
            else if(list.type() == list.hash){
                find_value_strategy.newItemStrategy.hash();
            }
        },

        numeric: function(newItem){
            // check if numeric list item contains only integers
            if(!listItem.isInteger(newItem)){
                alert("Please enter integers only");
                return false;
            }

            list.addItem(newItem);
        },

        text: function(newItem){
            list.addItem(newItem);
        },

        hash: function(){
            var valueItemKey    = $('#value_item_key');
            var valueItem       = $('#value_item');
            var newItemKey      = jQuery.trim(valueItemKey.val());
            var newItemValue    = jQuery.trim(valueItem.val());
            var newItemOption   = newItemKey+':' +newItemValue;
            var newItemIdString = '"00_'+newItemOption+'"';

            // check if key does not contain forbidden chars
            if(!listItem.isKeyLike(newItemKey)) {
                alert("Key cannot contain `:` symbol");
                return false;
            }

            // check if value item is numeric
            if(!listItem.isInteger(newItemValue)) {
                alert("Value can be only an integer");
                return false;
            }

            $("#list_list_item_ids").append('<option value='+newItemIdString+'>'+newItemOption+'</option>');

            // clear key, value after they have been added
            valueItemKey.val("");
            valueItem.val("");
        }
    }
}

list = {
    numeric: 'numeric',
    text: 'text',
    hash: 'hash',

    type: function(){
        if($('#isText').val() == 'false' && $('#isHash').val() == 'false'){
            return list.numeric;
        }
        else if($('#isText').val() == 'true'){
            return list.text;
        }
        else if($('#isHash').val() == 'true'){
            return list.hash;
        }
    },

    alreadyAdded: function(newItemText){
        var added = false;

        $('#list_list_item_ids').find('option').each ( function() {
            if(list.type() == list.numeric || list.type() == list.text ) {
                if ( $(this).text() == newItemText){
                    alert("List item \""+newItemText+"\" already added.");
                    added = true;
                }
            }
            else if(list.type() == list.hash){
                var newItemKeyText      = newItemText.split(':')[0];
                var existingItemKeyText = $(this).text().split(':')[0];

                if (existingItemKeyText  == newItemKeyText){
                    alert("List item \""+newItemKeyText+"\" already added.");
                    added = true;
                }
            }
        });
        
        return added;
    },

    addItem: function(newItem){
        $("#list_list_item_ids").append('<option value="00_'+newItem+'">'+newItem+'</option>');
        $('#value_item').val("");
    }
}

listItem = {
    valueItem: $('#value_item'),
    valueItemKey: $('#value_item_key'),
    fieldSelectors: ['#value_item', '#value_item_key'],

    valueIsEmpty: function(object){
        console.log(0);
        return object == "" && object !== null;
    },
    isInteger: function(newItem){
        var regExp  = /^[+-]?[0-9]*$/;
        return regExp.test(newItem);
    },
    isKeyLike: function(key){
        var regExp  = /:/;
        return !regExp.test(key);
    },

    fields: function(){
        var result = [];
        $.each(listItem.fieldSelectors, function(i, value){
            result.push($(value));
        });

        return result;
    }
}



function find_value(status){
    var list_item_ids = [];

    if (status == 'Archive') {
        find_value_strategy.archive(list_item_ids);
    }
    else if (status == 'Unarchive') {
        find_value_strategy.unarchive(list_item_ids);
    }
    else if (status == 'NewItem') {
        find_value_strategy.newItem();
    }

    if (list_item_ids == '' && (status == 'Archive' || status == 'Unarchive') ){
	    alert("Please select List item to set " + status);
    } else {
        $("#inactive_list_items").val($('#list_list_item_ids > option').map(function() { return this.value; }).get() );
        $("#active_list_items").val($('#list_item_list_item_ids > option').map(function() { return this.value; }).get() );
    }

    return false;
}

$('#list_is_text').change(function() {
    var isHashCheckbox = $('#list_is_hash');
    var isHashCheckboxDiv = isHashCheckbox.parent();
    if(this.checked) {
        isHashCheckbox.attr('checked', false);
        isHashCheckboxDiv.hide();
    }
    else {
        isHashCheckboxDiv.show();
    }
});