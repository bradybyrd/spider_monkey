$(function() {
    $('#request_app_ids').on('change', function() { clearMultiSelectedEnvironments(this) });
});

function InlineMultiPickerSelect(itemName, clickedLink){
    var self = this;

    this.itemName = itemName;
    this.itemNameLowerCase = itemName.toLowerCase();
    this.clickedLink = clickedLink;
    this.urlGetItems = '/requests/multi_environments';

    this.SetHtmlElementsValues = function(){
        this.parentForm = $(self.clickedLink).closest('form');
        this.linkDiv = self.parentForm.find('#request_link_for_multi_select');
        this.label = self.parentForm.find('label:contains('+ self.itemName +':)');
        this.link = $('<a>', {href: '#', onclick: 'addRemoveItems(this, "'+ this.itemName +'"); return false;', text: 'Add '+ self.itemName +'s'});
        this.multiSelectDiv = self.parentForm.find('#request_multi_select');

        var popup = self.parentForm.parents('#facebox');
        if (popup.length) {
            this.selectorPrefix = 'popup_'
        }else{
            this.selectorPrefix = ''
        }
    };

    this.ClearSelectedItems = function() {
        self.multiSelectDiv.hide();
        self.linkDiv.html(self.link);
        self.linkDiv.show();
    };

    this.EnableMultiSelect = function(){
        self.SetHtmlElementsValues();
        self.label.text(self.itemName +'s:');
    };

    self.EnableMultiSelect();

    this.DisplayMultiSelect = function(){
        var appId = self.parentForm.find('#request_app_ids').val(),
            requestTemplateId = self.parentForm.find('#request_template_id').val(),
            data = { app_id: appId, request_template_id: requestTemplateId };
        if (appId != '' || requestTemplateId != undefined ) {
            self.GetItemsFromServer(data);
        }
    };

    this.GetItemsFromServer = function(data){
        $.ajax({
            url: url_prefix + self.urlGetItems,
            type: 'GET',
            data: data,
            dataType: 'html',
            success: function (data) {
                self.linkDiv.hide();
                self.multiSelectDiv.show();
                self.multiSelectDiv.html(data);
            }
        });
    };

    this.SelectItems = function(changed) {
        self.selectedIds = [];
        self.selectedNames = [];
        var selectedItems = $('.multiple_picker_selected option');

        self.linkDiv.show();
        $.each(selectedItems, function(index, item){
            self.selectedIds.push($(item).val());
            self.selectedNames.push($(item).text());
        });
        if (changed == true) { self.CreateHiddenFields(); }

        if (self.itemNameLowerCase == 'environment'){
            self.ShowOrHideDwSelect(self.parentForm, self.selectedIds);
        }
        self.multiSelectDiv.html('');
    };

    this.CreateHiddenFields = function(){
        var link,
            span = $('<span>', {id: 'show_picker_container_for_'+ self.itemNameLowerCase +'_id'}),
            selectedItemsInput = $('<input>', { id: 'request_'+ self.itemNameLowerCase +'_ids',
                name: 'request['+ self.itemNameLowerCase +'_ids]',
                value: self.selectedIds, type:'hidden' });

        if (self.selectedNames.length) {
            link = $('<a>', {href: '#', onclick: 'addRemoveItems(this, "'+ this.itemName +'"); return false;', text: self.selectedNames.toString() + '(Edit)'}); }
        else { link = this.link}

        $.each(self.selectedIds, function(index, id){
            span.append($('<input>', {name: 'request['+ self.itemNameLowerCase +'_ids][]', value:id, type: 'hidden'}));
        });

        self.linkDiv.html('');
        self.linkDiv.append(link, span, selectedItemsInput);
    };

    this.ShowOrHideDwSelect = function() {
        var policy = 'opened',
            deploymentWindowSelect = self.parentForm.find('#'+self.selectorPrefix+'request_deployment_window_event_id');

        if (self.selectedIds != undefined && self.selectedIds.length == 1){
            policy = $('#deployment_policy_' + self.selectedIds[0]).val();
        }
        deploymentWindowSelect.closest('.field').toggle(policy == 'closed');
        deploymentWindowSelect.closest('form').find('#'+self.selectorPrefix+'request_deployment_window_event_id').select2('val', '');
    };

    return {
        DisplayMultiSelect: self.DisplayMultiSelect,
        SelectItems: self.SelectItems,
        ClearSelectedItems: self.ClearSelectedItems,
        selectedIds: self.selectedIds,
        selectedNames: self.selectedNames
    }
}

function useMultiSelect(clickedLink, itemName) {
    inlineMultiPickerSelect = new InlineMultiPickerSelect(itemName, clickedLink);
    inlineMultiPickerSelect.ClearSelectedItems();
}

function addRemoveItems(clickedLink, itemName){
    inlineMultiPickerSelect = new InlineMultiPickerSelect(itemName, clickedLink);
    inlineMultiPickerSelect.DisplayMultiSelect();
}

function selectItems(changed){
    inlineMultiPickerSelect.SelectItems(changed);
}

function reinitMultiSelect(childElement){
    return new InlineMultiPickerSelect('Environment', childElement);
}

function clearMultiSelectedEnvironments(appsDropdown){
    var label = $(appsDropdown).closest('form').find("label:contains('Environments:')"),
        deploymentWindowSelect = $('#request_deployment_window_event_id');
    if (label.length) {
        if (typeof inlineMultiPickerSelect == 'undefined'){
            inlineMultiPickerSelect = reinitMultiSelect(label);
        }
        inlineMultiPickerSelect.ClearSelectedItems();
    }
    if (deploymentWindowSelect.val().length){
        deploymentWindowSelect.closest('.field').toggle(true);
    }
}

