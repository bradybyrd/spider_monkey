////////////////////////////////////////////////////////////////////////////////
// BMC Software, Inc.
// Confidential and Proprietary
// Copyright (c) BMC Software, Inc. 2001-2012
// All Rights Reserved.
////////////////////////////////////////////////////////////////////////////////

jQuery(function() {
	jQuery('#quick_links').find("h2").click(function() {
	  jQuery('#quick_links').find("ul").toggle();
	});
});


function breadcrumbs() {
	var breadCrumbCookie = Get_Cookie("breadCrumbs");
	var href = String(window.location);
	if (breadCrumbCookie){
		var breadCrumbs = uniqArray(breadCrumbCookie.split(','));
	} else {
		var breadCrumbs = new Array();
	}
	if(isEditPage(href)) {
		href = cleanHref(href);
		breadCrumbs.push(cleanString(document.title) + "*" + (href));
		var lim = breadCrumbs.length;
		if(lim > 12){
			breadCrumbs = breadCrumbs.splice(1,lim -1);
		}
		deleteBreadCrumbCookie();
		document.cookie ="breadCrumbs=" + encodeURI(uniqArray(breadCrumbs)) + "; " + " path=/";
	}
	var new_breadcrumb_cookies = Get_Cookie("breadCrumbs");
	if(new_breadcrumb_cookies != null)drawLinks(uniqArray(new_breadcrumb_cookies.split(',').reverse()));
}

function isEditPage(href){
	var sa = href.split('/');
	var lim = sa.length-1;
	var listPages = ['capistrano', 'bladelogic', 'hudson', 'request_templates', 'automation_monitor']
	for(var i = lim;i >= (lim-1);i--) {
	  if  (sa[lim] != 'apply_template'){
	    if((sa[i] == 'edit') || (parseInt(sa[i]) > 1) && i > 2  ){
	      return(true);
		  break;
	    }
	  }
	}
	var foundIt = false;
	for (key in listPages){
		if (href.indexOf(listPages[key])>0){
			foundIt = true;
		}
	}
	return(foundIt);
}

function drawLinks(recentLinks){
	var links = "<div id='quick_links'><h3>Recent Page Links</h3>";
	var sep = "<br>";
	links += "<div style='float:left;'>";
	var lim = recentLinks.length;
	if(lim > 10){lim = 10}
	for (var i = 0; i < lim; i++){
	  //if (i==5){links += "</div><div style='float:right;'>"}
	  var linkData = recentLinks[i].split('*');
	  linkTitle = linkData[0];
	  links += "<a href='" + linkData[1] + "' title='" + linkData[0] +  "'>" + prefixType(linkTitle) + "</a>" + sep;
	}
	links += "</div></div>";
	jQuery(".crumbs").append(links);
}

function padString(txt, iLen){
	if(txt.substr(0,1) == " "){
		txt = txt.substr(1,50);
	}
	var curLen = txt.length;
	var res = "";
	var diff = (curLen - iLen);
	if(diff > 0){
		res = txt.slice(0,(iLen-3)) + "...";
	}else{
		//var sPad = "";
		//for (var i = 1; i<(iLen-curLen); i++){sPad += " ";}
		res = txt //+ sPad;
	}
	return res;
}

function cleanHref(href){
	if (href.indexOf("/requests/") > -1){
		ipos1 = href.indexOf("/edit#");
		ipos2 = href.indexOf("?");
		if(ipos1 > -1){href = href.slice(0,ipos1)}
		if(ipos2 > -1){href = href.slice(0,ipos2)}
	}
	return href;
}

function cleanString(txt){
	var res = "";
	res = txt.replace("Manage", "").replace("Editing","").replace("Application:","App");
	res = res.replace("Property:", "Prop").replace("Activity:", "Act");
	res = res.replace("Edit","").replace("Request","Req");
	res = res.replace(",","-");
	return res;
}

function prefixType(txt){
	var max_len = 35;
	res = padString(txt, max_len);
	if(res.substr(0,3) == "App"){
		res = tagColor("App: ", "indigo_txt") + res.substr(3,max_len);
	}else if(res.substr(0,4) == "Prop"){
		res = tagColor("Prop: ", "green_txt") + res.substr(4,max_len);
	}else if(res.substr(0,4) == "Team"){
		res = tagColor("Team: ", "green_txt") + res.substr(6,max_len);
	}else if(res.substr(0,4) == "User"){
		res = tagColor("User: ", "green_txt") + res.substr(5,max_len);
	}else if(res.substr(0,3) == "Req"){
		res = tagColor("Req: ", "blue_txt") + res.substr(3,max_len);
	}else if(res.substr(0,6) == "Server"){
		res = tagColor("Server: ", "purple_txt") + res.substr(7,max_len);
	}else if(res.substr(0,3) == "Act"){
		res = tagColor("Act: ", "maroon_txt") + res.substr(3,max_len);
	}else if(res.substr(0,4) == "Life"){
		res = tagColor("Life: ", "orange_txt") + res.substr(4,max_len);
	}else if(res.substr(0,4) == "Auto"){
		res = tagColor("Auto: ", "brown_txt") + res.replace("Automation - ","");
	}
	return res;
}

function tagColor(txt, tag_color){
		return "<span class='" + tag_color + "'>" + txt + "</span>";
}

function logOut(){
	deleteBreadCrumbCookie();
	window.location= url_prefix + "/logout";
}

function deleteBreadCrumbCookie(){
	var breadCrumbCookie = Get_Cookie("breadCrumbs");
	var d = new Date();
	document.cookie = "breadCrumbs=" + breadCrumbCookie + ";expires=" + d.toGMTString() + ";" + ";";
}

function Get_Cookie(check_name) {
	// first we'll split this cookie up into name/value pairs
	// note: document.cookie only returns name=value, not the other components
	var a_all_cookies = document.cookie.split( ';' );
	var a_temp_cookie = '';
	var cookie_name = '';
	var cookie_value = '';
	var b_cookie_found = false; // set boolean t/f default f

	for ( i = 0; i < a_all_cookies.length; i++ )
	{
		// now we'll split apart each name=value pair
		a_temp_cookie = a_all_cookies[i].split( '=' );

		// and trim left/right whitespace while we're at it
		cookie_name = a_temp_cookie[0].replace(/^\s+|\s+jQuery/g, '');

		// if the extracted name matches passed check_name
		if ( cookie_name == check_name )
		{
			b_cookie_found = true;
			// we need to handle case where cookie has no value but exists (no = sign, that is):
            if (a_temp_cookie.length >= 1){
                var parsedValue = a_temp_cookie[1].replace(/^\s+|\s+jQuery/g, '');
                cookie_value    = decodeURI(parsedValue);
            }
			// note that in cases where cookie is initialized but no value, null is returned
			return cookie_value;
		}
		a_temp_cookie = null;
		cookie_name = '';
	}
	if ( !b_cookie_found )
	{
		return null;
	}
}

function uniqArray(ary){
	var r = new Array();
		o:for(var i = 0, n = ary.length; i < n; i++)
		{
			for(var x = 0, y = r.length; x < y; x++)
			{
				if(r[x]==ary[i])
				{
					continue o;
				}
			}
			r[r.length] = ary[i];
		}
		return r;

}

