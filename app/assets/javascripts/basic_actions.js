////////////////////////////////////////////////////////////////////////////////
// BMC Software, Inc.
// Confidential and Proprietary
// Copyright (c) BMC Software, Inc. 2001-2012
// All Rights Reserved.
////////////////////////////////////////////////////////////////////////////////

$(function() {
    $('.initialFocus:first').livequery(function(){
        $(this).focus();
    });
    $('#flash_success').livequery(function(){
        $(this).hideAfterTimeout(15);
    });
    $('#flash_notice').livequery(function(){
        $(this).hideAfterTimeout(15);
    });
    $('#flash_warning').livequery(function(){
        $(this).hideAfterTimeout(15);
    });
    $('tr.show_model').livequery(function(){
        $(this).click(showModel);
    });
    $('tr.show_model a').livequery(function(){
        $(this).click(performDefaultClick);
    });
    $('.toggle').livequery(function(){
        $(this).click(toggleElements);
    });
    $('#login_box').livequery(function(){
        $(this).submit(trimLogin);
    });


    //search bar default text
    searchBarDefaultText();
    //the little edges at the left of first tab and at the right of last tab
    serrateTabBoundaries() ;

    // adjusts width of the primary navigation container so that tabs will scroll if necessary
    //    fixPrimaryNav() ;


    function toggleElements() {
        $(this).openToggle() || $(this).closeToggle();
        return false;
    }
    StreamStep.toggleElements = toggleElements;

    $(getCookieList('open-toggles')).each(function(id) {
        $('#'+this).openToggle();
    });

    function showModel() {
        window.location = $(this).attr('data-show-path');
    }

    function performDefaultClick(e) {
        e.stopPropagation();
    }

});

$.fn.closeToggle = function() {
    var toggle = $(this);
    if (toggle.data('toggle-open')) {
        $(toggle.attr('rel')).hide();
        toggle.addClass('closed').removeClass('open');
        toggle.data('toggle-open', false);
    
        if (toggle.hasClass('preserve'))
            removeFromCookieList('open-toggles', toggle.attr('id'));

        return true;
    } else return false;
}

$.fn.openToggle = function() {
    if (this.length == 0) return;
    var toggle = $(this);
    if (!toggle.data('toggle-open')) {
        $(toggle.attr('rel')).show();
        toggle.addClass('open').removeClass('closed');
        toggle.data('toggle-open', true);

        if (toggle.hasClass('preserve'))
            appendToCookieList('open-toggles', toggle.attr('id'));

        return true;
    } else return false;
}

function appendToCookieList(name, id) {
    if (id == undefined) return;
    if (id.toString() == '') return;
    var values = getCookieList(name);
    if(!Array.indexOf){
        Array.prototype.indexOf = function(obj){
            for(var i=0; i<this.length; i++){
                if(this[i]==obj){
                    return i;
                }
            }
            return -1;
        }
    }
    if (values.indexOf(id) == -1) {
        values.push(id);
        $.cookie(name, values.join(','));
    }
    return values;
}

function removeFromCookieList(name, id) {
    if (id == undefined) return;
    var values = ($.cookie(name) || '').split(',');
    values.remove(id);
    $.cookie(name, values.join(','));
    return values;
}

function getCookieList(name) {
    var val = $.cookie(name);
    if (val) return val.split(',');
    else return [];
}

Array.prototype.remove = function(el) {
    var idx = this.indexOf(el);
    if (idx < 0) return;
    return this.splice(idx, 1)[0];
}

$.fn.hideAfterTimeout = function(seconds) {
    var flash_div = $(this);
    setTimeout(function() {
        flash_div.fadeOut();
    }, seconds * 1000);
}

StreamStep.reloadPage = function() {
    window.location.href = window.location.href;
    window.location.reload();
}

$.fn.spin = function(append) {
  if (append)
    $(this).append('<img src="' + url_prefix + '/assets/spinner.gif" class = "spinner_request" />')
  else
    $(this).after('<img src="' + url_prefix + '/assets/spinner.gif" class = "spinner_request" />')
}

$.fn.stopSpin = function(append) {
	// CHKME,Manish,2012-01-09,See if its =spinner.gif instead.
    if (append)
        $(this).find('img[src$.spinner.gif]').remove();
    else
        $(this).next('img[src$.spinner.gif]').remove();
}

function truncate(text, length, truncation) {
    length = length || 30;
    truncation = truncation === undefined ? '...' : truncation;
    return text.length > length ?
    text.slice(0, length - truncation.length) + truncation : text;
}

function serrateTabBoundaries() {
    //note the hidden header tag within the primaryNav
    $('#primaryNav ul:nth-child(3)').find('li:first-child').addClass('last');
    $('#primaryNav ul:nth-child(3)').find('li:last-child').addClass('first');
    $('#primaryNav ul:nth-child(2)').find('li:last-child').addClass('last');
    $('#primaryNav ul:nth-child(2)').find('li:first-child').addClass('first');
    $('.drop_down ul li').removeClass();
}
function searchBarDefaultText() {
    var el = $('#q');
    if (el.val() == "") {
        el.val("Search Requests")
        el.css({'color':'#ccc','text-align':'center'})        
    }
    el
    .focus(function(){
        $(this).css({'color':'black','text-align':'left'});
        if ($(this).val() == "Search Requests") {
            $(this).val("");
        }
    })
    .blur(function(){
        $(this).css({'color':'#ccc','text-align':'left'});
        if ($(this).val() == "") {
            $(this).val("Search Requests");
            $(this).css({'color':'#ccc','text-align':'center'});
        }
    });
}

function fixPrimaryNav(){
    
    primaryNavTabs = $('#primaryNav ul');

    primaryNavTabs.each(
        function()
        {
            var primaryNavWidth=0;
            $(this).children().each(function(){
                primaryNavWidth+=this.offsetWidth
            })
            primaryNavWidth+=5;
            $(this).css('width',primaryNavWidth + 'px');
        }
        );
    adjustPrimaryNav();
    $(window).resize(function(){
        adjustPrimaryNav();
    });
    
}

function adjustPrimaryNav() {
    var primaryNav = $('primaryNav'), topBar = $('topBar'),
    wrapper = $('#Wrapper');
    if (primaryNav.scrollWidth > primaryNav.offsetWidth)
    {
        if (topBar.hasClass('withOverflow')) return;

        $('topBar, primaryNav').addClass('withOverflow');

        if (wrapper)
            wrapper.addClass('withOverflow');
    }
    else
    {
        if (!topBar.hasClass('withOverflow'))
            return;

        $('topBar, primaryNav').removeClass('withOverflow');

        if (wrapper)
            wrapper.removeClass('withOverflow');
    }
}

function trimLogin(){
    var login = $('#user_login');
    if($('#user_login').val() != undefined) {
        login.val(login.val().replace(/^\s+|\s+$/g,''));
    }
}

function checkStompPath(){
    path = $("#stomp_js_path").val();
    $.ajax( { url: path, type: "GET" }).fail(function( ) {
        $.facebox("<div style='text-align:center'>" +
                  "<h3>Auto-refresh for requests is disabled.</h3>" +
                  "<p>Enable RLM auto-refresh by accepting the following link " +
                  "<a href="+path+" target='_blank' onclick='$.facebox.close();'>SSL certificate</a> or</p>" +
                  "<p>by checking the configuration</p>" +
                  "</div>"
        )
    });
}
