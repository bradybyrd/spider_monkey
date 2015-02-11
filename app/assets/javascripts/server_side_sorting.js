/**
 * BMC Software, Inc.
 * Confidential and Proprietary
 * Copyright (c) BMC Software, Inc. 2001-2013
 * All Rights Reserved.
 */
$.extend(jQuery, {
    margeUrlWithParams: function(url, params){
        var split_url= url.split("?");
        var old_params = {};
        if(split_url.length > 1){
            old_params = $.deparam(split_url[1]);
        }
        return split_url[0] + "?" + jQuery.param($.extend(old_params, params));
    },

    // Convert array of arrays (hash array) to object
    // [["name1":value1], ["name2": value2]] -> {'name1': value1, 'name2': value2}
    // keyFormatter - function for formatting value during conversion
    hashArraysToObject: function(hashArray, keyFormatter){
        var result = {};
        if(!keyFormatter || keyFormatter == undefined) keyFormatter = function(a,b){return a};
        for(var i=0; i<hashArray.length; i++){
            var pair = hashArray[i];
            if (pair.length < 2) throw "invalid call of hashArraysToObject(), argument is not proper array";
            result[pair[0]] = keyFormatter.call(this, pair[1], pair[0]);
        }
        return result;
    },
    // Convert object to array of arrays (hash array)
    // {'name1': value1, 'name2': value2} -> [["name1":value1], ["name2": value2]]
    objectToHashArrays: function(obj, keyFormatter){
        var result = [];
        if(!keyFormatter || keyFormatter == undefined) keyFormatter = function(a,b){return a};
        for(var key in obj){
            result.push([key, keyFormatter.call(this, pair[1], pair[0])]);
        }
        return result;
    },
    setTBodyInnerHTML: function(tbody, html) {
        var temp = tbody.ownerDocument.createElement('div');
        if ('TBODY' == $(html)[0].tagName) {
            temp.innerHTML = '<table>' + html + '</table>';
            tbody.parentNode.replaceChild(temp.firstChild.children[0], tbody);
        } else {
            tbody.parentNode.replaceChild($(html).find('tbody')[0], tbody);
        }
    }
});

/**
 * serverSideSorting usage example:
 *
 * <a class="server_side_tablesorter_pagination" href="...">1</a><a class="server_side_tablesorter_pagination" href="...">2</a> ...
 *
 * <table class="server_side_tablesorter ..." summary="<url-to-the-server-with-order-and-pagination-params>">
 *    <thead>
 *        <tr>
 *            <th headers="name1">Name 1</th>
 *            <th headers="name2">Name 2</th>
 *            <th">Name 3</th>
 *            <th headers="name4">Name 4</th>
 *        </tr>
 *    </thead>
 *    <tbody>
 *        ...
 *    </tbody>
 * </table>
 */

var SERVER_SIDE_TABLE_CLASS = 'server_side_tablesorter';
var SERVER_SIDE_PAGINATION_CLASS = 'server_side_tablesorter_pagination';

var orderArrayToOrderKeys = function(order){
    return $.hashArraysToObject(order, function(val){return val.toUpperCase() == "ASC" ? 0 : 1;});
}

var humanizedOrderToSortListLike = function(table, orderKeys){
    var tableHeaders        = table.getElementsByTagName("TH");
    var tablesorterHeaders  = {};
    var sortList            = [];

    for(var i = 0; i < tableHeaders.length; i++){
        var th = tableHeaders[i];
        if(th.headers != null && th.headers){
            // {"name":0, "name2":1} -> [[0,0],[3,0]]
            if (orderKeys[th.headers] != null && orderKeys[th.headers] != undefined) sortList.push([i,orderKeys[th.headers]]);
        } else {
            tablesorterHeaders[i] = {sorter: false};
        }
    }
    if(sortList.length == 0) sortList.push([0,0]);

    return [tablesorterHeaders, sortList];
}

$(document).ready(function() {
    var startCode = 1;
    var currentCode = startCode;

    $('table.' + SERVER_SIDE_TABLE_CLASS).livequery(function(){
        var order;
        var previousTable;
        var sortList            = []; // default Sort List
        var orderKeys           = {};
        var paginationTables    = $('.server_side_tablesorter');

        // valid summery is in previous table;
        // if more than one table present:
        // - take summary from it

        if(paginationTables.length > 1){
            // small dirty hack against `will_paginate` to force paginator to make request everytime
            // a page is chosen by removing the previous generated table
            //$(previousTable).parent().parent().remove();
            for(var i = 0; i < paginationTables.length; i++){
                if(i == 0)continue;
                // delete previous container in case there two containers contains sortingTabels with the same id
                // situation cased by will_paginate gem (that append new page rather than replace previous)
                if(paginationTables[i].parentNode && paginationTables[i].parentNode.parentNode
                    && paginationTables[i-1].parentNode && paginationTables[i-1].parentNode.parentNode
                    && paginationTables[i].parentNode.parentNode.id == paginationTables[i-1].parentNode.parentNode.id
                    && paginationTables[i].parentNode.parentNode != paginationTables[i-1].parentNode.parentNode){
                    $(paginationTables[i-1].parentNode.parentNode).remove();
                }
            }
        }
        var summary = $(this).attr('summary') || paginationTables.first().attr('summary');
        order = $.deparam(summary.split("?")[1]).order;

        // we have order as [["name","ASC"], ["name2", "DESC"]] convert it to {"name":0, "name2":1}
        if(order)  orderKeys    = orderArrayToOrderKeys(order);

        var headerAndList       = humanizedOrderToSortListLike(this, orderKeys);
        var tablesorterHeaders  = headerAndList[0];
        var sortList            = headerAndList[1];

        $(this).tablesorter({sortList: sortList,
            textExtraction: 'complex',
            showProcessing : true,
            widgets: ['zebra'],
            serverSideSorting: true,
            headers: tablesorterHeaders
        })
        // assign the sortStart event
        .bind("sortStart",function(e){
         })
         // assign the sortEnd event
         // :TODO add handler to other event, without previous sorting
        .bind("sortEnd",function(e){
            var table = e.target || e.srcElement;
            var config = table.config;
            var url = table.summary;
            var sortList = config.sortList;
            var headers = config.headerList;

            var order = [];
            for(var i = 0; i < sortList.length; i++){
                var pair = sortList[i];
                var orderName = headers[pair[0]].headers;
                var orderDirection = (pair[1] == 0) ? "ASC" : "DESC";
                order.push([orderName, orderDirection]);
            }
            var params_obj = {'order': order};

            // prepare pagination
            var pagination_links = $(table).parent().find("a." + SERVER_SIDE_PAGINATION_CLASS + ", " + "." + SERVER_SIDE_PAGINATION_CLASS + " a");

            for(var i = 0; i < pagination_links.length; i++){
                pagination_links[i].href = $.margeUrlWithParams(pagination_links[i].href, params_obj);
            }

            url = $.margeUrlWithParams(url, params_obj);
            table.summary = url;

            $.get(url, function(html) {
                if(table && table.tBodies && table.tBodies[0]) $.setTBodyInnerHTML(table.tBodies[0], html);
                $(table).trigger("update");
                Occurrences.showTooltip();
                Occurrences.initContextMenu(url);
            });
        })
    });
});
