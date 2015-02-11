function MultiPickerSelect(select, values){
    var self = this;

    this.sortOptionsFn = function(option1, option2){
        return option1.text > option2.text ? 1 : (option1.text == option2.text ? 0 : -1);
    };

    this.select = select;
    this.values = values || $("option", this.select).map(function(){
        return {value: this.value, text: this.text, disabled: this.disabled};
    }).toArray().sort(self.sortOptionsFn);

    this.applyValues = function(values){
        values = values || self.values;
        var innerHTML_ = '';
        for(var i=0; i < values.length; i++) {
            innerHTML_ += '<option ';
            if (values[i]['disabled'] == true){
                innerHTML_ += 'disabled="disabled" '
            }
            innerHTML_ += 'value="' + values[i]['value'] +'">' + values[i]['text'] + '</option>';
        }
        $(this.select).html(innerHTML_);
    };
    // sort all options
    this.applyValues(self.values);

    this.getSelect = function(){
        return self.select;
    };

    this.getAllOptions = function(){
        return Array.prototype.slice.call(self.select.options);
    };

    this.getAllAvailableOptions = function(){
        var options = [],
            options_all = self.select.options;
        $.each(options_all, function(_, item){
            if (item.disabled == false) { options.push(item); }
        });
        return options
    };

    this.getSelectedOptions = function(){
        var select = self.getSelect();
        var options_to_select = [];
        for(var i=0; i < select.options.length; i++){
            if(select.options[i].selected == true) options_to_select.push(select.options[i]);
        }
        return options_to_select;
    };

    this.addOptions = function(options){
        if (!options.length > 0) return false;

        var select = self.getSelect();
        for(var i=0;i < options.length; i++){
            select.add(options[i]);
        }
        return true;
    };
    this.selectOptions =function(ids){
        var options = self.getAllOptions();
        var result = 0;
        for(var i = 0; i < options.length; i++){
            if(ids.indexOf(options[i].value) >= 0){
                options[i].selected = true;
                result++;
            }
        }
    };

    this.removeAllOptions = function(){
        var selectParenNode = self.select.parentNode;
        var toRemove = self.select;
        self.select = self.select.cloneNode(false);
        selectParenNode.replaceChild(self.select, toRemove);
        return self.select;
    };

    this.storePlainOptionsData = function(options){
        $('.' + self.select.className + '').parent().data('options', options);
    };

    this.resetOptions = function(options){
        self.removeAllOptions();
        var new_values = [];
        $.each(options, function(){
            var include = true;
            var value =  this.value.toString();
            $.each(self.values, function(){
                if(this.value.toString() == value) include = false;
            });
            if(include) new_values.push({value: this.value, text: this.text});
        });
        self.values = $.merge(self.values, new_values).sort(self.sortOptionsFn);
        self.storePlainOptionsData(options);
        return self.addOptions(options);
    };
    // move options from self select to another, call resetOptions that sort items
    this.moveTo = function(select, all){
        var options_to_add = all == true ? self.getAllAvailableOptions() : self.getSelectedOptions();
        var all_options = $.merge(select.getAllOptions(), options_to_add).sort(self.sortOptionsFn);
        var new_values = [];
        $.each(self.values, function(){
            var include = true;
            var value = this.value.toString();
            $.each(options_to_add, function(){
                if(value == this.value.toString()) include = false;
            });
            if(include) new_values.push(this);
        });

        self.values = new_values;
        self.storePlainOptionsData(new_values);
        return select.resetOptions(all_options);
    };

    this.addFilter = function(input) {
        input.focus(function() {
            $(this).addClass('ui-state-active');
        })
            .blur(function() {
                $(this).removeClass('ui-state-active');
            })
            .keypress(function(e) {
                if (e.keyCode == 13)
                    return false;
            })
            .keyup(function() {
                self.filter.apply(input);
            });
    };

    this.filter = function() {
        self.applyValues();
        var input = this,
            options = self.getAllOptions(),
            cache = [],
            term = $.trim(input.val().toLowerCase()),
            scores = [];

        $.each(options, function(){
            cache.push(this);
        });
        if (!term) {
            self.applyValues();
        } else {
            self.removeAllOptions();
            $.each(cache, function() {
                if (this.text.toLowerCase().indexOf(term)>-1) { scores.push(this) }
            });

            self.addOptions(scores);
        }
    };

    return {
        getSelect: self.getSelect,
        getAllOptions: self.getAllOptions,
        addOptions: self.addOptions,
        resetOptions: self.resetOptions,
        removeAllOptions: self.removeAllOptions,
        addFilter: self.addFilter,
        moveTo: self.moveTo,
        selectOptions: self.selectOptions,
        getSelectedOptions: self.getSelectedOptions
    };
}

MultiPickerSelect.processSelect = function(callback, options_){
    var multiple_picker_selected_el = $("select.multiple_picker_selected"),
        message = null,
        selectedOptions = multiple_picker_selected_el.parent().data("options");
    if(typeof(window[callback]) != "function"){
        message = "'Couldn\'t run callback as there are no function with such name: " + callback;
    }
    try{
        console.log(selectedOptions);
        window[callback](selectedOptions, options_);
    }catch(e){
        message = 'Couldn\'t run "' + callback + '"function. Some Error happens: ' + e;
    }
    if(message != null){
        if(console && console.log){
            console.log(message);
        } else {
            alert(message);
        }
    } else {
        jQuery(document).trigger('close.facebox');
    }
};

MultiPickerSelect.getAlreadySelected = function(){
    var id_prefix    = "multiple_picker_container_for_",
        item_class   = $("div[id^=" + id_prefix + "]")[0].id.replace(id_prefix, ""),
        link_id      = "show_picker_link_for_" + item_class.toLowerCase() + "_id",
        container_id = "show_picker_container_for_" + item_class.toLowerCase() + "_id";

    var link      = $("a#" + link_id)[0],
        result    = [],
        container = $("span#" + container_id);

    if(container != undefined && container && container.length > 0){
        var inputs = container.find('INPUT[type="hidden"]');
        for(var i = 0; i < inputs.length; i++){
            result.push(inputs[i].value);
        }
    }
    return result;
};

var multiple_picker_to_select_el = $("select.multiple_picker_to_select")[0],
    multiple_picker_selected_el = $("select.multiple_picker_selected")[0],
    multiple_picker_to_select = new MultiPickerSelect(multiple_picker_to_select_el),
    multiple_picker_selected = new MultiPickerSelect(multiple_picker_selected_el);
// verify If some options were already selected but not sent to the server
multiple_picker_to_select.selectOptions(MultiPickerSelect.getAlreadySelected());

if(multiple_picker_to_select.getSelectedOptions().length) {
    multiple_picker_selected.moveTo(multiple_picker_to_select, true);
}
multiple_picker_to_select.moveTo(multiple_picker_selected);

multiple_picker_to_select.addFilter($('div[id^="multiple_picker_container"] input.search.to-select'));
multiple_picker_selected.addFilter($('div[id^="multiple_picker_container"] input.search.selected'));

$('body').on('click', ".multiple-picker-controls > .select", function() {
    multiple_picker_to_select.moveTo(multiple_picker_selected); return false;
})
$('body').on('click', ".multiple-picker-controls > .deselect", function() {
    multiple_picker_selected.moveTo(multiple_picker_to_select); return false;
})
$('body').on('click', ".multiple-picker-controls > .select-all", function() {
    multiple_picker_to_select.moveTo(multiple_picker_selected, true); return false;
})
$('body').on('click', ".multiple-picker-controls > .deselect-all", function() {
    multiple_picker_selected.moveTo(multiple_picker_to_select, true); return false;
})

/**
 options = {
      item_class: item_class.camelize,
      item_class_plural: item_class.camelize.pluralize,
      object_class: object_class.underscore.pluralize
    }
 **/

processMultiplePickerObject = function(select_options, options){
    var container_str = '';
    var selected_items_text = [];

    for(var i=0; i < select_options.length; i++){
        container_str += "<input type='hidden' name='" + options.object_class + "[" + options.item_class.toLowerCase() + "_ids][]' value='" + select_options[i].value + "'>";
        selected_items_text.push(select_options[i].innerHTML);
    }
    var link_str = "Add " + options.item_class_plural;
    if(select_options.length) {
        link_str = "Change " + options.item_class_plural + " (selected " + select_options.length + ")";
    }

    var link_id = "show_picker_link_for_" + options.item_class.toLowerCase() + "_id",
        container_id = "show_picker_container_for_" + options.item_class.toLowerCase() + "_id";

    var link = $("a#" + link_id)[0];
    link.innerHTML =  link_str;
    link.setAttribute('title', selected_items_text.join(', '));

    var container = $("span#" + container_id)[0];
    if (container == undefined || !container){
        container  = document.createElement("SPAN");
        container.id = container_id;
        link.parentNode.insertBefore(container, link.nextSibling);
    }
    container.innerHTML = container_str;

    if ( options.auto_submit == 'true' ){
        var frm = $( "form");
        if ( options.form_name ){
            frm = $( "#" + options.form_name );
            // Add the hidden field to this form
            frm.append( container_str )
        }
        $('<input>').attr({
            type: 'hidden',
            name: 'auto_submit',
            value: 'y'
        }).appendTo( frm );
        $( frm ).submit();
    }

    $('#deployment_window_series_environment_ids').val(MultiPickerSelect.getAlreadySelected());
    $('#group_role_ids').val(MultiPickerSelect.getAlreadySelected());
    $('#user_group_ids').val(MultiPickerSelect.getAlreadySelected());
};
