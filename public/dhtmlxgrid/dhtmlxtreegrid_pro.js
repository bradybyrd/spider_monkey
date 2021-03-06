/*
Copyright DHTMLX LTD. http://www.dhtmlx.com
To use this component please contact sales@dhtmlx.com to obtain license

|BMC TPS Info    |DHTMLX treegrid    |TPSDR0033700     |DR4W6.2.7.00     |http://www.dhtmlx.com    |Registered  |

*/
dhtmlx=function(obj){for (var a in obj)dhtmlx[a]=obj[a];return dhtmlx};dhtmlx.extend_api=function(name,map,ext){var t = window[name];if (!t)return;window[name]=function(obj){if (obj && typeof obj == "object" && !obj.tagName){var that = t.apply(this,(map._init?map._init(obj):arguments));for (var a in dhtmlx)if (map[a])this[map[a]](dhtmlx[a]);for (var a in obj){if (map[a])this[map[a]](obj[a]);else if (a.indexOf("on")==0){this.attachEvent(a,obj[a])}}}else
 var that = t.apply(this,arguments);if (map._patch)map._patch(this);return that||this};window[name].prototype=t.prototype;if (ext)dhtmlXHeir(window[name].prototype,ext)};dhtmlxAjax={get:function(url,callback){var t=new dtmlXMLLoaderObject(true);t.async=(arguments.length<3);t.waitCall=callback;t.loadXML(url)
 return t},
 post:function(url,post,callback){var t=new dtmlXMLLoaderObject(true);t.async=(arguments.length<4);t.waitCall=callback;t.loadXML(url,true,post)
 return t},
 getSync:function(url){return this.get(url,null,true)
 },
 postSync:function(url,post){return this.post(url,post,null,true)}};function dtmlXMLLoaderObject(funcObject, dhtmlObject, async, rSeed){this.xmlDoc="";if (typeof (async)!= "undefined")
 this.async=async;else
 this.async=true;this.onloadAction=funcObject||null;this.mainObject=dhtmlObject||null;this.waitCall=null;this.rSeed=rSeed||false;return this};dtmlXMLLoaderObject.prototype.waitLoadFunction=function(dhtmlObject){var once = true;this.check=function (){if ((dhtmlObject)&&(dhtmlObject.onloadAction != null)){if ((!dhtmlObject.xmlDoc.readyState)||(dhtmlObject.xmlDoc.readyState == 4)){if (!once)return;once=false;if (typeof dhtmlObject.onloadAction == "function")dhtmlObject.onloadAction(dhtmlObject.mainObject, null, null, null, dhtmlObject);if (dhtmlObject.waitCall){dhtmlObject.waitCall.call(this,dhtmlObject);dhtmlObject.waitCall=null}}}};return this.check};dtmlXMLLoaderObject.prototype.getXMLTopNode=function(tagName, oldObj){if (this.xmlDoc.responseXML){var temp = this.xmlDoc.responseXML.getElementsByTagName(tagName);if(temp.length==0 && tagName.indexOf(":")!=-1)
 var temp = this.xmlDoc.responseXML.getElementsByTagName((tagName.split(":"))[1]);var z = temp[0]}else
 var z = this.xmlDoc.documentElement;if (z){this._retry=false;return z};if ((_isIE)&&(!this._retry)){var xmlString = this.xmlDoc.responseText;var oldObj = this.xmlDoc;this._retry=true;this.xmlDoc=new ActiveXObject("Microsoft.XMLDOM");this.xmlDoc.async=false;this.xmlDoc["loadXM"+"L"](xmlString);return this.getXMLTopNode(tagName, oldObj)};dhtmlxError.throwError("LoadXML", "Incorrect XML", [
 (oldObj||this.xmlDoc),
 this.mainObject
 ]);return document.createElement("DIV")};dtmlXMLLoaderObject.prototype.loadXMLString=function(xmlString){{
 try{var parser = new DOMParser();this.xmlDoc=parser.parseFromString(xmlString, "text/xml")}catch (e){this.xmlDoc=new ActiveXObject("Microsoft.XMLDOM");this.xmlDoc.async=this.async;this.xmlDoc["loadXM"+"L"](xmlString)}};this.onloadAction(this.mainObject, null, null, null, this);if (this.waitCall){this.waitCall();this.waitCall=null}};dtmlXMLLoaderObject.prototype.loadXML=function(filePath, postMode, postVars, rpc){if (this.rSeed)filePath+=((filePath.indexOf("?") != -1) ? "&" : "?")+"a_dhx_rSeed="+(new Date()).valueOf();this.filePath=filePath;if ((!_isIE)&&(window.XMLHttpRequest))
 this.xmlDoc=new XMLHttpRequest();else {if (document.implementation&&document.implementation.createDocument){this.xmlDoc=document.implementation.createDocument("", "", null);this.xmlDoc.onload=new this.waitLoadFunction(this);this.xmlDoc.load(filePath);return}else
 this.xmlDoc=new ActiveXObject("Microsoft.XMLHTTP")};if (this.async)this.xmlDoc.onreadystatechange=new this.waitLoadFunction(this);this.xmlDoc.open(postMode ? "POST" : "GET", filePath, this.async);if (rpc){this.xmlDoc.setRequestHeader("User-Agent", "dhtmlxRPC v0.1 ("+navigator.userAgent+")");this.xmlDoc.setRequestHeader("Content-type", "text/xml")}else if (postMode)this.xmlDoc.setRequestHeader('Content-type', 'application/x-www-form-urlencoded');this.xmlDoc.setRequestHeader("X-Requested-With","XMLHttpRequest");this.xmlDoc.send(null||postVars);if (!this.async)(new this.waitLoadFunction(this))()};dtmlXMLLoaderObject.prototype.destructor=function(){this.onloadAction=null;this.mainObject=null;this.xmlDoc=null;return null};dtmlXMLLoaderObject.prototype.xmlNodeToJSON = function(node){var t={};for (var i=0;i<node.attributes.length;i++)t[node.attributes[i].name]=node.attributes[i].value;t["_tagvalue"]=node.firstChild?node.firstChild.nodeValue:"";for (var i=0;i<node.childNodes.length;i++){var name=node.childNodes[i].tagName;if (name){if (!t[name])t[name]=[];t[name].push(this.xmlNodeToJSON(node.childNodes[i]))}};return t};function callerFunction(funcObject, dhtmlObject){this.handler=function(e){if (!e)e=window.event;funcObject(e, dhtmlObject);return true};return this.handler};function getAbsoluteLeft(htmlObject){return getOffset(htmlObject).left};function getAbsoluteTop(htmlObject){return getOffset(htmlObject).top};function getOffsetSum(elem) {var top=0, left=0;while(elem){top = top + parseInt(elem.offsetTop);left = left + parseInt(elem.offsetLeft);elem = elem.offsetParent};return {top: top, left: left}};function getOffsetRect(elem) {var box = elem.getBoundingClientRect();var body = document.body;var docElem = document.documentElement;var scrollTop = window.pageYOffset || docElem.scrollTop || body.scrollTop;var scrollLeft = window.pageXOffset || docElem.scrollLeft || body.scrollLeft;var clientTop = docElem.clientTop || body.clientTop || 0;var clientLeft = docElem.clientLeft || body.clientLeft || 0;var top = box.top + scrollTop - clientTop;var left = box.left + scrollLeft - clientLeft;return {top: Math.round(top), left: Math.round(left) }};function getOffset(elem) {if (elem.getBoundingClientRect && !_isChrome){return getOffsetRect(elem)}else {return getOffsetSum(elem)}};function convertStringToBoolean(inputString){if (typeof (inputString)== "string")
 inputString=inputString.toLowerCase();switch (inputString){case "1":
 case "true":
 case "yes":
 case "y":
 case 1:
 case true:
 return true;break;default: return false}};function getUrlSymbol(str){if (str.indexOf("?")!= -1)
 return "&"
 else
 return "?"
};function dhtmlDragAndDropObject(){if (window.dhtmlDragAndDrop)return window.dhtmlDragAndDrop;this.lastLanding=0;this.dragNode=0;this.dragStartNode=0;this.dragStartObject=0;this.tempDOMU=null;this.tempDOMM=null;this.waitDrag=0;window.dhtmlDragAndDrop=this;return this};dhtmlDragAndDropObject.prototype.removeDraggableItem=function(htmlNode){htmlNode.onmousedown=null;htmlNode.dragStarter=null;htmlNode.dragLanding=null};dhtmlDragAndDropObject.prototype.addDraggableItem=function(htmlNode, dhtmlObject){htmlNode.onmousedown=this.preCreateDragCopy;htmlNode.dragStarter=dhtmlObject;this.addDragLanding(htmlNode, dhtmlObject)};dhtmlDragAndDropObject.prototype.addDragLanding=function(htmlNode, dhtmlObject){htmlNode.dragLanding=dhtmlObject};dhtmlDragAndDropObject.prototype.preCreateDragCopy=function(e){if ((e||event)&& (e||event).button == 2)
 return;if (window.dhtmlDragAndDrop.waitDrag){window.dhtmlDragAndDrop.waitDrag=0;document.body.onmouseup=window.dhtmlDragAndDrop.tempDOMU;document.body.onmousemove=window.dhtmlDragAndDrop.tempDOMM;return false};window.dhtmlDragAndDrop.waitDrag=1;window.dhtmlDragAndDrop.tempDOMU=document.body.onmouseup;window.dhtmlDragAndDrop.tempDOMM=document.body.onmousemove;window.dhtmlDragAndDrop.dragStartNode=this;window.dhtmlDragAndDrop.dragStartObject=this.dragStarter;document.body.onmouseup=window.dhtmlDragAndDrop.preCreateDragCopy;document.body.onmousemove=window.dhtmlDragAndDrop.callDrag;window.dhtmlDragAndDrop.downtime = new Date().valueOf();if ((e)&&(e.preventDefault)){e.preventDefault();return false};return false};dhtmlDragAndDropObject.prototype.callDrag=function(e){if (!e)e=window.event;dragger=window.dhtmlDragAndDrop;if ((new Date()).valueOf()-dragger.downtime<100) return;if ((e.button == 0)&&(_isIE))
 return dragger.stopDrag();if (!dragger.dragNode&&dragger.waitDrag){dragger.dragNode=dragger.dragStartObject._createDragNode(dragger.dragStartNode, e);if (!dragger.dragNode)return dragger.stopDrag();dragger.dragNode.onselectstart=function(){return false};dragger.gldragNode=dragger.dragNode;document.body.appendChild(dragger.dragNode);document.body.onmouseup=dragger.stopDrag;dragger.waitDrag=0;dragger.dragNode.pWindow=window;dragger.initFrameRoute()};if (dragger.dragNode.parentNode != window.document.body){var grd = dragger.gldragNode;if (dragger.gldragNode.old)grd=dragger.gldragNode.old;grd.parentNode.removeChild(grd);var oldBody = dragger.dragNode.pWindow;if (_isIE){var div = document.createElement("Div");div.innerHTML=dragger.dragNode.outerHTML;dragger.dragNode=div.childNodes[0]}else
 dragger.dragNode=dragger.dragNode.cloneNode(true);dragger.dragNode.pWindow=window;dragger.gldragNode.old=dragger.dragNode;document.body.appendChild(dragger.dragNode);oldBody.dhtmlDragAndDrop.dragNode=dragger.dragNode};dragger.dragNode.style.left=e.clientX+15+(dragger.fx
 ? dragger.fx*(-1)
 : 0)
 +(document.body.scrollLeft||document.documentElement.scrollLeft)+"px";dragger.dragNode.style.top=e.clientY+3+(dragger.fy
 ? dragger.fy*(-1)
 : 0)
 +(document.body.scrollTop||document.documentElement.scrollTop)+"px";if (!e.srcElement)var z = e.target;else
 z=e.srcElement;dragger.checkLanding(z, e)};dhtmlDragAndDropObject.prototype.calculateFramePosition=function(n){if (window.name){var el = parent.frames[window.name].frameElement.offsetParent;var fx = 0;var fy = 0;while (el){fx+=el.offsetLeft;fy+=el.offsetTop;el=el.offsetParent};if ((parent.dhtmlDragAndDrop)){var ls = parent.dhtmlDragAndDrop.calculateFramePosition(1);fx+=ls.split('_')[0]*1;fy+=ls.split('_')[1]*1};if (n)return fx+"_"+fy;else
 this.fx=fx;this.fy=fy};return "0_0"};dhtmlDragAndDropObject.prototype.checkLanding=function(htmlObject, e){if ((htmlObject)&&(htmlObject.dragLanding)){if (this.lastLanding)this.lastLanding.dragLanding._dragOut(this.lastLanding);this.lastLanding=htmlObject;this.lastLanding=this.lastLanding.dragLanding._dragIn(this.lastLanding, this.dragStartNode, e.clientX,
 e.clientY, e);this.lastLanding_scr=(_isIE ? e.srcElement : e.target)}else {if ((htmlObject)&&(htmlObject.tagName != "BODY"))
 this.checkLanding(htmlObject.parentNode, e);else {if (this.lastLanding)this.lastLanding.dragLanding._dragOut(this.lastLanding, e.clientX, e.clientY, e);this.lastLanding=0;if (this._onNotFound)this._onNotFound()}}};dhtmlDragAndDropObject.prototype.stopDrag=function(e, mode){dragger=window.dhtmlDragAndDrop;if (!mode){dragger.stopFrameRoute();var temp = dragger.lastLanding;dragger.lastLanding=null;if (temp)temp.dragLanding._drag(dragger.dragStartNode, dragger.dragStartObject, temp, (_isIE
 ? event.srcElement
 : e.target))};dragger.lastLanding=null;if ((dragger.dragNode)&&(dragger.dragNode.parentNode == document.body))
 dragger.dragNode.parentNode.removeChild(dragger.dragNode);dragger.dragNode=0;dragger.gldragNode=0;dragger.fx=0;dragger.fy=0;dragger.dragStartNode=0;dragger.dragStartObject=0;document.body.onmouseup=dragger.tempDOMU;document.body.onmousemove=dragger.tempDOMM;dragger.tempDOMU=null;dragger.tempDOMM=null;dragger.waitDrag=0};dhtmlDragAndDropObject.prototype.stopFrameRoute=function(win){if (win)window.dhtmlDragAndDrop.stopDrag(1, 1);for (var i = 0;i < window.frames.length;i++){try{if ((window.frames[i] != win)&&(window.frames[i].dhtmlDragAndDrop))
 window.frames[i].dhtmlDragAndDrop.stopFrameRoute(window)}catch(e){}};try{if ((parent.dhtmlDragAndDrop)&&(parent != window)&&(parent != win))
 parent.dhtmlDragAndDrop.stopFrameRoute(window)}catch(e){}};dhtmlDragAndDropObject.prototype.initFrameRoute=function(win, mode){if (win){window.dhtmlDragAndDrop.preCreateDragCopy();window.dhtmlDragAndDrop.dragStartNode=win.dhtmlDragAndDrop.dragStartNode;window.dhtmlDragAndDrop.dragStartObject=win.dhtmlDragAndDrop.dragStartObject;window.dhtmlDragAndDrop.dragNode=win.dhtmlDragAndDrop.dragNode;window.dhtmlDragAndDrop.gldragNode=win.dhtmlDragAndDrop.dragNode;window.document.body.onmouseup=window.dhtmlDragAndDrop.stopDrag;window.waitDrag=0;if (((!_isIE)&&(mode))&&((!_isFF)||(_FFrv < 1.8)))
 window.dhtmlDragAndDrop.calculateFramePosition()};try{if ((parent.dhtmlDragAndDrop)&&(parent != window)&&(parent != win))
 parent.dhtmlDragAndDrop.initFrameRoute(window)}catch(e){};for (var i = 0;i < window.frames.length;i++){try{if ((window.frames[i] != win)&&(window.frames[i].dhtmlDragAndDrop))
 window.frames[i].dhtmlDragAndDrop.initFrameRoute(window, ((!win||mode) ? 1 : 0))}catch(e){}}};var _isFF = false;var _isIE = false;var _isOpera = false;var _isKHTML = false;var _isMacOS = false;var _isChrome = false;if (navigator.userAgent.indexOf('Macintosh')!= -1)
 _isMacOS=true;if (navigator.userAgent.toLowerCase().indexOf('chrome')>-1)
 _isChrome=true;if ((navigator.userAgent.indexOf('Safari')!= -1)||(navigator.userAgent.indexOf('Konqueror') != -1)){var _KHTMLrv = parseFloat(navigator.userAgent.substr(navigator.userAgent.indexOf('Safari')+7, 5));if (_KHTMLrv > 525){_isFF=true;var _FFrv = 1.9}else
 _isKHTML=true}else if (navigator.userAgent.indexOf('Opera')!= -1){_isOpera=true;_OperaRv=parseFloat(navigator.userAgent.substr(navigator.userAgent.indexOf('Opera')+6, 3))}else if (navigator.appName.indexOf("Microsoft")!= -1){_isIE=true;if (navigator.appVersion.indexOf("MSIE 8.0")!= -1 && document.compatMode != "BackCompat") _isIE=8}else {_isFF=true;var _FFrv = parseFloat(navigator.userAgent.split("rv:")[1])
};dtmlXMLLoaderObject.prototype.doXPath=function(xpathExp, docObj, namespace, result_type){if (_isKHTML || (!_isIE && !window.XPathResult))
 return this.doXPathOpera(xpathExp, docObj);if (_isIE){if (!docObj)if (!this.xmlDoc.nodeName)docObj=this.xmlDoc.responseXML
 else
 docObj=this.xmlDoc;if (!docObj)dhtmlxError.throwError("LoadXML", "Incorrect XML", [
 (docObj||this.xmlDoc),
 this.mainObject
 ]);if (namespace != null)docObj.setProperty("SelectionNamespaces", "xmlns:xsl='"+namespace+"'");if (result_type == 'single'){return docObj.selectSingleNode(xpathExp)}else {return docObj.selectNodes(xpathExp)||new Array(0)}}else {var nodeObj = docObj;if (!docObj){if (!this.xmlDoc.nodeName){docObj=this.xmlDoc.responseXML
 }else {docObj=this.xmlDoc}};if (!docObj)dhtmlxError.throwError("LoadXML", "Incorrect XML", [
 (docObj||this.xmlDoc),
 this.mainObject
 ]);if (docObj.nodeName.indexOf("document")!= -1){nodeObj=docObj}else {nodeObj=docObj;docObj=docObj.ownerDocument};var retType = XPathResult.ANY_TYPE;if (result_type == 'single')retType=XPathResult.FIRST_ORDERED_NODE_TYPE
 var rowsCol = new Array();var col = docObj.evaluate(xpathExp, nodeObj, function(pref){return namespace
 }, retType, null);if (retType == XPathResult.FIRST_ORDERED_NODE_TYPE){return col.singleNodeValue};var thisColMemb = col.iterateNext();while (thisColMemb){rowsCol[rowsCol.length]=thisColMemb;thisColMemb=col.iterateNext()};return rowsCol}};function _dhtmlxError(type, name, params){if (!this.catches)this.catches=new Array();return this};_dhtmlxError.prototype.catchError=function(type, func_name){this.catches[type]=func_name};_dhtmlxError.prototype.throwError=function(type, name, params){if (this.catches[type])return this.catches[type](type, name, params);if (this.catches["ALL"])return this.catches["ALL"](type, name, params);alert("Error type: "+arguments[0]+"\nDescription: "+arguments[1]);return null};window.dhtmlxError=new _dhtmlxError();dtmlXMLLoaderObject.prototype.doXPathOpera=function(xpathExp, docObj){var z = xpathExp.replace(/[\/]+/gi, "/").split('/');var obj = null;var i = 1;if (!z.length)return [];if (z[0] == ".")obj=[docObj];else if (z[0] == ""){obj=(this.xmlDoc.responseXML||this.xmlDoc).getElementsByTagName(z[i].replace(/\[[^\]]*\]/g, ""));i++}else
 return [];for (i;i < z.length;i++)obj=this._getAllNamedChilds(obj, z[i]);if (z[i-1].indexOf("[")!= -1)
 obj=this._filterXPath(obj, z[i-1]);return obj};dtmlXMLLoaderObject.prototype._filterXPath=function(a, b){var c = new Array();var b = b.replace(/[^\[]*\[\@/g, "").replace(/[\[\]\@]*/g, "");for (var i = 0;i < a.length;i++)if (a[i].getAttribute(b))
 c[c.length]=a[i];return c};dtmlXMLLoaderObject.prototype._getAllNamedChilds=function(a, b){var c = new Array();if (_isKHTML)b=b.toUpperCase();for (var i = 0;i < a.length;i++)for (var j = 0;j < a[i].childNodes.length;j++){if (_isKHTML){if (a[i].childNodes[j].tagName&&a[i].childNodes[j].tagName.toUpperCase()== b)
 c[c.length]=a[i].childNodes[j]}else if (a[i].childNodes[j].tagName == b)c[c.length]=a[i].childNodes[j]};return c};function dhtmlXHeir(a, b){for (var c in b)if (typeof (b[c])== "function")
 a[c]=b[c];return a};function dhtmlxEvent(el, event, handler){if (el.addEventListener)el.addEventListener(event, handler, false);else if (el.attachEvent)el.attachEvent("on"+event, handler)};dtmlXMLLoaderObject.prototype.xslDoc=null;dtmlXMLLoaderObject.prototype.setXSLParamValue=function(paramName, paramValue, xslDoc){if (!xslDoc)xslDoc=this.xslDoc

 if (xslDoc.responseXML)xslDoc=xslDoc.responseXML;var item =
 this.doXPath("/xsl:stylesheet/xsl:variable[@name='"+paramName+"']", xslDoc,
 "http:/\/www.w3.org/1999/XSL/Transform", "single");if (item != null)item.firstChild.nodeValue=paramValue
};dtmlXMLLoaderObject.prototype.doXSLTransToObject=function(xslDoc, xmlDoc){if (!xslDoc)xslDoc=this.xslDoc;if (xslDoc.responseXML)xslDoc=xslDoc.responseXML

 if (!xmlDoc)xmlDoc=this.xmlDoc;if (xmlDoc.responseXML)xmlDoc=xmlDoc.responseXML

 
 if (!_isIE){if (!this.XSLProcessor){this.XSLProcessor=new XSLTProcessor();this.XSLProcessor.importStylesheet(xslDoc)};var result = this.XSLProcessor.transformToDocument(xmlDoc)}else {var result = new ActiveXObject("Msxml2.DOMDocument.3.0");try{xmlDoc.transformNodeToObject(xslDoc, result)}catch(e){result = xmlDoc.transformNode(xslDoc)}};return result};dtmlXMLLoaderObject.prototype.doXSLTransToString=function(xslDoc, xmlDoc){var res = this.doXSLTransToObject(xslDoc, xmlDoc);if(typeof(res)=="string")
 return res;return this.doSerialization(res)};dtmlXMLLoaderObject.prototype.doSerialization=function(xmlDoc){if (!xmlDoc)xmlDoc=this.xmlDoc;if (xmlDoc.responseXML)xmlDoc=xmlDoc.responseXML
 if (!_isIE){var xmlSerializer = new XMLSerializer();return xmlSerializer.serializeToString(xmlDoc)}else
 return xmlDoc.xml};dhtmlxEventable=function(obj){obj.dhx_SeverCatcherPath="";obj.attachEvent=function(name, catcher, callObj){name='ev_'+name.toLowerCase();if (!this[name])this[name]=new this.eventCatcher(callObj||this);return(name+':'+this[name].addEvent(catcher))};obj.callEvent=function(name, arg0){name='ev_'+name.toLowerCase();if (this[name])return this[name].apply(this, arg0);return true};obj.checkEvent=function(name){return (!!this['ev_'+name.toLowerCase()])
 };obj.eventCatcher=function(obj){var dhx_catch = [];var z = function(){var res = true;for (var i = 0;i < dhx_catch.length;i++){if (dhx_catch[i] != null){var zr = dhx_catch[i].apply(obj, arguments);res=res&&zr}};return res};z.addEvent=function(ev){if (typeof (ev)!= "function")
 ev=eval(ev);if (ev)return dhx_catch.push(ev)-1;return false};z.removeEvent=function(id){dhx_catch[id]=null};return z};obj.detachEvent=function(id){if (id != false){var list = id.split(':');this[list[0]].removeEvent(list[1])}}};function dataProcessor(serverProcessorURL){this.serverProcessor = serverProcessorURL;this.action_param="!nativeeditor_status";this.obj = null;this.updatedRows = [];this.autoUpdate = true;this.updateMode = "cell";this._tMode="GET";this.post_delim = "_";this._waitMode=0;this._in_progress={};this._invalid={};this.mandatoryFields=[];this.messages=[];this.styles={updated:"font-weight:bold;",
 inserted:"font-weight:bold;",
 deleted:"text-decoration : line-through;",
 invalid:"background-color:FFE0E0;",
 invalid_cell:"border-bottom:2px solid red;",
 error:"color:red;",
 clear:"font-weight:normal;text-decoration:none;"
 };this.enableUTFencoding(true);dhtmlxEventable(this);return this};dataProcessor.prototype={setTransactionMode:function(mode,total){this._tMode=mode;this._tSend=total},
 escape:function(data){if (this._utf)return encodeURIComponent(data);else
 return escape(data)},
 
 enableUTFencoding:function(mode){this._utf=convertStringToBoolean(mode)},
 
 setDataColumns:function(val){this._columns=(typeof val == "string")?val.split(","):val},
 
 getSyncState:function(){return !this.updatedRows.length},
 
 enableDataNames:function(mode){this._endnm=convertStringToBoolean(mode)},
 
 enablePartialDataSend:function(mode){this._changed=convertStringToBoolean(mode)},
 
 setUpdateMode:function(mode,dnd){this.autoUpdate = (mode=="cell");this.updateMode = mode;this.dnd=dnd},
 
 setUpdated:function(rowId,state,mode){var ind=this.findRow(rowId);mode=mode||"updated";var existing = this.obj.getUserData(rowId,this.action_param);if (existing && mode == "updated")mode=existing;if (state){this.set_invalid(rowId,false);this.updatedRows[ind]=rowId;this.obj.setUserData(rowId,this.action_param,mode)}else{if (!this.is_invalid(rowId)){this.updatedRows.splice(ind,1);this.obj.setUserData(rowId,this.action_param,"")}};if (!state)this._clearUpdateFlag(rowId);this.markRow(rowId,state,mode);if (state && this.autoUpdate)this.sendData(rowId)},
 _clearUpdateFlag:function(rowId){if (this.obj.mytype!="tree"){var row=this.obj.getRowById(rowId);if (row)for (var j=0;j<this.obj._cCount;j++)this.obj.cells(rowId,j).cell.wasChanged=false}},
 markRow:function(id,state,mode){var str="";var invalid=this.is_invalid(id)
 if (invalid){str=this.styles[invalid]
 state=true};if (this.callEvent("onRowMark",[id,state,mode,invalid])){str=this.styles[state?mode:"clear"]+str;this.obj[this._methods[0]](id,str);if (invalid && invalid.details){str+=this.styles[invalid+"_cell"];for (var i=0;i < invalid.details.length;i++)if (invalid.details[i])this.obj[this._methods[1]](id,i,str)}}},
 getState:function(id){return this.obj.getUserData(id,this.action_param)},
 is_invalid:function(id){return this._invalid[id]},
 set_invalid:function(id,mode,details){if (details)mode={value:mode, details:details, toString:function(){return this.value.toString()}};this._invalid[id]=mode},
 
 checkBeforeUpdate:function(rowId){var valid=true;var c_invalid=[];for (var i=0;i<this.obj._cCount;i++)if (this.mandatoryFields[i]){var res=this.mandatoryFields[i].call(this.obj,this.obj.cells(rowId,i).getValue(),rowId,i);if (typeof res == "string"){this.messages.push(res);valid = false}else {valid&=res;c_invalid[i]=!res}};if (!valid){this.set_invalid(rowId,"invalid",c_invalid);this.setUpdated(rowId,false)};return valid},
 
 sendData:function(rowId){if (this._waitMode && (this.obj.mytype=="tree" || this.obj._h2)) return;if (this.obj.editStop)this.obj.editStop();if (this.obj.linked_form)this.obj.linked_form.update();if(typeof rowId == "undefined" || this._tSend)return this.sendAllData();if (this._in_progress[rowId])return false;this.messages=[];if (!this.checkBeforeUpdate(rowId)&& this.callEvent("onValidatationError",[rowId,this.messages])) return false;this._beforeSendData(this._getRowData(rowId),rowId)},
 _beforeSendData:function(data,rowId){if (!this.callEvent("onBeforeUpdate",[rowId,this.getState(rowId)])) return false;this._sendData(data,rowId)},
 _sendData:function(a1,rowId){if (!a1)return;if (rowId)this._in_progress[rowId]=(new Date()).valueOf();if (!this.callEvent("onBeforeDataSending",rowId?[rowId,this.getState(rowId)]:[])) return false;var a2=new dtmlXMLLoaderObject(this.afterUpdate,this,true);var a3=this.serverProcessor;if (this._tMode!="POST")a2.loadXML(a3+((a3.indexOf("?")!=-1)?"&":"?")+a1);else
 a2.loadXML(a3,true,a1);this._waitMode++},
 sendAllData:function(){if (!this.updatedRows.length)return;this.messages=[];var valid=true;for (var i=0;i<this.updatedRows.length;i++)valid&=this.checkBeforeUpdate(this.updatedRows[i]);if (!valid && !this.callEvent("onValidatationError",["",this.messages])) return false;if (this._tSend)this._sendData(this._getAllData());else
 for (var i=0;i<this.updatedRows.length;i++)if (!this._in_progress[this.updatedRows[i]]){if (this.is_invalid(this.updatedRows[i])) continue;this._beforeSendData(this._getRowData(this.updatedRows[i]),this.updatedRows[i]);if (this._waitMode && (this.obj.mytype=="tree" || this.obj._h2)) return}},
 
 
 
 
 
 
 
 
 _getAllData:function(rowId){var out=new Array();var rs=new Array();for(var i=0;i<this.updatedRows.length;i++){var id=this.updatedRows[i];if (this._in_progress[id] || this.is_invalid(id)) continue;if (!this.callEvent("onBeforeUpdate",[id,this.getState(id)])) continue;out[out.length]=this._getRowData(id,id+this.post_delim);rs[rs.length]=id;this._in_progress[id]=(new Date()).valueOf()};if (out.length)out[out.length]="ids="+rs.join(",");return out.join("&")},
 _getRowData:function(rowId,pref){pref=(pref||"");if (this.obj.mytype=="tree"){var z=this.obj._globalIdStorageFind(rowId);var z2=z.parentObject;var i=0;for (i=0;i<z2.childsCount;i++)if (z2.childNodes[i]==z)break;var str=pref+"tr_id="+this.escape(z.id);str+="&"+pref+"tr_pid="+this.escape(z2.id);str+="&"+pref+"tr_order="+i;str+="&"+pref+"tr_text="+this.escape(z.span.innerHTML);z2=(z._userdatalist||"").split(",");for (i=0;i<z2.length;i++)str+="&"+pref+this.escape(z2[i])+"="+this.escape(z.userData["t_"+z2[i]])}else{var str=pref+"gr_id="+this.escape(rowId);if (this.obj.isTreeGrid())
 str+="&"+pref+"gr_pid="+this.escape(this.obj.getParentId(rowId));var r=this.obj.getRowById(rowId);for (var i=0;i<this.obj._cCount;i++){if (this.obj._c_order)var i_c=this.obj._c_order[i];else
 var i_c=i;var c=this.obj.cells(r.idd,i);if (this._changed && !c.wasChanged()) continue;if (this._endnm)str+="&"+pref+this.obj.getColumnId(i)+"="+this.escape(c.getValue());else
 str+="&"+pref+"c"+i_c+"="+this.escape(c.getValue())};var data=this.obj.UserData[rowId];if (data){for (var j=0;j<data.keys.length;j++)if (data.keys[j].indexOf("__")!=0)
 str+="&"+pref+data.keys[j]+"="+this.escape(data.values[j])};var data=this.obj.UserData["gridglobaluserdata"];if (data){for (var j=0;j<data.keys.length;j++)str+="&"+pref+data.keys[j]+"="+this.escape(data.values[j])}};if (this.obj.linked_form)str+=this.obj.linked_form.get_serialized(rowId,pref);return str},
 
 
 
 
 
 
 
 
 
 setVerificator:function(ind,verifFunction){this.mandatoryFields[ind] = verifFunction||(function(value){return (value!="")})},
 
 clearVerificator:function(ind){this.mandatoryFields[ind] = false},
 
 
 
 
 
 findRow:function(pattern){var i=0;for(i=0;i<this.updatedRows.length;i++)if(pattern==this.updatedRows[i])break;return i},

 
 


 





 
 defineAction:function(name,handler){if (!this._uActions)this._uActions=[];this._uActions[name]=handler},




 
 afterUpdateCallback:function(sid, tid, action, btag) {delete this._in_progress[sid];var correct=(action!="error" && action!="invalid");if (!correct)this.set_invalid(sid,action);if ((this._uActions)&&(this._uActions[action])&&(!this._uActions[action](btag))) return;this.setUpdated(sid, false);var soid = sid;switch (action) {case "inserted":
 case "insert":
 if (tid != sid){this.obj[this._methods[2]](sid, tid);sid = tid};break;case "delete":
 case "deleted":
 this.obj.setUserData(sid, this.action_param, "true_deleted");this.obj[this._methods[3]](sid);return this.callEvent("onAfterUpdate", [sid, action, tid, btag])
 break};if (correct)this.obj.setUserData(sid, this.action_param,'');this.callEvent("onAfterUpdate", [sid, action, tid, btag])
 },

 
 afterUpdate:function(that,b,c,d,xml){xml.getXMLTopNode("data");if (!xml.xmlDoc.responseXML)return;var atag=xml.doXPath("//data/action");for (var i=0;i<atag.length;i++){var btag=atag[i];var action = btag.getAttribute("type");var sid = btag.getAttribute("sid");var tid = btag.getAttribute("tid");that.afterUpdateCallback(sid,tid,action,btag)};if (that._waitMode)that._waitMode--;if ((that.obj.mytype=="tree" || that.obj._h2)&& that.updatedRows.length) 
 that.sendData();that.callEvent("onAfterUpdateFinish",[]);if (!that.updatedRows.length)that.callEvent("onFullSync",[])},




 
 
 init:function(anObj){this.obj = anObj;if (this.obj._dp_init)return this.obj._dp_init(this);var self = this;if (this.obj.mytype=="tree"){this._methods=["setItemStyle","","changeItemId","deleteItem"];this.obj.attachEvent("onEdit",function(state,id){if (state==3)self.setUpdated(id,true)
 return true});this.obj.attachEvent("onDrop",function(id,id_2,id_3,tree_1,tree_2){if (tree_1==tree_2)self.setUpdated(id,true)});this.obj._onrdlh=function(rowId){var z=self.getState(rowId);if (z=="inserted"){self.set_invalid(rowId,false);self.setUpdated(rowId,false);return true};if (z=="true_deleted"){self.setUpdated(rowId,false);return true};self.setUpdated(rowId,true,"deleted")
 return false};this.obj._onradh=function(rowId){self.setUpdated(rowId,true,"inserted")
 }}else{this._methods=["setRowTextStyle","setCellTextStyle","changeRowId","deleteRow"];this.obj.attachEvent("onEditCell",function(state,id,index){if (self._columns && !self._columns[index])return true;var cell = self.obj.cells(id,index)
 if(state==1){if(cell.isCheckbox()){self.setUpdated(id,true)
 }}else if(state==2){if(cell.wasChanged()){self.setUpdated(id,true)
 }};return true})
 this.obj.attachEvent("onRowPaste",function(id){self.setUpdated(id,true)
 })
 this.obj.attachEvent("onRowIdChange",function(id,newid){var ind=self.findRow(id);if (ind<self.updatedRows.length)self.updatedRows[ind]=newid})
 this.obj.attachEvent("onSelectStateChanged",function(rowId){if(self.updateMode=="row")self.sendData();return true});this.obj.attachEvent("onEnter",function(rowId,celInd){if(self.updateMode=="row")self.sendData();return true});this.obj.attachEvent("onBeforeRowDeleted",function(rowId){if (this.dragContext && self.dnd){window.setTimeout(function(){self.setUpdated(rowId,true)},1)
 return true};var z=self.getState(rowId);if (this._h2){this._h2.forEachChild(rowId,function(el){self.setUpdated(el.id,false);self.markRow(el.id,true,"deleted")},this)};if (z=="inserted"){self.set_invalid(rowId,false);self.setUpdated(rowId,false);return true};if (z=="deleted")return false;if (z=="true_deleted"){self.setUpdated(rowId,false);return true};self.setUpdated(rowId,true,"deleted");return false});this.obj.attachEvent("onRowAdded",function(rowId){if (this.dragContext && self.dnd)return true;self.setUpdated(rowId,true,"inserted")
 return true});this.obj.on_form_update=function(id){self.setUpdated(id,true);return true}}},
 
 
 link_form:function(obj){obj.on_update=this.obj.on_form_update},
 setOnAfterUpdate:function(ev){this.attachEvent("onAfterUpdate",ev)},
 enableDebug:function(mode){},
 setOnBeforeUpdateHandler:function(func){this.attachEvent("onBeforeDataSending",func)}};var globalActiveDHTMLGridObject;String.prototype._dhx_trim=function(){return this.replace(/&nbsp;/g, " ").replace(/(^[ \t]*)|([ \t]*$)/g, "")};function dhtmlxArray(ar){return dhtmlXHeir((ar||new Array()), dhtmlxArray._master)};dhtmlxArray._master={_dhx_find:function(pattern){for (var i = 0;i < this.length;i++){if (pattern == this[i])return i};return -1},
 _dhx_insertAt:function(ind, value){this[this.length]=null;for (var i = this.length-1;i >= ind;i--)this[i]=this[i-1]
 this[ind]=value
 },
 _dhx_removeAt:function(ind){this.splice(ind,1)
 },
 _dhx_swapItems:function(ind1, ind2){var tmp = this[ind1];this[ind1]=this[ind2]
 this[ind2]=tmp}};function dhtmlXGridObject(id){if (_isIE)try{document.execCommand("BackgroundImageCache", false, true)}catch (e){};if (id){if (typeof (id)== 'object'){this.entBox=id
 this.entBox.id="cgrid2_"+this.uid()}else
 this.entBox=document.getElementById(id)}else {this.entBox=document.createElement("DIV");this.entBox.id="cgrid2_"+this.uid()};this.entBox.innerHTML="";dhtmlxEventable(this);var self = this;this._wcorr=0;this.cell=null;this.row=null;this.iconURL="";this.editor=null;this._f2kE=true;this._dclE=true;this.combos=new Array(0);this.defVal=new Array(0);this.rowsAr={};this.rowsBuffer=dhtmlxArray();this.rowsCol=dhtmlxArray();this._data_cache={};this._ecache={};this._ud_enabled=true;this.xmlLoader=new dtmlXMLLoaderObject(this.doLoadDetails, this, true, this.no_cashe);this._maskArr=[];this.selectedRows=dhtmlxArray();this.UserData={};this._sizeFix=this._borderFix=0;this.entBox.className+=" gridbox";this.entBox.style.width=this.entBox.getAttribute("width")
 ||(window.getComputedStyle
 ? (this.entBox.style.width||window.getComputedStyle(this.entBox, null)["width"])
 : (this.entBox.currentStyle
 ? this.entBox.currentStyle["width"]
 : this.entBox.style.width||0))
 ||"100%";this.entBox.style.height=this.entBox.getAttribute("height")
 ||(window.getComputedStyle
 ? (this.entBox.style.height||window.getComputedStyle(this.entBox, null)["height"])
 : (this.entBox.currentStyle
 ? this.entBox.currentStyle["height"]
 : this.entBox.style.height||0))
 ||"100%";this.entBox.style.cursor='default';this.entBox.onselectstart=function(){return false
 };var t_creator=function(name){var t=document.createElement("TABLE");t.cellSpacing=t.cellPadding=0;t.style.cssText='width:100%;table-layout:fixed;';t.className=name.substr(2);return t};this.obj=t_creator("c_obj");this.hdr=t_creator("c_hdr");this.hdr.style.marginRight="20px";this.hdr.style.paddingRight="20px";this.objBox=document.createElement("DIV");this.objBox.style.width="100%";this.objBox.style.overflow="auto";this.objBox.appendChild(this.obj);this.objBox.className="objbox";this.hdrBox=document.createElement("DIV");this.hdrBox.style.width="100%"
 this.hdrBox.style.height="25px";this.hdrBox.style.overflow="hidden";this.hdrBox.className="xhdr";this.preloadImagesAr=new Array(0)

 this.sortImg=document.createElement("IMG")
 this.sortImg.style.display="none";this.hdrBox.appendChild(this.sortImg)
 this.hdrBox.appendChild(this.hdr);this.hdrBox.style.position="relative";this.entBox.appendChild(this.hdrBox);this.entBox.appendChild(this.objBox);this.entBox.grid=this;this.objBox.grid=this;this.hdrBox.grid=this;this.obj.grid=this;this.hdr.grid=this;this.cellWidthPX=[];this.cellWidthPC=[];this.cellWidthType=this.entBox.cellwidthtype||"px";this.delim=this.entBox.delimiter||",";this._csvDelim=",";this.hdrLabels=[];this.columnIds=[];this.columnColor=[];this._hrrar=[];this.cellType=dhtmlxArray();this.cellAlign=[];this.initCellWidth=[];this.fldSort=[];this._srdh=(_isIE && (document.compatMode != "BackCompat") ? 24 : 20);this.imgURL=window.dhx_globalImgPath||"";this.isActive=false;this.isEditable=true;this.useImagesInHeader=false;this.pagingOn=false;this.rowsBufferOutSize=0;dhtmlxEvent(window, "unload", function(){try{if (self.destructor)self.destructor()}catch (e){}});this.setSkin=function(name){this.skin_name=name;this.entBox.className="gridbox gridbox_"+name;this.skin_h_correction=0;this.enableAlterCss("ev_"+name, "odd_"+name, this.isTreeGrid())
 this._fixAlterCss()

 switch (name){case "clear":
 this._topMb=document.createElement("DIV");this._topMb.className="topMumba";this._topMb.innerHTML="<img style='left:0px' src='"+this.imgURL
 +"skinC_top_left.gif'><img style='right:20px' src='"+this.imgURL+"skinC_top_right.gif'>";this.entBox.appendChild(this._topMb);this._botMb=document.createElement("DIV");this._botMb.className="bottomMumba";this._botMb.innerHTML="<img style='left:0px' src='"+this.imgURL
 +"skinD_bottom_left.gif'><img style='right:20px' src='"+this.imgURL+"skinD_bottom_right.gif'>";this.entBox.appendChild(this._botMb);this.entBox.style.position="relative";this.skin_h_correction=20;break;case "dhx_skyblue":
 case "glassy_blue":
 case "dhx_black":
 case "dhx_blue":
 case "modern":
 case "light":
 this._srdh=20;this.forceDivInHeader=true;break;case "xp":
 this.forceDivInHeader=true;if ((_isIE)&&(document.compatMode != "BackCompat"))
 this._srdh=25;else this._srdh=22;break;case "mt":
 if ((_isIE)&&(document.compatMode != "BackCompat"))
 this._srdh=25;else this._srdh=22;break;case "gray":
 if ((_isIE)&&(document.compatMode != "BackCompat"))
 this._srdh=22;break;case "sbdark":
 break};if (_isIE&&this.hdr){var d = this.hdr.parentNode;d.removeChild(this.hdr);d.appendChild(this.hdr)};this.setSizes()};if (_isIE)this.preventIECaching(true);if (window.dhtmlDragAndDropObject)this.dragger=new dhtmlDragAndDropObject();this._doOnScroll=function(e, mode){this.callEvent("onScroll", [
 this.objBox.scrollLeft,
 this.objBox.scrollTop
 ]);this.doOnScroll(e, mode)};this.doOnScroll=function(e, mode){this.hdrBox.scrollLeft=this.objBox.scrollLeft;if (this.ftr)this.ftr.parentNode.scrollLeft=this.objBox.scrollLeft;if (mode)return;if (this._srnd){if (this._dLoadTimer)window.clearTimeout(this._dLoadTimer);this._dLoadTimer=window.setTimeout(function(){self._update_srnd_view()}, 100)}};this.attachToObject=function(obj){obj.appendChild(this.globalBox?this.globalBox:this.entBox);this.setSizes()};this.init=function(fl){if ((this.isTreeGrid())&&(!this._h2)){this._h2=new dhtmlxHierarchy();if ((this._fake)&&(!this._realfake))
 this._fake._h2=this._h2;this._tgc={imgURL: null
 }};if (!this._hstyles)return;this.editStop()
 
 this.lastClicked=null;this.resized=null;this.fldSorted=this.r_fldSorted=null;this.cellWidthPX=[];this.cellWidthPC=[];if (this.hdr.rows.length > 0){this.clearAll(true)};var hdrRow = this.hdr.insertRow(0);for (var i = 0;i < this.hdrLabels.length;i++){hdrRow.appendChild(document.createElement("TH"));hdrRow.childNodes[i]._cellIndex=i;hdrRow.childNodes[i].style.height="0px"};if (_isIE && _isIE<8)hdrRow.style.position="absolute";else
 hdrRow.style.height='auto';var hdrRow = this.hdr.insertRow(_isKHTML ? 2 : 1);hdrRow._childIndexes=new Array();var col_ex = 0;for (var i = 0;i < this.hdrLabels.length;i++){hdrRow._childIndexes[i]=i-col_ex;if ((this.hdrLabels[i] == this.splitSign)&&(i != 0)){if (_isKHTML)hdrRow.insertCell(i-col_ex);hdrRow.cells[i-col_ex-1].colSpan=(hdrRow.cells[i-col_ex-1].colSpan||1)+1;hdrRow.childNodes[i-col_ex-1]._cellIndex++;col_ex++;hdrRow._childIndexes[i]=i-col_ex;continue};hdrRow.insertCell(i-col_ex);hdrRow.childNodes[i-col_ex]._cellIndex=i;hdrRow.childNodes[i-col_ex]._cellIndexS=i;this.setColumnLabel(i, this.hdrLabels[i])};if (col_ex == 0)hdrRow._childIndexes=null;this._cCount=this.hdrLabels.length;if (_isIE)window.setTimeout(function(){self.setSizes()}, 1);if (!this.obj.firstChild)this.obj.appendChild(document.createElement("TBODY"));var tar = this.obj.firstChild;if (!tar.firstChild){tar.appendChild(document.createElement("TR"));tar=tar.firstChild;if (_isIE && _isIE<8)tar.style.position="absolute";else
 tar.style.height='auto';for (var i = 0;i < this.hdrLabels.length;i++){tar.appendChild(document.createElement("TH"));tar.childNodes[i].style.height="0px"}};this._c_order=null;if (this.multiLine != true)this.obj.className+=" row20px";this.sortImg.style.position="absolute";this.sortImg.style.display="none";this.sortImg.src=this.imgURL+"sort_desc.gif";this.sortImg.defLeft=0;if (this.noHeader){this.hdrBox.style.display='none'}else {this.noHeader=false
 };if (this._ivizcol)this.setColHidden();this.attachHeader();this.attachHeader(0, 0, "_aFoot");this.setSizes();if (fl)this.parseXML()
 this.obj.scrollTop=0

 if (this.dragAndDropOff)this.dragger.addDragLanding(this.entBox, this);if (this._initDrF)this._initD();if (this._init_point)this._init_point()};this.setColumnSizes=function(gridWidth){var summ = 0;var fcols = [];for (var i = 0;i < this._cCount;i++){if ((this.initCellWidth[i] == "*")&& !this._hrrar[i]){this._awdth=false;fcols.push(i);continue};if (this.cellWidthType == '%'){if (typeof this.cellWidthPC[i]=="undefined")this.cellWidthPC[i]=this.initCellWidth[i];this.cellWidthPX[i]=Math.floor(gridWidth*this.cellWidthPC[i]/100)||0}else{if (typeof this.cellWidthPX[i]=="undefined")this.cellWidthPX[i]=this.initCellWidth[i]};if (!this._hrrar[i])summ+=this.cellWidthPX[i]*1};if (fcols.length){var ms = Math.floor((gridWidth-summ)/fcols.length);if (ms < 0)ms=1;for (var i = 0;i < fcols.length;i++){var next=Math.max((this._drsclmW ? this._drsclmW[fcols[i]] : 0),ms)
 this.cellWidthPX[fcols[i]]=next;summ+=next};this._setAutoResize()};this.obj.style.width=summ+"px";this.hdr.style.width=summ+"px";if (this.ftr)this.ftr.style.width=summ+"px";this.chngCellWidth();return summ};this.setSizes=function(){if ((!this.hdr.rows[0])) return;window.clearTimeout(this._sizeTime);if (!this.entBox.offsetWidth && (!this.globalBox || !this.globalBox.offsetWidth)){this._sizeTime=window.setTimeout(function(){self.setSizes()
 }, 250);return};var quirks=this.quirks = (_isIE && document.compatMode=="BackCompat");var outerBorder=(this.entBox.offsetWidth-this.entBox.clientWidth)/2;if (this.globalBox){var splitOuterBorder=(this.globalBox.offsetWidth-this.globalBox.clientWidth)/2;if (this._delta_x && !this._realfake){var ow = this.globalBox.clientWidth;this.globalBox.style.width=this._delta_x;this.entBox.style.width=Math.max(0,(this.globalBox.clientWidth+(quirks?splitOuterBorder*2:0))-this._fake.entBox.clientWidth)+"px";if (ow != this.globalBox.clientWidth){this._fake._correctSplit(this._fake.entBox.clientWidth)}};if (this._delta_y && !this._realfake){this.globalBox.style.height=this._delta_y;this.entBox.style.overflow=this._fake.entBox.style.overflow="hidden";this.entBox.style.height=this._fake.entBox.style.height=this.globalBox.clientHeight+(quirks?splitOuterBorder*2:0)+"px"}}else {if (this._delta_x){if (this.entBox.parentNode.tagName=="TD"){this.entBox.style.width="1px";this.entBox.style.width=parseInt(this._delta_x)*this.entBox.parentNode.clientWidth/100-outerBorder*2+"px"}else
 this.entBox.style.width=this._delta_x};if (this._delta_y)this.entBox.style.height=this._delta_y};var isVScroll = this.parentGrid?false:(this.objBox.scrollHeight > this.objBox.offsetHeight);var scrfix = _isFF?18:18;var gridWidth=this.entBox.clientWidth-(this.skin_h_correction||0)*(quirks?0:1);var gridWidthActive=this.entBox.clientWidth-(this.skin_h_correction||0);var gridHeight=this.entBox.clientHeight;var summ=this.setColumnSizes(gridWidthActive-(isVScroll?scrfix:0));var isHScroll = this.parentGrid?false:((this.objBox.scrollWidth > this.objBox.offsetWidth)||(this.objBox.style.overflowX=="scroll"));var headerHeight = this.hdr.clientHeight;var footerHeight = this.ftr?this.ftr.clientHeight:0;var newWidth=gridWidth;var newHeight=gridHeight-headerHeight-footerHeight;if (this._awdth && this._awdth[0] && this._awdth[1]==99999)isHScroll=0;if (this._ahgr){if (this._ahgrMA)newHeight=this.entBox.parentNode.clientHeight-headerHeight-footerHeight;else
 newHeight=this.obj.offsetHeight+(isHScroll?scrfix:0);if (this._ahgrM){if (this._ahgrF)newHeight=Math.min(this._ahgrM,newHeight+headerHeight+footerHeight)-headerHeight-footerHeight;else 
 newHeight=Math.min(this._ahgrM,newHeight)};if (isVScroll && newHeight>=this.obj.scrollHeight+(isHScroll?scrfix:0)){isVScroll=false;this.setColumnSizes(gridWidthActive)}};if ((this._awdth)&&(this._awdth[0])){if (this.cellWidthType == '%')this.cellWidthType="px";if (this._fake)summ+=this._fake.entBox.clientWidth;var newWidth=Math.min(Math.max(summ+(isVScroll?scrfix:0),this._awdth[2]),this._awdth[1]);if (this._fake)newWidth-=this._fake.entBox.clientWidth};newHeight=Math.max(0,newHeight);this._ff_size_delta=(this._ff_size_delta==0.1)?0.2:0.1;if (!_isFF)this._ff_size_delta=0;this.entBox.style.width=newWidth+(quirks?2:0)*outerBorder+this._ff_size_delta+"px";this.entBox.style.height=newHeight+(quirks?2:0)*outerBorder+headerHeight+footerHeight+"px";this.objBox.style.height=newHeight+((quirks&&!isVScroll)?2:0)*outerBorder+"px";this.hdrBox.style.height=headerHeight+"px";if (newHeight != gridHeight)this.doOnScroll(0, !this._srnd);var ext=this["setSizes_"+this.skin_name];if (ext)ext.call(this);this.setSortImgPos();if (headerHeight != this.hdr.clientHeight && this._ahgr)this.setSizes()};this.setSizes_clear=function(){var y=this.hdr.offsetHeight;var x=this.entBox.offsetWidth;var y2=y+this.objBox.offsetHeight;this._topMb.style.top=(y||0)+"px";this._topMb.style.width=(x+20)+"px";this._botMb.style.top=(y2-3)+"px";this._botMb.style.width=(x+20)+"px"};this.chngCellWidth=function(){if ((_isOpera)&&(this.ftr))
 this.ftr.width=this.objBox.scrollWidth+"px";var l = this._cCount;for (var i = 0;i < l;i++){this.hdr.rows[0].cells[i].style.width=this.cellWidthPX[i]+"px";this.obj.rows[0].childNodes[i].style.width=this.cellWidthPX[i]+"px";if (this.ftr)this.ftr.rows[0].cells[i].style.width=this.cellWidthPX[i]+"px"}};this.setDelimiter=function(delim){this.delim=delim};this.setInitWidthsP=function(wp){this.cellWidthType="%";this.initCellWidth=wp.split(this.delim.replace(/px/gi, ""));if (!arguments[1])this._setAutoResize()};this._setAutoResize=function(){if (this._realfake)return;var el = window;var self = this;dhtmlxEvent(window,"resize",function(){window.clearTimeout(self._resize_timer);if (self._setAutoResize)self._resize_timer=window.setTimeout(function(){self.setSizes();if (self._fake)self._fake._correctSplit()}, 100)})
 };this.setInitWidths=function(wp){this.cellWidthType="px";this.initCellWidth=wp.split(this.delim);if (_isFF){for (var i = 0;i < this.initCellWidth.length;i++)if (this.initCellWidth[i] != "*")this.initCellWidth[i]=parseInt(this.initCellWidth[i])}};this.enableMultiline=function(state){this.multiLine=convertStringToBoolean(state)};this.enableMultiselect=function(state){this.selMultiRows=convertStringToBoolean(state)};this.setImagePath=function(path){this.imgURL=path};this.setImagesPath=this.setImagePath;this.setIconPath=function(path){this.iconURL=path};this.setIconsPath=this.setIconPath;this.changeCursorState=function(ev){var el = ev.target||ev.srcElement;if (el.tagName != "TD")el=this.getFirstParentOfType(el, "TD")
 if (!el)return;if ((el.tagName == "TD")&&(this._drsclmn)&&(!this._drsclmn[el._cellIndex]))
 return el.style.cursor="default";var check = (ev.layerX||0)+(((!_isIE)&&(ev.target.tagName == "DIV")) ? el.offsetLeft : 0);if ((el.offsetWidth-(ev.offsetX||(parseInt(this.getPosition(el, this.hdrBox))-check)*-1)) < (_isOpera?20:10)){el.style.cursor="E-resize"}else{el.style.cursor="default"};if (_isOpera)this.hdrBox.scrollLeft=this.objBox.scrollLeft};this.startColResize=function(ev){if (this.resized)this.stopColResize();this.resized=null;var el = ev.target||ev.srcElement;if (el.tagName != "TD")el=this.getFirstParentOfType(el, "TD")
 var x = ev.clientX;var tabW = this.hdr.offsetWidth;var startW = parseInt(el.offsetWidth)

 if (el.tagName == "TD"&&el.style.cursor != "default"){if ((this._drsclmn)&&(!this._drsclmn[el._cellIndex]))
 return;self._old_d_mm=document.body.onmousemove;self._old_d_mu=document.body.onmouseup;document.body.onmousemove=function(e){if (self)self.doColResize(e||window.event, el, startW, x, tabW)
 };document.body.onmouseup=function(){if (self)self.stopColResize()}}};this.stopColResize=function(){document.body.onmousemove=self._old_d_mm||"";document.body.onmouseup=self._old_d_mu||"";this.setSizes();this.doOnScroll(0, 1)
 this.callEvent("onResizeEnd", [this])};this.doColResize=function(ev, el, startW, x, tabW){el.style.cursor="E-resize";this.resized=el;var fcolW = startW+(ev.clientX-x);var wtabW = tabW+(ev.clientX-x)

 if (!(this.callEvent("onResize", [
 el._cellIndex,
 fcolW,
 this
 ])))
 return;if (_isIE)this.objBox.scrollLeft=this.hdrBox.scrollLeft;if (el.colSpan > 1){var a_sizes = new Array();for (var i = 0;i < el.colSpan;i++)a_sizes[i]=Math.round(fcolW*this.hdr.rows[0].childNodes[el._cellIndexS+i].offsetWidth/el.offsetWidth);for (var i = 0;i < el.colSpan;i++)this._setColumnSizeR(el._cellIndexS+i*1, a_sizes[i])}else
 this._setColumnSizeR(el._cellIndex, fcolW);this.doOnScroll(0, 1);this.setSizes();if (this._fake && this._awdth)this._fake._correctSplit()};this._setColumnSizeR=function(ind, fcolW){if (fcolW > ((this._drsclmW&&!this._notresize)? (this._drsclmW[ind]||10) : 10)){this.obj.rows[0].childNodes[ind].style.width=fcolW+"px";this.hdr.rows[0].childNodes[ind].style.width=fcolW+"px";if (this.ftr)this.ftr.rows[0].childNodes[ind].style.width=fcolW+"px";if (this.cellWidthType == 'px'){this.cellWidthPX[ind]=fcolW}else {var gridWidth = parseInt(this.entBox.offsetWidth);if (this.objBox.scrollHeight > this.objBox.offsetHeight)gridWidth-=17;var pcWidth = Math.round(fcolW / gridWidth*100)
 this.cellWidthPC[ind]=pcWidth};if (this.sortImg.style.display!="none")this.setSortImgPos()}};this.setSortImgState=function(state, ind, order, row){order=(order||"asc").toLowerCase();if (!convertStringToBoolean(state)){this.sortImg.style.display="none";this.fldSorted=null;return};if (order == "asc")this.sortImg.src=this.imgURL+"sort_asc.gif";else
 this.sortImg.src=this.imgURL+"sort_desc.gif";this.sortImg.style.display="";this.fldSorted=this.hdr.rows[0].childNodes[ind];var r = this.hdr.rows[row||1];if (!r)return;for (var i = 0;i < r.childNodes.length;i++){if (r.childNodes[i]._cellIndexS == ind){this.r_fldSorted=r.childNodes[i];return this.setSortImgPos()}};return this.setSortImgState(state,ind,order,(row||1)+1)};this.setSortImgPos=function(ind, mode, hRowInd, el){if (this._hrrar && this._hrrar[this.r_fldSorted?this.r_fldSorted._cellIndex:ind])return;if (!el){if (!ind)var el = this.r_fldSorted;else
 var el = this.hdr.rows[hRowInd||0].cells[ind]};if (el != null){var pos = this.getPosition(el, this.hdrBox)
 var wdth = el.offsetWidth;this.sortImg.style.left=Number(pos[0]+wdth-13)+"px";this.sortImg.defLeft=parseInt(this.sortImg.style.left)
 this.sortImg.style.top=Number(pos[1]+5)+"px";if ((!this.useImagesInHeader)&&(!mode))
 this.sortImg.style.display="inline";this.sortImg.style.left=this.sortImg.defLeft+"px"}};this.setActive=function(fl){if (arguments.length == 0)var fl = true;if (fl == true){if (globalActiveDHTMLGridObject&&(globalActiveDHTMLGridObject != this))
 globalActiveDHTMLGridObject.editStop();globalActiveDHTMLGridObject=this;this.isActive=true}else {this.isActive=false}};this._doClick=function(ev){var selMethod = 0;var el = this.getFirstParentOfType(_isIE ? ev.srcElement : ev.target, "TD");if (!el)return;var fl = true;if (this.markedCells){var markMethod = 0;if (ev.shiftKey||ev.metaKey){markMethod=1};if (ev.ctrlKey){markMethod=2};this.doMark(el, markMethod);return true};if (this.selMultiRows != false){if (ev.shiftKey&&this.row != null){selMethod=1};if (ev.ctrlKey||ev.metaKey){selMethod=2}};this.doClick(el, fl, selMethod)
 };this._doContClick=function(ev){var el = this.getFirstParentOfType(_isIE ? ev.srcElement : ev.target, "TD");if ((!el)||( typeof (el.parentNode.idd) == "undefined"))
 return true;if (ev.button == 2||(_isMacOS&&ev.ctrlKey)){if (!this.callEvent("onRightClick", [
 el.parentNode.idd,
 el._cellIndex,
 ev
 ])){var z = function(e){(e||event).cancelBubble=true;return false};(ev.srcElement||ev.target).oncontextmenu=z;return z(ev)};if (this._ctmndx){if (!(this.callEvent("onBeforeContextMenu", [
 el.parentNode.idd,
 el._cellIndex,
 this
 ])))
 return true;if (_isIE)ev.srcElement.oncontextmenu=function(){event.cancelBubble=true;return false};if (this._ctmndx.showContextMenu){var dEl0=window.document.documentElement;var dEl1=window.document.body;var corrector = new Array((dEl0.scrollLeft||dEl1.scrollLeft),(dEl0.scrollTop||dEl1.scrollTop));if (_isIE){var x= ev.clientX+corrector[0];var y = ev.clientY+corrector[1]}else {var x= ev.pageX;var y = ev.pageY};this._ctmndx.showContextMenu(x-1,y-1)
 this.contextID=this._ctmndx.contextMenuZoneId=el.parentNode.idd+"_"+el._cellIndex;this._ctmndx._skip_hide=true}else {el.contextMenuId=el.parentNode.idd+"_"+el._cellIndex;el.contextMenu=this._ctmndx;el.a=this._ctmndx._contextStart;el.a(el, ev);el.a=null};ev.cancelBubble=true}}else if (this._ctmndx){if (this._ctmndx.hideContextMenu)this._ctmndx.hideContextMenu()
 else
 this._ctmndx._contextEnd()};return true};this.doClick=function(el, fl, selMethod, show){if (!this.selMultiRows)selMethod=0;var psid = this.row ? this.row.idd : 0;this.setActive(true);if (!selMethod)selMethod=0;if (this.cell != null)this.cell.className=this.cell.className.replace(/cellselected/g, "");if (el.tagName == "TD"){if (this.checkEvent("onSelectStateChanged"))
 var initial = this.getSelectedId();var prow = this.row;if (selMethod == 1){var elRowIndex = this.rowsCol._dhx_find(el.parentNode)
 var lcRowIndex = this.rowsCol._dhx_find(this.lastClicked)

 if (elRowIndex > lcRowIndex){var strt = lcRowIndex;var end = elRowIndex}else {var strt = elRowIndex;var end = lcRowIndex};for (var i = 0;i < this.rowsCol.length;i++)if ((i >= strt&&i <= end)){if (this.rowsCol[i]&&(!this.rowsCol[i]._sRow)){if (this.rowsCol[i].className.indexOf("rowselected")== -1&&this.callEvent("onBeforeSelect", [
 this.rowsCol[i].idd,
 psid
 ])){this.rowsCol[i].className+=" rowselected";this.selectedRows[this.selectedRows.length]=this.rowsCol[i]
 }}else {this.clearSelection();return this.doClick(el, fl, 0, show)}}}else if (selMethod == 2){if (el.parentNode.className.indexOf("rowselected")!= -1){el.parentNode.className=el.parentNode.className.replace(/rowselected/g, "");this.selectedRows._dhx_removeAt(this.selectedRows._dhx_find(el.parentNode))
 var skipRowSelection = true}};this.editStop()
 if (typeof (el.parentNode.idd)== "undefined")
 return true;if ((!skipRowSelection)&&(!el.parentNode._sRow)){if (this.callEvent("onBeforeSelect", [
 el.parentNode.idd,
 psid
 ])){if (selMethod == 0)this.clearSelection();this.cell=el;if ((prow == el.parentNode)&&(this._chRRS))
 fl=false;this.row=el.parentNode;this.row.className+=" rowselected"
 
 if (this.cell && _isIE && _isIE == 8 ){var next = this.cell.nextSibling;var parent = this.cell.parentNode;parent.removeChild(this.cell)
 parent.insertBefore(this.cell,next)};if (this.selectedRows._dhx_find(this.row)== -1)
 this.selectedRows[this.selectedRows.length]=this.row}};if (this.cell && this.cell.parentNode.className.indexOf("rowselected")!= -1)
 this.cell.className=this.cell.className.replace(/cellselected/g, "")+" cellselected";if (selMethod != 1)if (!this.row)return;this.lastClicked=el.parentNode;var rid = this.row.idd;var cid = this.cell;if (fl&& typeof (rid)!= "undefined" && cid && !skipRowSelection)
 self.onRowSelectTime=setTimeout(function(){self.callEvent("onRowSelect", [
 rid,
 cid._cellIndex
 ])}, 100)

 if (this.checkEvent("onSelectStateChanged")){var afinal = this.getSelectedId();if (initial != afinal)this.callEvent("onSelectStateChanged", [afinal,initial])}};this.isActive=true;if (show !== false && this.cell && this.cell.parentNode.idd)this.moveToVisible(this.cell)
 };this.selectAll=function(){this.clearSelection();this.selectedRows=dhtmlxArray([].concat(this.rowsCol));for (var i = this.rowsCol.length-1;i >= 0;i--){if (this.rowsCol[i]._cntr)this.selectedRows.splice(i, 1);else
 this.rowsCol[i].className+=" rowselected"};if (this.selectedRows.length){this.row=this.selectedRows[0];this.cell=this.row.cells[0]};if ((this._fake)&&(!this._realfake))
 this._fake.selectAll()};this.selectCell=function(r, cInd, fl, preserve, edit, show){if (!fl)fl=false;if (typeof (r)!= "object")
 r=this.render_row(r)
 if (!r || r==-1)return null;if (r._childIndexes)var c = r.childNodes[r._childIndexes[cInd]];else


 var c = r.childNodes[cInd];if (!c)c=r.childNodes[0];if (preserve)this.doClick(c, fl, 3, show)
 else
 this.doClick(c, fl, 0, show)

 if (edit)this.editCell()};this.moveToVisible=function(cell_obj, onlyVScroll){if (this.pagingOn){var newPage=Math.floor(this.getRowIndex(cell_obj.parentNode.idd) / this.rowsBufferOutSize)+1;if (newPage!=this.currentPage)this.changePage(newPage)};if (!cell_obj.offsetHeight){var mask=this._realfake?this._fake.rowsAr[cell_obj.parentNode.idd]:cell_obj.parentNode;var h=this.rowsBuffer._dhx_find(mask)*this._srdh;return this.objBox.scrollTop=h};try{var distance = cell_obj.offsetLeft+cell_obj.offsetWidth+20;var scrollLeft = 0;if (distance > (this.objBox.offsetWidth+this.objBox.scrollLeft)){if (cell_obj.offsetLeft > this.objBox.scrollLeft)scrollLeft=cell_obj.offsetLeft-5
 }else if (cell_obj.offsetLeft < this.objBox.scrollLeft){distance-=cell_obj.offsetWidth*2/3;if (distance < this.objBox.scrollLeft)scrollLeft=cell_obj.offsetLeft-5
 };if ((scrollLeft)&&(!onlyVScroll))
 this.objBox.scrollLeft=scrollLeft;var distance = cell_obj.offsetTop+cell_obj.offsetHeight+20;if (distance > (this.objBox.offsetHeight+this.objBox.scrollTop)){var scrollTop = distance-this.objBox.offsetHeight}else if (cell_obj.offsetTop < this.objBox.scrollTop){var scrollTop = cell_obj.offsetTop-5
 };if (scrollTop)this.objBox.scrollTop=scrollTop}catch (er){}};this.editCell=function(){if (this.editor&&this.cell == this.editor.cell)return;this.editStop();if ((this.isEditable != true)||(!this.cell))
 return false;var c = this.cell;if (c.parentNode._locked)return false;this.editor=this.cells4(c);if (this.editor != null){if (this.editor.isDisabled()){this.editor=null;return false};if (this.callEvent("onEditCell", [
 0,
 this.row.idd,
 this.cell._cellIndex
 ])!= false&&this.editor.edit){this._Opera_stop=(new Date).valueOf();c.className+=" editable";this.editor.edit();this.callEvent("onEditCell", [
 1,
 this.row.idd,
 this.cell._cellIndex
 ])
 }else {this.editor=null}}};this.editStop=function(mode){if (_isOpera)if (this._Opera_stop){if ((this._Opera_stop*1+50)> (new Date).valueOf())
 return;this._Opera_stop=null};if (this.editor&&this.editor != null){this.editor.cell.className=this.editor.cell.className.replace("editable", "");if (mode){var t = this.editor.val;this.editor.detach();this.editor.setValue(t);this.editor=null;return};if (this.editor.detach())
 this.cell.wasChanged=true;var g = this.editor;this.editor=null;var z = this.callEvent("onEditCell", [
 2,
 this.row.idd,
 this.cell._cellIndex,
 g.getValue(),
 g.val
 ]);if (( typeof (z)== "string")||( typeof (z) == "number"))
 g[g.setImage ? "setLabel" : "setValue"](z);else if (!z)g[g.setImage ? "setLabel" : "setValue"](g.val)}};this._nextRowCell=function(row, dir, pos){row=this._nextRow((this._groups?this.rowsCol:this.rowsBuffer)._dhx_find(row), dir);if (!row)return null;return row.childNodes[row._childIndexes ? row._childIndexes[pos] : pos]};this._getNextCell=function(acell, dir, i){acell=acell||this.cell;var arow = acell.parentNode;if (this._tabOrder){i=this._tabOrder[acell._cellIndex];if (typeof i != "undefined")if (i < 0)acell=this._nextRowCell(arow, dir, Math.abs(i)-1);else
 acell=arow.childNodes[i]}else {var i = acell._cellIndex+dir;if (i >= 0&&i < this._cCount){if (arow._childIndexes)i=arow._childIndexes[acell._cellIndex]+dir;acell=arow.childNodes[i]}else {acell=this._nextRowCell(arow, dir, (dir == 1 ? 0 : (this._cCount-1)))}};if (!acell){if ((dir == 1)&&this.tabEnd){this.tabEnd.focus();this.tabEnd.focus();this.setActive(false)};if ((dir == -1)&&this.tabStart){this.tabStart.focus();this.tabStart.focus();this.setActive(false)};return null};if (acell.style.display != "none"
 &&(!this.smartTabOrder||!this.cells(acell.parentNode.idd, acell._cellIndex).isDisabled()))
 return acell;return this._getNextCell(acell, dir)};this._nextRow=function(ind, dir){var r = this.render_row(ind+dir);if (!r || r==-1)return null;if (r&&r.style.display == "none")return this._nextRow(ind+dir, dir);return r};this.scrollPage=function(dir){var master = this._realfake?this._fake:this;var new_ind = Math.floor((master._r_select||this.getRowIndex(this.row.idd)||0)+(dir)*this.objBox.offsetHeight / (this._srdh||20));if (new_ind < 0)new_ind=0;if (new_ind >= this.rowsBuffer.length)new_ind=this.rowsBuffer.length-1;if (this._srnd && !this.rowsBuffer[new_ind]){this.objBox.scrollTop+=Math.floor((dir)*this.objBox.offsetHeight / (this._srdh||20))*(this._srdh||20);master._r_select=new_ind}else {this.selectCell(new_ind, this.cell._cellIndex, true, false,false,(this.multiLine || this._srnd));if (!this.multiLine && !this._srnd && !this._realfake)this.objBox.scrollTop=this.getRowById(this.getRowId(new_ind)).offsetTop;master._r_select=null}};this.doKey=function(ev){if (!ev)return true;if ((ev.target||ev.srcElement).value !== window.undefined){var zx = (ev.target||ev.srcElement);if ((!zx.parentNode)||(zx.parentNode.className.indexOf("editable") == -1))
 return true};if ((globalActiveDHTMLGridObject)&&(this != globalActiveDHTMLGridObject))
 return globalActiveDHTMLGridObject.doKey(ev);if (this.isActive == false){return true};if (this._htkebl)return true;if (!this.callEvent("onKeyPress", [
 ev.keyCode,
 ev.ctrlKey,
 ev.shiftKey,
 ev
 ]))
 return false;var code = "k"+ev.keyCode+"_"+(ev.ctrlKey ? 1 : 0)+"_"+(ev.shiftKey ? 1 : 0);if (this.cell){if (this._key_events[code]){if (false === this._key_events[code].call(this))
 return true;if (ev.preventDefault)ev.preventDefault();ev.cancelBubble=true;return false};if (this._key_events["k_other"])this._key_events.k_other.call(this, ev)};return true};this.selectRow=function(r, fl, preserve, show){if (typeof (r)!= 'object')
 r=this.render_row(r);this.selectCell(r, 0, fl, preserve, false, show)
 };this.wasDblClicked=function(ev){var el = this.getFirstParentOfType(_isIE ? ev.srcElement : ev.target, "TD");if (el){var rowId = el.parentNode.idd;return this.callEvent("onRowDblClicked", [
 rowId,
 el._cellIndex
 ])}};this._onHeaderClick=function(e, el){var that = this.grid;el=el||that.getFirstParentOfType(_isIE ? event.srcElement : e.target, "TD");if (this.grid.resized == null){if (!(this.grid.callEvent("onHeaderClick", [
 el._cellIndexS,
 (e||window.event)])))
 return false;that.sortField(el._cellIndexS, false, el)

 }};this.deleteSelectedRows=function(){var num = this.selectedRows.length 

 if (num == 0)return;var tmpAr = this.selectedRows;this.selectedRows=dhtmlxArray()
 for (var i = num-1;i >= 0;i--){var node = tmpAr[i]

 if (!this.deleteRow(node.idd, node)){this.selectedRows[this.selectedRows.length]=node}else {if (node == this.row){var ind = i}}};if (ind){try{if (ind+1 > this.rowsCol.length)ind--;this.selectCell(ind, 0, true)
 }catch (er){this.row=null
 this.cell=null
 }}};this.getSelectedRowId=function(){var selAr = new Array(0);var uni = {};for (var i = 0;i < this.selectedRows.length;i++){var id = this.selectedRows[i].idd;if (uni[id])continue;selAr[selAr.length]=id;uni[id]=true};if (selAr.length == 0)return null;else
 return selAr.join(this.delim)};this.getSelectedCellIndex=function(){if (this.cell != null)return this.cell._cellIndex;else
 return -1};this.getColWidth=function(ind){return parseInt(this.cellWidthPX[ind])+((_isFF) ? 2 : 0)};this.setColWidth=function(ind, value){if (this._hrrar[ind])return;if (this.cellWidthType == 'px')this.cellWidthPX[ind]=parseInt(value)-+((_isFF) ? 2 : 0);else
 this.cellWidthPC[ind]=parseInt(value);this.setSizes()};this.getRowIndex=function(row_id){for (var i = 0;i < this.rowsBuffer.length;i++)if (this.rowsBuffer[i]&&this.rowsBuffer[i].idd == row_id)return i;return -1};this.getRowId=function(ind){return this.rowsBuffer[ind] ? this.rowsBuffer[ind].idd : this.undefined};this.setRowId=function(ind, row_id){this.changeRowId(this.getRowId(ind), row_id)
 };this.changeRowId=function(oldRowId, newRowId){if (oldRowId == newRowId)return;var row = this.rowsAr[oldRowId]
 row.idd=newRowId;if (this.UserData[oldRowId]){this.UserData[newRowId]=this.UserData[oldRowId]
 this.UserData[oldRowId]=null};if (this._h2&&this._h2.get[oldRowId]){this._h2.get[newRowId]=this._h2.get[oldRowId];this._h2.get[newRowId].id=newRowId;delete this._h2.get[oldRowId]};this.rowsAr[oldRowId]=null;this.rowsAr[newRowId]=row;for (var i = 0;i < row.childNodes.length;i++)if (row.childNodes[i]._code)row.childNodes[i]._code=this._compileSCL(row.childNodes[i]._val, row.childNodes[i]);if (this._mat_links && this._mat_links[oldRowId]){var a=this._mat_links[oldRowId];delete this._mat_links[oldRowId];for (var c in a)for (var i=0;i < a[c].length;i++)this._compileSCL(a[c][i].original,a[c][i])};this.callEvent("onRowIdChange",[oldRowId,newRowId])};this.setColumnIds=function(ids){this.columnIds=ids.split(this.delim)
 };this.setColumnId=function(ind, id){this.columnIds[ind]=id};this.getColIndexById=function(id){for (var i = 0;i < this.columnIds.length;i++)if (this.columnIds[i] == id)return i};this.getColumnId=function(cin){return this.columnIds[cin]};this.getColumnLabel=function(cin, ind, hdr){var z = (hdr||this.hdr).rows[(ind||0)+1];for (var i=0;i<z.cells.length;i++)if (z.cells[i]._cellIndexS==cin)return (_isIE ? z.cells[i].innerText : z.cells[i].textContent);return ""};this.getFooterLabel=function(cin, ind){return this.getColumnLabel(cin,ind,this.ftr)};this.setRowTextBold=function(row_id){var r=this.getRowById(row_id)
 if (r)r.style.fontWeight="bold"};this.setRowTextStyle=function(row_id, styleString){var r = this.getRowById(row_id)
 if (!r)return;for (var i = 0;i < r.childNodes.length;i++){var pfix = r.childNodes[i]._attrs["style"]||"";if ((this._hrrar)&&(this._hrrar[i]))
 pfix="display:none;";if (_isIE)r.childNodes[i].style.cssText=pfix+"width:"+r.childNodes[i].style.width+";"+styleString;else
 r.childNodes[i].style.cssText=pfix+"width:"+r.childNodes[i].style.width+";"+styleString}};this.setRowColor=function(row_id, color){var r = this.getRowById(row_id)

 for (var i = 0;i < r.childNodes.length;i++)r.childNodes[i].bgColor=color};this.setCellTextStyle=function(row_id, ind, styleString){var r = this.getRowById(row_id)

 if (!r)return;var cell = r.childNodes[r._childIndexes ? r._childIndexes[ind] : ind];if (!cell)return;var pfix = "";if ((this._hrrar)&&(this._hrrar[ind]))
 pfix="display:none;";if (_isIE)cell.style.cssText=pfix+"width:"+cell.style.width+";"+styleString;else
 cell.style.cssText=pfix+"width:"+cell.style.width+";"+styleString};this.setRowTextNormal=function(row_id){var r=this.getRowById(row_id);if (r)r.style.fontWeight="normal"};this.doesRowExist=function(row_id){if (this.getRowById(row_id)!= null)
 return true
 else
 return false
 };this.getColumnsNum=function(){return this._cCount};this.moveRowUp=function(row_id){var r = this.getRowById(row_id)

 if (this.isTreeGrid())
 return this.moveRowUDTG(row_id, -1);var rInd = this.rowsCol._dhx_find(r)
 if ((r.previousSibling)&&(rInd != 0)){r.parentNode.insertBefore(r, r.previousSibling)
 this.rowsCol._dhx_swapItems(rInd, rInd-1)
 this.setSizes();var bInd=this.rowsBuffer._dhx_find(r);this.rowsBuffer._dhx_swapItems(bInd,bInd-1);if (this._cssEven)this._fixAlterCss(rInd-1)}};this.moveRowDown=function(row_id){var r = this.getRowById(row_id)

 if (this.isTreeGrid())
 return this.moveRowUDTG(row_id, 1);var rInd = this.rowsCol._dhx_find(r);if (r.nextSibling){this.rowsCol._dhx_swapItems(rInd, rInd+1)

 if (r.nextSibling.nextSibling)r.parentNode.insertBefore(r, r.nextSibling.nextSibling)
 else
 r.parentNode.appendChild(r)
 this.setSizes();var bInd=this.rowsBuffer._dhx_find(r);this.rowsBuffer._dhx_swapItems(bInd,bInd+1);if (this._cssEven)this._fixAlterCss(rInd)}};this.getCombo=function(col_ind){if (!this.combos[col_ind]){this.combos[col_ind]=new dhtmlXGridComboObject()};return this.combos[col_ind]};this.setUserData=function(row_id, name, value){if (!row_id)row_id="gridglobaluserdata";if (!this.UserData[row_id])this.UserData[row_id]=new Hashtable()
 this.UserData[row_id].put(name, value)
 };this.getUserData=function(row_id, name){if (!row_id)row_id="gridglobaluserdata";this.getRowById(row_id);var z = this.UserData[row_id];return (z ? z.get(name) : "")};this.setEditable=function(fl){this.isEditable=convertStringToBoolean(fl)};this.selectRowById=function(row_id, multiFL, show, call){if (!call)call=false;this.selectCell(this.getRowById(row_id), 0, call, multiFL, false, show)};this.clearSelection=function(){this.editStop()

 for (var i = 0;i < this.selectedRows.length;i++){var r = this.rowsAr[this.selectedRows[i].idd];if (r)r.className=r.className.replace(/rowselected/g, "")};this.selectedRows=dhtmlxArray()
 this.row=null;if (this.cell != null){this.cell.className=this.cell.className.replace(/cellselected/g, "");this.cell=null}};this.copyRowContent=function(from_row_id, to_row_id){var frRow = this.getRowById(from_row_id)

 if (!this.isTreeGrid())
 for (var i = 0;i < frRow.cells.length;i++){this.cells(to_row_id, i).setValue(this.cells(from_row_id, i).getValue())
 }else
 this._copyTreeGridRowContent(frRow, from_row_id, to_row_id);if (!_isIE)this.getRowById(from_row_id).cells[0].height=frRow.cells[0].offsetHeight
 };this.setFooterLabel=function(c, label, ind){return this.setColumnLabel(c,label,ind,this.ftr)};this.setColumnLabel=function(c, label, ind, hdr){var z = (hdr||this.hdr).rows[ind||1];var col = (z._childIndexes ? z._childIndexes[c] : c);if (!z.cells[col])return;if (!this.useImagesInHeader){var hdrHTML = "<div class='hdrcell'>"

 if (label.indexOf('img:[')!= -1){var imUrl = label.replace(/.*\[([^>]+)\].*/, "$1");label=label.substr(label.indexOf("]")+1, label.length)
 hdrHTML+="<img width='18px' height='18px' align='absmiddle' src='"+imUrl+"' hspace='2'>"
 };hdrHTML+=label;hdrHTML+="</div>";z.cells[col].innerHTML=hdrHTML;if (this._hstyles[col])z.cells[col].style.cssText=this._hstyles[col]}else {z.cells[col].style.textAlign="left";z.cells[col].innerHTML="<img src='"+this.imgURL+""+label+"' onerror='this.src = \""+this.imgURL
 +"imageloaderror.gif\"'>";var a = new Image();a.src=this.imgURL+""+label.replace(/(\.[a-z]+)/, ".des$1");this.preloadImagesAr[this.preloadImagesAr.length]=a;var b = new Image();b.src=this.imgURL+""+label.replace(/(\.[a-z]+)/, ".asc$1");this.preloadImagesAr[this.preloadImagesAr.length]=b};if ((label||"").indexOf("#") != -1){var t = label.match(/(^|{)#([^}]+)(}|$)/);if (t){var tn = "_in_header_"+t[2];if (this[tn])this[tn]((this.forceDivInHeader ? z.cells[col].firstChild : z.cells[col]), col, label.split(t[0]))}}};this.clearAll=function(header){if (!this.obj.rows[0])return;if (this._h2){this._h2=new dhtmlxHierarchy();if (this._fake){if (this._realfake)this._h2=this._fake._h2;else
 this._fake._h2=this._h2}};this.limit=this._limitC=0;this.editStop(true);if (this._dLoadTimer)window.clearTimeout(this._dLoadTimer);if (this._dload){this.objBox.scrollTop=0;this.limit=this._limitC||0;this._initDrF=true};var len = this.rowsCol.length;len=this.obj.rows.length;for (var i = len-1;i > 0;i--){var t_r = this.obj.rows[i];t_r.parentNode.removeChild(t_r)};if (header){this._master_row=null;this.obj.rows[0].parentNode.removeChild(this.obj.rows[0]);for (var i = this.hdr.rows.length-1;i >= 0;i--){var t_r = this.hdr.rows[i];t_r.parentNode.removeChild(t_r)};if (this.ftr){this.ftr.parentNode.removeChild(this.ftr);this.ftr=null};this._aHead=this.ftr=this.cellWidth=this.cellType=this._aFoot=null;this._hrrar=[];this.columnIds=[];this.combos=[]};this.row=null;this.cell=null;this.rowsCol=dhtmlxArray()
 this.rowsAr=[];this._RaSeCol=[];this.rowsBuffer=dhtmlxArray()
 this.UserData=[]
 this.selectedRows=dhtmlxArray();if (this.pagingOn || this._srnd)this.xmlFileUrl="";if (this.pagingOn)this.changePage(1);if (this._contextCallTimer)window.clearTimeout(this._contextCallTimer);if (this._sst)this.enableStableSorting(true);this._fillers=this.undefined;this.setSortImgState(false);this.setSizes();this.callEvent("onClearAll", [])};this.sortField=function(ind, repeatFl, r_el){if (this.getRowsNum()== 0)
 return false;var el = this.hdr.rows[0].cells[ind];if (!el)return;if (el.tagName == "TH"&&(this.fldSort.length-1)>= el._cellIndex
 &&this.fldSort[el._cellIndex] != 'na'){var data=this.getSortingState();var sortType= ( data[0]==ind && data[1]=="asc" ) ? "des" : "asc";if (!this.callEvent("onBeforeSorting", [
 ind,
 this.fldSort[ind],
 sortType
 ]))
 return;this.sortImg.src=this.imgURL+"sort_"+(sortType == "asc" ? "asc" : "desc")+".gif";if (this.useImagesInHeader){var cel = this.hdr.rows[1].cells[el._cellIndex].firstChild;if (this.fldSorted != null){var celT = this.hdr.rows[1].cells[this.fldSorted._cellIndex].firstChild;celT.src=celT.src.replace(/(\.asc\.)|(\.des\.)/, ".")};cel.src=cel.src.replace(/(\.[a-z]+)$/, "."+sortType+"$1")
 };this.sortRows(el._cellIndex, this.fldSort[el._cellIndex], sortType)
 this.fldSorted=el;this.r_fldSorted=r_el;var c = this.hdr.rows[1];var c = r_el.parentNode;var real_el = c._childIndexes ? c._childIndexes[el._cellIndex] : el._cellIndex;this.setSortImgPos(false, false, false, r_el)}};this.setCustomSorting=function(func, col){if (!this._customSorts)this._customSorts=new Array();this._customSorts[col]=( typeof (func) == "string") ? eval(func) : func;this.fldSort[col]="cus"};this.enableHeaderImages=function(fl){this.useImagesInHeader=fl};this.setHeader=function(hdrStr, splitSign, styles){if (typeof (hdrStr)!= "object")
 var arLab = this._eSplit(hdrStr);else
 arLab=[].concat(hdrStr);var arWdth = new Array(0);var arTyp = new dhtmlxArray(0);var arAlg = new Array(0);var arVAlg = new Array(0);var arSrt = new Array(0);for (var i = 0;i < arLab.length;i++){arWdth[arWdth.length]=Math.round(100 / arLab.length);arTyp[arTyp.length]="ed";arAlg[arAlg.length]="left";arVAlg[arVAlg.length]="middle";arSrt[arSrt.length]="na"};this.splitSign=splitSign||"#cspan";this.hdrLabels=arLab;this.cellWidth=arWdth;if (!this.initCellWidth.length)this.setInitWidthsP(arWdth.join(this.delim),true);this.cellType=arTyp;this.cellAlign=arAlg;this.cellVAlign=arVAlg;this.fldSort=arSrt;this._hstyles=styles||[]};this._eSplit=function(str){if (![].push)return str.split(this.delim);var a = "r"+(new Date()).valueOf();var z = this.delim.replace(/([\|\+\*\^])/g, "\\$1")
 return (str||"").replace(RegExp(z, "g"), a).replace(RegExp("\\\\"+a, "g"), this.delim).split(a)};this.getColType=function(cInd){return this.cellType[cInd]};this.getColTypeById=function(cID){return this.cellType[this.getColIndexById(cID)]};this.setColTypes=function(typeStr){this.cellType=dhtmlxArray(typeStr.split(this.delim));this._strangeParams=new Array();for (var i = 0;i < this.cellType.length;i++){if ((this.cellType[i].indexOf("[")!= -1)){var z = this.cellType[i].split(/[\[\]]+/g);this.cellType[i]=z[0];this.defVal[i]=z[1];if (z[1].indexOf("=")== 0){this.cellType[i]="math";this._strangeParams[i]=z[0]}};if (!window["eXcell_"+this.cellType[i]])dhtmlxError.throwError("Configuration","Incorrect cell type: "+this.cellType[i],[this,this.cellType[i]])}};this.setColSorting=function(sortStr){this.fldSort=sortStr.split(this.delim)


 for (var i = 0;i < this.fldSort.length;i++)if (((this.fldSort[i]).length > 4)&&( typeof (window[this.fldSort[i]]) == "function")){if (!this._customSorts)this._customSorts=new Array();this._customSorts[i]=window[this.fldSort[i]];this.fldSort[i]="cus"}};this.setColAlign=function(alStr){this.cellAlign=alStr.split(this.delim)
 for (var i=0;i < this.cellAlign.length;i++)this.cellAlign[i]=this.cellAlign[i]._dhx_trim()};this.setColVAlign=function(valStr){this.cellVAlign=valStr.split(this.delim)
 };this.setNoHeader=function(fl){this.noHeader=convertStringToBoolean(fl)};this.showRow=function(rowID){this.getRowById(rowID)

 if (this._h2)this.openItem(this._h2.get[rowID].parent.id);var c = this.getRowById(rowID).childNodes[0];while (c&&c.style.display == "none")c=c.nextSibling;if (c)this.moveToVisible(c, true)
 };this.setStyle=function(ss_header, ss_grid, ss_selCell, ss_selRow){this.ssModifier=[
 ss_header,
 ss_grid,
 ss_selCell,
 ss_selCell,
 ss_selRow
 ];var prefs = ["#"+this.entBox.id+" table.hdr td", "#"+this.entBox.id+" table.obj td",
 "#"+this.entBox.id+" table.obj tr.rowselected td.cellselected",
 "#"+this.entBox.id+" table.obj td.cellselected", "#"+this.entBox.id+" table.obj tr.rowselected td"];for (var i = 0;i < prefs.length;i++)if (this.ssModifier[i]){if (_isIE)document.styleSheets[0].addRule(prefs[i], this.ssModifier[i]);else
 document.styleSheets[0].insertRule(prefs[i]+" {"+this.ssModifier[i]+" };", 0)}};this.setColumnColor=function(clr){this.columnColor=clr.split(this.delim)
 };this.enableAlterCss=function(cssE, cssU, perLevel, levelUnique){if (cssE||cssU)this.attachEvent("onGridReconstructed",function(){this._fixAlterCss();if (this._fake)this._fake._fixAlterCss()});this._cssSP=perLevel;this._cssSU=levelUnique;this._cssEven=cssE;this._cssUnEven=cssU};this._fixAlterCss=function(ind){if (this._h2 && (this._cssSP || this._cssSU))
 return this._fixAlterCssTGR(ind);if (!this._cssEven && !this._cssUnEven)return;ind=ind||0;var j = ind;for (var i = ind;i < this.rowsCol.length;i++){if (!this.rowsCol[i])continue;if (this.rowsCol[i].style.display != "none"){if (this.rowsCol[i].className.indexOf("rowselected")!= -1){if (j%2 == 1)this.rowsCol[i].className=this._cssUnEven+" rowselected "+(this.rowsCol[i]._css||"");else
 this.rowsCol[i].className=this._cssEven+" rowselected "+(this.rowsCol[i]._css||"")}else {if (j%2 == 1)this.rowsCol[i].className=this._cssUnEven+" "+(this.rowsCol[i]._css||"");else
 this.rowsCol[i].className=this._cssEven+" "+(this.rowsCol[i]._css||"")};j++}}};this.clearChangedState=function(){for (var i = 0;i < this.rowsCol.length;i++){var row = this.rowsCol[i];var cols = row.childNodes.length;for (var j = 0;j < cols;j++)row.childNodes[j].wasChanged=false}};this.getChangedRows=function(and_added){var res = new Array();this.forEachRow(function(id){var row = this.rowsAr[id];if (row.tagName!="TR")return;var cols = row.childNodes.length;if (and_added && row._added)res[res.length]=row.idd;else
 for (var j = 0;j < cols;j++)if (row.childNodes[j].wasChanged){res[res.length]=row.idd;break}})
 return res.join(this.delim)};this._sUDa=false;this._sAll=false;this.setSerializationLevel=function(userData, fullXML, config, changedAttr, onlyChanged, asCDATA){this._sUDa=userData;this._sAll=fullXML;this._sConfig=config;this._chAttr=changedAttr;this._onlChAttr=onlyChanged;this._asCDATA=asCDATA};this.setSerializableColumns=function(list){if (!list){this._srClmn=null;return};this._srClmn=(list||"").split(",");for (var i = 0;i < this._srClmn.length;i++)this._srClmn[i]=convertStringToBoolean(this._srClmn[i])};this._serialise=function(rCol, inner, closed){this.editStop()
 var out = [];var close = "</"+this.xml.s_row+">"

 if (this.isTreeGrid()){this._h2.forEachChildF(0, function(el){var temp = this._serializeRow(this.render_row_tree(-1, el.id));out.push(temp);if (temp)return true;else
 return false}, this, function(){out.push(close)})}else
 for (var i = 0;i < this.rowsBuffer.length;i++)if (this.rowsBuffer[i]){var temp = this._serializeRow(this.render_row(i));out.push(temp);if (temp)out.push(close)};return [out.join("")]};this._serializeRow=function(r, i){var out = [];var ra = this.xml.row_attrs;var ca = this.xml.cell_attrs;out.push("<"+this.xml.s_row);out.push(" id='"+r.idd+"'");if ((this._sAll)&&this.selectedRows._dhx_find(r) != -1)
 out.push(" selected='1'");if (this._h2&&this._h2.get[r.idd].state == "minus")out.push(" open='1'");if (ra.length)for (var i = 0;i < ra.length;i++)out.push(" "+ra[i]+"='"+r._attrs[ra[i]]+"'");out.push(">");if (this._sUDa&&this.UserData[r.idd]){keysAr=this.UserData[r.idd].getKeys()

 for (var ii = 0;ii < keysAr.length;ii++)out.push("<userdata name='"+keysAr[ii]+"'>"+(this._asCDATA?"<![CDATA[":"")+this.UserData[r.idd].get(keysAr[ii])+(this._asCDATA?"]]>":"")+"</userdata>")};var changeFl = false;for (var jj = 0;jj < this._cCount;jj++){if ((!this._srClmn)||(this._srClmn[jj])){var zx = this.cells3(r, jj);out.push("<cell");if (ca.length)for (var i = 0;i < ca.length;i++)out.push(" "+ca[i]+"='"+zx.cell._attrs[ca[i]]+"'");zxVal=zx[this._agetm]();if (this._asCDATA)zxVal="<![CDATA["+zxVal+"]]>";if ((this._ecspn)&&(zx.cell.colSpan)&&zx.cell.colSpan > 1)
 out.push(" colspan=\""+zx.cell.colSpan+"\" ");if (this._chAttr){if (zx.wasChanged()){out.push(" changed=\"1\"");changeFl=true}}else if ((this._onlChAttr)&&(zx.wasChanged()))
 changeFl=true;if (this._sAll && this.cellType[jj]=="tree")out.push((this._h2 ? (" image='"+this._h2.get[r.idd].image+"'") : "")+">"+zxVal+"</cell>");else
 out.push(">"+zxVal+"</cell>");if ((this._ecspn)&&(zx.cell.colSpan))
 for (var u = 0;u < zx.cell.colSpan-1;u++){out.push("<cell/>");jj++}}};if ((this._onlChAttr)&&(!changeFl)&&(!r._added))
 return "";return out.join("")};this._serialiseConfig=function(){var out = "<head>";for (var i = 0;i < this.hdr.rows[0].cells.length;i++){if (this._srClmn && !this._srClmn[i])continue;var sort = this.fldSort[i];if (sort == "cus"){sort = this._customSorts[i].toString();sort=sort.replace(/function[\ ]*/,"").replace(/\([^\f]*/,"")};out+="<column width='"+this.getColWidth(i)+"' align='"+this.cellAlign[i]+"' type='"+this.cellType[i]
 +"' sort='"+(sort||"na")+"' color='"+this.columnColor[i]+"'"
 +(this.columnIds[i]
 ? (" id='"+this.columnIds[i]+"'")
 : "")+">";if (this._asCDATA)out+="<![CDATA["+this.getHeaderCol(i)+"]]>";else
 out+=this.getHeaderCol(i);var z = this.getCombo(i);if (z)for (var j = 0;j < z.keys.length;j++)out+="<option value='"+z.keys[j]+"'>"+z.values[j]+"</option>";out+="</column>"
 };return out+="</head>"};this.serialize=function(){var out = '<?xml version="1.0"?><rows>';if (this._mathSerialization)this._agetm="getMathValue";else
 this._agetm="getValue";if (this._sUDa&&this.UserData["gridglobaluserdata"]){var keysAr = this.UserData["gridglobaluserdata"].getKeys()

 for (var i = 0;i < keysAr.length;i++)out+="<userdata name='"+keysAr[i]+"'>"+this.UserData["gridglobaluserdata"].get(keysAr[i])
 +"</userdata>"};if (this._sConfig)out+=this._serialiseConfig();out+=this._serialise();out+='</rows>';return out};this.getPosition=function(oNode, pNode){if (!pNode && !_isChrome){var pos = getOffset(oNode);return [pos.left, pos.top]};var oCurrentNode = oNode;var iLeft = 0;var iTop = 0;while ((oCurrentNode)&&(oCurrentNode != pNode)){iLeft+=oCurrentNode.offsetLeft-oCurrentNode.scrollLeft;iTop+=oCurrentNode.offsetTop-oCurrentNode.scrollTop;oCurrentNode=oCurrentNode.offsetParent};if (pNode == document.body){if (_isIE){iTop+=document.body.offsetTop||document.documentElement.offsetTop;iLeft+=document.body.offsetLeft||document.documentElement.offsetLeft}else if (!_isFF){iLeft+=document.body.offsetLeft;iTop+=document.body.offsetTop}};return [iLeft, iTop]};this.getFirstParentOfType=function(obj, tag){while (obj&&obj.tagName != tag&&obj.tagName != "BODY"){obj=obj.parentNode};return obj};this.objBox.onscroll=function(){this.grid._doOnScroll()};if ((!_isOpera)||(_OperaRv > 8.5)){this.hdr.onmousemove=function(e){this.grid.changeCursorState(e||window.event)};this.hdr.onmousedown=function(e){return this.grid.startColResize(e||window.event)}};this.obj.onmousemove=this._drawTooltip;this.obj.onclick=function(e){this.grid._doClick(e||window.event);if (this.grid._sclE)this.grid.editCell(e||window.event);(e||event).cancelBubble=true};if (_isMacOS){this.entBox.oncontextmenu=function(e){e.cancelBubble=true;e.returnValue=false;return this.grid._doContClick(e||window.event)}}else {this.entBox.onmousedown=function(e){return this.grid._doContClick(e||window.event)};this.entBox.oncontextmenu=function(e){if (this._ctmndx||this.grid._ctmndx)(e||event).cancelBubble=true;return !this._ctmndx}};this.obj.ondblclick=function(e){if (!this.grid.wasDblClicked(e||window.event)) 
 return false;if (this.grid._dclE){var row = this.grid.getFirstParentOfType((_isIE?event.srcElement:e.target),"TR");if (row == this.grid.row)this.grid.editCell(e||window.event)};(e||event).cancelBubble=true;if (_isOpera)return false};this.hdr.onclick=this._onHeaderClick;this.sortImg.onclick=function(){self._onHeaderClick.apply({grid: self
 }, [
 null,
 self.r_fldSorted
 ])};this.hdr.ondblclick=this._onHeaderDblClick;if (!document.body._dhtmlxgrid_onkeydown){dhtmlxEvent(document, _isOpera?"keypress":"keydown",function(e){if (globalActiveDHTMLGridObject)return globalActiveDHTMLGridObject.doKey(e||window.event)});document.body._dhtmlxgrid_onkeydown=true};dhtmlxEvent(document.body, "click", function(){if (self.editStop)self.editStop()});this.entBox.onbeforeactivate=function(){this._still_active=null;this.grid.setActive();event.cancelBubble=true};this.entBox.onbeforedeactivate=function(){if (this.grid._still_active)this.grid._still_active=null;else 
 this.grid.isActive=false;event.cancelBubble=true};if (this.entBox.style.height.toString().indexOf("%") != -1)
 this._delta_y = this.entBox.style.height;if (this.entBox.style.width.toString().indexOf("%") != -1)
 this._delta_x = this.entBox.style.width;if (this._delta_x||this._delta_y)this._setAutoResize();this.setColHidden=this.setColumnsVisibility
 this.enableCollSpan = this.enableColSpan
 this.setMultiselect=this.enableMultiselect;this.setMultiLine=this.enableMultiline;this.deleteSelectedItem=this.deleteSelectedRows;this.getSelectedId=this.getSelectedRowId;this.getHeaderCol=this.getColumnLabel;this.isItemExists=this.doesRowExist;this.getColumnCount=this.getColumnsNum;this.setSelectedRow=this.selectRowById;this.setHeaderCol=this.setColumnLabel;this.preventIECashing=this.preventIECaching;this.enableAutoHeigth=this.enableAutoHeight;this.getUID=this.uid;if (dhtmlx.image_path)this.setImagePath(dhtmlx.image_path);if (dhtmlx.skin)this.setSkin(dhtmlx.skin);return this};dhtmlXGridObject.prototype={getRowAttribute: function(id, name){return this.getRowById(id)._attrs[name]},
 setRowAttribute: function(id, name, value){this.getRowById(id)._attrs[name]=value},
 
 isTreeGrid:function(){return (this.cellType._dhx_find("tree") != -1)},
 

 
 setRowHidden:function(id, state){var f = convertStringToBoolean(state);var row = this.getRowById(id) 
 
 if (!row)return;if (row.expand === "")this.collapseKids(row);if ((state)&&(row.style.display != "none")){row.style.display="none";var z = this.selectedRows._dhx_find(row);if (z != -1){row.className=row.className.replace("rowselected", "");for (var i = 0;i < row.childNodes.length;i++)row.childNodes[i].className=row.childNodes[i].className.replace(/cellselected/g, "");this.selectedRows._dhx_removeAt(z)};this.callEvent("onGridReconstructed", [])};if ((!state)&&(row.style.display == "none")){row.style.display="";this.callEvent("onGridReconstructed", [])};this.setSizes()},
 

 
 setColumnHidden:function(ind, state){if (!this.hdr.rows.length){if (!this._ivizcol)this._ivizcol=[];return this._ivizcol[ind]=state};if ((this.fldSorted)&&(this.fldSorted.cellIndex == ind)&&(state))
 this.sortImg.style.display="none";var f = convertStringToBoolean(state);if (f){if (!this._hrrar)this._hrrar=new Array();else if (this._hrrar[ind])return;this._hrrar[ind]="display:none;";this._hideShowColumn(ind, "none")}else {if ((!this._hrrar)||(!this._hrrar[ind]))
 return;this._hrrar[ind]="";this._hideShowColumn(ind, "")};if ((this.fldSorted)&&(this.fldSorted.cellIndex == ind)&&(!state))
 this.sortImg.style.display="inline";this.setSortImgPos();this.callEvent("onColumnHidden",[ind,state])
 },
 
 
 
 isColumnHidden:function(ind){if ((this._hrrar)&&(this._hrrar[ind]))
 return true;return false},
 
 setColumnsVisibility:function(list){if (list)this._ivizcol=list.split(this.delim);if (this.hdr.rows.length&&this._ivizcol)for (var i = 0;i < this._ivizcol.length;i++)this.setColumnHidden(i, this._ivizcol[i])},
 
 _fixHiddenRowsAll:function(pb, ind, prop, state, index){index=index||"_cellIndex";var z = pb.rows.length;for (var i = 0;i < z;i++){var x = pb.rows[i].childNodes;if (x.length != this._cCount){for (var j = 0;j < x.length;j++)if (x[j][index] == ind){x[j].style[prop]=state;break}}else
 x[ind].style[prop]=state}},
 
 _hideShowColumn:function(ind, state){var hind = ind;if ((this.hdr.rows[1]._childIndexes)&&(this.hdr.rows[1]._childIndexes[ind] != ind))
 hind=this.hdr.rows[1]._childIndexes[ind];if (state == "none"){this.hdr.rows[0].cells[ind]._oldWidth=this.hdr.rows[0].cells[ind].style.width||(this.initCellWidth[ind]+"px");this.hdr.rows[0].cells[ind]._oldWidthP=this.cellWidthPC[ind];this.obj.rows[0].cells[ind].style.width="0px";var t={rows:[this.obj.rows[0]]};this.forEachRow(function(id){if (this.rowsAr[id].tagName=="TR")t.rows.push(this.rowsAr[id])
 })
 this._fixHiddenRowsAll(t, ind, "display", "none");if (this.isTreeGrid())
 this._fixHiddenRowsAllTG(ind, "none");if ((_isOpera&&_OperaRv < 9)||_isKHTML||(_isFF)){this._fixHiddenRowsAll(this.hdr, ind, "display", "none","_cellIndexS")};if (this.ftr)this._fixHiddenRowsAll(this.ftr.childNodes[0], ind, "display", "none");this._fixHiddenRowsAll(this.hdr, ind, "whiteSpace", "nowrap","_cellIndexS");if (!this.cellWidthPX.length&&!this.cellWidthPC.length)this.cellWidthPX=[].concat(this.initCellWidth);if (this.cellWidthPX[ind])this.cellWidthPX[ind]=0;if (this.cellWidthPC[ind])this.cellWidthPC[ind]=0}else {if (this.hdr.rows[0].cells[ind]._oldWidth){var zrow = this.hdr.rows[0].cells[ind];if (_isOpera||_isKHTML||(_isFF))
 this._fixHiddenRowsAll(this.hdr, ind, "display", "","_cellIndexS");if (this.ftr)this._fixHiddenRowsAll(this.ftr.childNodes[0], ind, "display", "");var t={rows:[this.obj.rows[0]]};this.forEachRow(function(id){if (this.rowsAr[id].tagName=="TR")t.rows.push(this.rowsAr[id])
 })
 this._fixHiddenRowsAll(t, ind, "display", "");if (this.isTreeGrid())
 this._fixHiddenRowsAllTG(ind, "");this._fixHiddenRowsAll(this.hdr, ind, "whiteSpace", "normal","_cellIndexS");if (zrow._oldWidthP)this.cellWidthPC[ind]=zrow._oldWidthP;if (zrow._oldWidth)this.cellWidthPX[ind]=parseInt(zrow._oldWidth)}};this.setSizes();if ((!_isIE)&&(!_isFF)){this.obj.border=1;this.obj.border=0}},




 
 enableColSpan:function(mode){this._ecspn=convertStringToBoolean(mode)},



 
 enableRowsHover:function(mode, cssClass){this._unsetRowHover(false,true);this._hvrCss=cssClass;if (convertStringToBoolean(mode)){if (!this._elmnh){this.obj._honmousemove=this.obj.onmousemove;this.obj.onmousemove=this._setRowHover;if (_isIE)this.obj.onmouseleave=this._unsetRowHover;else
 this.obj.onmouseout=this._unsetRowHover;this._elmnh=true}}else {if (this._elmnh){this.obj.onmousemove=this.obj._honmousemove;if (_isIE)this.obj.onmouseleave=null;else
 this.obj.onmouseout=null;this._elmnh=false}}},

 
 enableEditEvents:function(click, dblclick, f2Key){this._sclE=convertStringToBoolean(click);this._dclE=convertStringToBoolean(dblclick);this._f2kE=convertStringToBoolean(f2Key)},
 

 
 enableLightMouseNavigation:function(mode){if (convertStringToBoolean(mode)){if (!this._elmn){this.entBox._onclick=this.entBox.onclick;this.entBox.onclick=function(){return true};this.obj._onclick=this.obj.onclick;this.obj.onclick=function(e){var c = this.grid.getFirstParentOfType(e ? e.target : event.srcElement, 'TD');if (!c)return;this.grid.editStop();this.grid.doClick(c);this.grid.editCell();(e||event).cancelBubble=true};this.obj._onmousemove=this.obj.onmousemove;this.obj.onmousemove=this._autoMoveSelect;this._elmn=true}}else {if (this._elmn){this.entBox.onclick=this.entBox._onclick;this.obj.onclick=this.obj._onclick;this.obj.onmousemove=this.obj._onmousemove;this._elmn=false}}},
 
 
 
 _unsetRowHover:function(e, c){if (c)that=this;else
 that=this.grid;if ((that._lahRw)&&(that._lahRw != c)){for (var i = 0;i < that._lahRw.childNodes.length;i++)that._lahRw.childNodes[i].className=that._lahRw.childNodes[i].className.replace(that._hvrCss, "");that._lahRw=null}},
 
 
 _setRowHover:function(e){var c = this.grid.getFirstParentOfType(e ? e.target : event.srcElement, 'TD');if (c && c.parentNode!=this.grid._lahRw){this.grid._unsetRowHover(0, c);c=c.parentNode;if (!c.idd || c.idd=="__filler__")return;for (var i = 0;i < c.childNodes.length;i++)c.childNodes[i].className+=" "+this.grid._hvrCss;this.grid._lahRw=c};this._honmousemove(e)},
 
 
 _autoMoveSelect:function(e){if (!this.grid.editor){var c = this.grid.getFirstParentOfType(e ? e.target : event.srcElement, 'TD');if (c.parentNode.idd)this.grid.doClick(c, true, 0)};this._onmousemove(e)},



 
 enableDistributedParsing:function(mode, count, time){if (convertStringToBoolean(mode)){this._ads_count=count||10;this._ads_time=time||250}else
 this._ads_count=0},


 
 destructor:function(){if (this._sizeTime)this._sizeTime=window.clearTimeout(this._sizeTime);this.entBox.className=(this.entBox.className||"").replace(/gridbox.*/,"");if (this.formInputs)for (var i = 0;i < this.formInputs.length;i++)this.parentForm.removeChild(this.formInputs[i]);var a;this.xmlLoader=this.xmlLoader.destructor();for (var i = 0;i < this.rowsCol.length;i++)if (this.rowsCol[i])this.rowsCol[i].grid=null;for (i in this.rowsAr)if (this.rowsAr[i])this.rowsAr[i]=null;this.rowsCol=new dhtmlxArray();this.rowsAr=new Array();this.entBox.innerHTML="";var dummy=function(){};this.entBox.onclick = this.entBox.onmousedown = this.entBox.onbeforeactivate = this.entBox.onbeforedeactivate = this.entBox.onbeforedeactivate = this.entBox.onselectstart = dummy;this.setSizes = this._update_srnd_view = this.callEvent = dummy;this.entBox.grid=null;for (a in this){if ((this[a])&&(this[a].m_obj))
 this[a].m_obj=null;this[a]=null};if (this == globalActiveDHTMLGridObject)globalActiveDHTMLGridObject=null;return null},
 

 
 getSortingState:function(){var z = new Array();if (this.fldSorted){z[0]=this.fldSorted._cellIndex;z[1]=(this.sortImg.src.indexOf("sort_desc.gif") != -1) ? "des" : "asc"};return z},

 
 
 enableAutoHeight:function(mode, maxHeight, countFullHeight){this._ahgr=convertStringToBoolean(mode);this._ahgrF=convertStringToBoolean(countFullHeight);this._ahgrM=maxHeight||null;if (arguments.length == 1){this.objBox.style.overflowY=mode?"hidden":"auto"};if (maxHeight == "auto"){this._ahgrM=null;this._ahgrMA=true;this._setAutoResize()}},

 enableStableSorting:function(mode){this._sst=convertStringToBoolean(mode);this.rowsCol.stablesort=function(cmp){var size = this.length-1;for (var i = 0;i < this.length-1;i++){for (var j = 0;j < size;j++)if (cmp(this[j], this[j+1])> 0){var temp = this[j];this[j]=this[j+1];this[j+1]=temp};size--}}},

 
 
 enableKeyboardSupport:function(mode){this._htkebl=!convertStringToBoolean(mode)},
 

 
 enableContextMenu:function(menu){this._ctmndx=menu},

 
 
 setScrollbarWidthCorrection:function(width){},

 
 enableTooltips:function(list){this._enbTts=list.split(",");for (var i = 0;i < this._enbTts.length;i++)this._enbTts[i]=convertStringToBoolean(this._enbTts[i])},

 

 
 enableResizing:function(list){this._drsclmn=list.split(",");for (var i = 0;i < this._drsclmn.length;i++)this._drsclmn[i]=convertStringToBoolean(this._drsclmn[i])},
 
 
 setColumnMinWidth:function(width, ind){if (arguments.length == 2){if (!this._drsclmW)this._drsclmW=new Array();this._drsclmW[ind]=width}else
 this._drsclmW=width.split(",")},

 
 
 enableCellIds:function(mode){this._enbCid=convertStringToBoolean(mode)},
 
 

 
 lockRow:function(rowId, mode){var z = this.getRowById(rowId);if (z){z._locked=convertStringToBoolean(mode);if ((this.cell)&&(this.cell.parentNode.idd == rowId))
 this.editStop()}},

 
 
 _getRowArray:function(row){var text = new Array();for (var ii = 0;ii < row.childNodes.length;ii++){var a = this.cells3(row, ii);text[ii]=a.getValue()};return text},


 
 setDateFormat:function(mask,incoming){this._dtmask=mask;this._dtmask_inc=incoming},
 
 
 setNumberFormat:function(mask, cInd, p_sep, d_sep){var nmask = mask.replace(/[^0\,\.]*/g, "");var pfix = nmask.indexOf(".");if (pfix > -1)pfix=nmask.length-pfix-1;var dfix = nmask.indexOf(",");if (dfix > -1)dfix=nmask.length-pfix-2-dfix;if (typeof p_sep != "string")p_sep=this.i18n.decimal_separator;if (typeof d_sep != "string")d_sep=this.i18n.group_separator;var pref = mask.split(nmask)[0];var postf = mask.split(nmask)[1];this._maskArr[cInd]=[
 pfix,
 dfix,
 pref,
 postf,
 p_sep,
 d_sep
 ]},
 
 _aplNFb:function(data, ind){var a = this._maskArr[ind];if (!a)return data;var ndata = parseFloat(data.toString().replace(/[^0-9]*/g, ""));if (data.toString().substr(0, 1) == "-")
 ndata=ndata*-1;if (a[0] > 0)ndata=ndata / Math.pow(10, a[0]);return ndata},
 
 
 _aplNF:function(data, ind){var a = this._maskArr[ind];if (!a)return data;var c = (parseFloat(data) < 0 ? "-" : "")+a[2];data=Math.abs(Math.round(parseFloat(data)*Math.pow(10, a[0] > 0 ? a[0] : 0))).toString();data=(data.length
 < a[0]
 ? Math.pow(10, a[0]+1-data.length).toString().substr(1, a[0]+1)+data.toString()
 : data).split("").reverse();data[a[0]]=(data[a[0]]||"0")+a[4];if (a[1] > 0)for (var j = (a[0] > 0 ? 0 : 1)+a[0]+a[1];j < data.length;j+=a[1])data[j]+=a[5];return c+data.reverse().join("")+a[3]},


 

 
 
 _launchCommands:function(arr){for (var i = 0;i < arr.length;i++){var args = new Array();for (var j = 0;j < arr[i].childNodes.length;j++)if (arr[i].childNodes[j].nodeType == 1)args[args.length]=arr[i].childNodes[j].firstChild.data;this[arr[i].getAttribute("command")].apply(this, args)}},
 
 
 
 _parseHead:function(xmlDoc){var hheadCol = this.xmlLoader.doXPath("./head", xmlDoc);if (hheadCol.length){var headCol = this.xmlLoader.doXPath("./column", hheadCol[0]);var asettings = this.xmlLoader.doXPath("./settings", hheadCol[0]);var awidthmet = "setInitWidths";var split = false;if (asettings[0]){for (var s = 0;s < asettings[0].childNodes.length;s++)switch (asettings[0].childNodes[s].tagName){case "colwidth":
 if (asettings[0].childNodes[s].firstChild&&asettings[0].childNodes[s].firstChild.data == "%")awidthmet="setInitWidthsP";break;case "splitat":
 split=(asettings[0].childNodes[s].firstChild ? asettings[0].childNodes[s].firstChild.data : false);break}};this._launchCommands(this.xmlLoader.doXPath("./beforeInit/call", hheadCol[0]));if (headCol.length > 0){if (this.hdr.rows.length > 0)this.clearAll(true);var sets = [
 [],
 [],
 [],
 [],
 [],
 [],
 [],
 [],
 []
 ];var attrs = ["", "width", "type", "align", "sort", "color", "format", "hidden", "id"];var calls = ["", awidthmet, "setColTypes", "setColAlign", "setColSorting", "setColumnColor", "",
 "", "setColumnIds"];for (var i = 0;i < headCol.length;i++){for (var j = 1;j < attrs.length;j++)sets[j].push(headCol[i].getAttribute(attrs[j]));sets[0].push((headCol[i].firstChild
 ? headCol[i].firstChild.data
 : "").replace(/^\s*((\s\S)*.+)\s*$/gi, "$1"))};this.setHeader(sets[0]);for (var i = 0;i < calls.length;i++)if (calls[i])this[calls[i]](sets[i].join(this.delim))
 
 for (var i = 0;i < headCol.length;i++){if ((this.cellType[i].indexOf('co')== 0)||(this.cellType[i] == "clist")){var optCol = this.xmlLoader.doXPath("./option", headCol[i]);if (optCol.length){var resAr = new Array();if (this.cellType[i] == "clist"){for (var j = 0;j < optCol.length;j++)resAr[resAr.length]=optCol[j].firstChild
 ? optCol[j].firstChild.data
 : "";this.registerCList(i, resAr)}else {var combo = this.getCombo(i);for (var j = 0;j < optCol.length;j++)combo.put(optCol[j].getAttribute("value"),
 optCol[j].firstChild
 ? optCol[j].firstChild.data
 : "")}}}else if (sets[6][i])if ((this.cellType[i].toLowerCase().indexOf("calendar")!=-1)||(this.fldSort[i] == "date"))
 this.setDateFormat(sets[6][i]);else
 this.setNumberFormat(sets[6][i], i)};this.init();var param=sets[7].join(this.delim);if (this.setColHidden && param.replace(/,/g,"")!="")
 this.setColHidden(param);if ((split)&&(this.splitAt))
 this.splitAt(split)};this._launchCommands(this.xmlLoader.doXPath("./afterInit/call", hheadCol[0]))};var gudCol = this.xmlLoader.doXPath("//rows/userdata", xmlDoc);if (gudCol.length > 0){if (!this.UserData["gridglobaluserdata"])this.UserData["gridglobaluserdata"]=new Hashtable();for (var j = 0;j < gudCol.length;j++){this.UserData["gridglobaluserdata"].put(gudCol[j].getAttribute("name"),
 gudCol[j].firstChild
 ? gudCol[j].firstChild.data
 : "")}}},
 
 

 
 
 
 getCheckedRows:function(col_ind){var d = new Array();this.forEachRowA(function(id){if (this.cells(id, col_ind).getValue() != 0)
 d.push(id)},true)
 return d.join(",")},
 
 checkAll:function(){var mode=arguments.length?arguments[0]:1;for (var cInd=0;cInd<this.getColumnsNum();cInd++){if(this.getColType(cInd)=="ch")this.setCheckedRows(cInd,mode)}},
 
 uncheckAll:function(){this.checkAll(0)},
 
 setCheckedRows:function(cInd,v){this.forEachRowA(function(id){if(this.cells(id,cInd).isCheckbox())this.cells(id,cInd).setValue(v)})},

 
 _drawTooltip:function(e){var c = this.grid.getFirstParentOfType(e ? e.target : event.srcElement, 'TD');if (!c || ((this.grid.editor)&&(this.grid.editor.cell == c)))
 return true;var r = c.parentNode;if (!r.idd||r.idd == "__filler__")return;var el = (e ? e.target : event.srcElement);if (r.idd == window.unknown)return true;if (!this.grid.callEvent("onMouseOver", [
 r.idd,
 c._cellIndex
 ]))
 return true;if ((this.grid._enbTts)&&(!this.grid._enbTts[c._cellIndex])){if (el.title)el.title='';return true};if (c._cellIndex >= this.grid._cCount)return;var ced = this.grid.cells3(r, c._cellIndex);if (!ced || !ced.cell || !ced.cell._attrs)return;if (el._title)ced.cell.title="";if (!ced.cell._attrs['title'])el._title=true;if (ced)el.title=ced.cell._attrs['title']
 ||(ced.getTitle
 ? ced.getTitle()
 : (ced.getValue()||"").toString().replace(/<[^>]*>/gi, ""));return true},

 
 enableCellWidthCorrection:function(size){if (_isFF)this._wcorr=parseInt(size)},
 
 
 
 getAllRowIds:function(separator){var ar = [];for (var i = 0;i < this.rowsBuffer.length;i++)if (this.rowsBuffer[i])ar.push(this.rowsBuffer[i].idd);return ar.join(separator||this.delim)
 },
 getAllItemIds:function(){return this.getAllRowIds()},
 


 
 
 setColspan:function(row_id, col_ind, colspan){if (!this._ecspn)return;var r = this.getRowById(row_id);if ((r._childIndexes)&&(r.childNodes[r._childIndexes[col_ind]])){var j = r._childIndexes[col_ind];var n = r.childNodes[j];var m = n.colSpan;n.colSpan=1;if ((m)&&(m != 1))
 for (var i = 1;i < m;i++){var c = document.createElement("TD");if (n.nextSibling)r.insertBefore(c, n.nextSibling);else
 r.appendChild(c);r._childIndexes[col_ind+i]=j+i;c._cellIndex=col_ind+i;c.style.textAlign=this.cellAlign[i];c.style.verticalAlign=this.cellVAlign[i];n=c;this.cells3(r, col_ind+i).setValue("")};for (var z = col_ind*1+1*m;z < r._childIndexes.length;z++){r._childIndexes[z]+=(m-1)*1}};if ((colspan)&&(colspan > 1)){if (r._childIndexes)var j = r._childIndexes[col_ind];else {var j = col_ind;r._childIndexes=new Array();for (var z = 0;z < r.childNodes.length;z++)r._childIndexes[z]=z};r.childNodes[j].colSpan=colspan;for (var z = 1;z < colspan;z++){r._childIndexes[r.childNodes[j+1]._cellIndex]=j;r.removeChild(r.childNodes[j+1])};var c1 = r.childNodes[r._childIndexes[col_ind]]._cellIndex;for (var z = c1*1+1*colspan;z < r._childIndexes.length;z++)r._childIndexes[z]-=(colspan-1)}},
 


 
 
 preventIECaching:function(mode){this.no_cashe=convertStringToBoolean(mode);this.xmlLoader.rSeed=this.no_cashe},
 enableColumnAutoSize:function(mode){this._eCAS=convertStringToBoolean(mode)},
 
 _onHeaderDblClick:function(e){var that = this.grid;var el = that.getFirstParentOfType(_isIE ? event.srcElement : e.target, "TD");if (!that._eCAS)return false;that.adjustColumnSize(el._cellIndexS)
 },
 
 
 adjustColumnSize:function(cInd, complex){if (this._hrrar && this._hrrar[cInd])return;this._notresize=true;var m = 0;this._setColumnSizeR(cInd, 20);for (var j = 1;j < this.hdr.rows.length;j++){var a = this.hdr.rows[j];a=a.childNodes[(a._childIndexes) ? a._childIndexes[cInd] : cInd];if ((a)&&((!a.colSpan)||(a.colSpan < 2)) && a._cellIndex==cInd){if ((a.childNodes[0])&&(a.childNodes[0].className == "hdrcell"))
 a=a.childNodes[0];m=Math.max(m, ((_isFF||_isOpera) ? (a.textContent.length*7) : a.scrollWidth))}};var l = this.obj.rows.length;for (var i = 1;i < l;i++){var z = this.obj.rows[i];if (z._childIndexes&&z._childIndexes[cInd] != cInd || !z.childNodes[cInd])continue;if (_isFF||_isOpera||complex)z=z.childNodes[cInd].textContent.length*7;else
 z=z.childNodes[cInd].scrollWidth;if (z > m)m=z};m+=20+(complex||0);this._setColumnSizeR(cInd, m);this._notresize=false;this.setSizes()},
 

 
 detachHeader:function(index, hdr){hdr=hdr||this.hdr;var row = hdr.rows[index+1];if (row)row.parentNode.removeChild(row);this.setSizes()},
 
 
 detachFooter:function(index){this.detachHeader(index, this.ftr)},
 
 
 attachHeader:function(values, style, _type){if (typeof (values)== "string")
 values=this._eSplit(values);if (typeof (style)== "string")
 style=style.split(this.delim);_type=_type||"_aHead";if (this.hdr.rows.length){if (values)this._createHRow([
 values,
 style
 ], this[(_type == "_aHead") ? "hdr" : "ftr"]);else if (this[_type])for (var i = 0;i < this[_type].length;i++)this.attachHeader.apply(this, this[_type][i])}else {if (!this[_type])this[_type]=new Array();this[_type][this[_type].length]=[
 values,
 style,
 _type
 ]}},
 
 _createHRow:function(data, parent){if (!parent){if (this.entBox.style.position!="absolute")this.entBox.style.position="relative";var z = document.createElement("DIV");z.className="c_ftr".substr(2);this.entBox.appendChild(z);var t = document.createElement("TABLE");t.cellPadding=t.cellSpacing=0;if (!_isIE){t.width="100%";t.style.paddingRight="20px"};t.style.marginRight="20px";t.style.tableLayout="fixed";z.appendChild(t);t.appendChild(document.createElement("TBODY"));this.ftr=parent=t;var hdrRow = t.insertRow(0);var thl = ((this.hdrLabels.length <= 1) ? data[0].length : this.hdrLabels.length);for (var i = 0;i < thl;i++){hdrRow.appendChild(document.createElement("TH"));hdrRow.childNodes[i]._cellIndex=i};if (_isIE && _isIE<8)hdrRow.style.position="absolute";else
 hdrRow.style.height='auto'};var st1 = data[1];var z = document.createElement("TR");parent.rows[0].parentNode.appendChild(z);for (var i = 0;i < data[0].length;i++){if (data[0][i] == "#cspan"){var pz = z.cells[z.cells.length-1];pz.colSpan=(pz.colSpan||1)+1;continue};if ((data[0][i] == "#rspan")&&(parent.rows.length > 1)){var pind = parent.rows.length-2;var found = false;var pz = null;while (!found){var pz = parent.rows[pind];for (var j = 0;j < pz.cells.length;j++)if (pz.cells[j]._cellIndex == i){found=j+1;break};pind--};pz=pz.cells[found-1];pz.rowSpan=(pz.rowSpan||1)+1;continue};var w = document.createElement("TD");w._cellIndex=w._cellIndexS=i;if (this._hrrar && this._hrrar[i] && !_isIE)w.style.display='none';if (typeof data[0][i] == "object")w.appendChild(data[0][i]);else {if (this.forceDivInHeader)w.innerHTML="<div class='hdrcell'>"+(data[0][i]||"&nbsp;")+"</div>";else
 w.innerHTML=(data[0][i]||"&nbsp;");if ((data[0][i]||"").indexOf("#") != -1){var t = data[0][i].match(/(^|{)#([^}]+)(}|$)/);if (t){var tn = "_in_header_"+t[2];if (this[tn])this[tn]((this.forceDivInHeader ? w.firstChild : w), i, data[0][i].split(t[0]))}}};if (st1)w.style.cssText=st1[i];z.appendChild(w)};var self = parent;if (_isKHTML){if (parent._kTimer)window.clearTimeout(parent._kTimer);parent._kTimer=window.setTimeout(function(){parent.rows[1].style.display='none';window.setTimeout(function(){parent.rows[1].style.display=''}, 1)}, 500)}},

 
 attachFooter:function(values, style){this.attachHeader(values, style, "_aFoot")},




 
 setCellExcellType:function(rowId, cellIndex, type){this.changeCellType(this.rowsAr[rowId], cellIndex, type)},
 
 changeCellType:function(r, ind, type){type=type||this.cellType[ind];var z = this.cells3(r, ind);var v = z.getValue();z.cell._cellType=type;var z = this.cells3(r, ind);z.setValue(v)},
 
 setRowExcellType:function(rowId, type){var z = this.rowsAr[rowId];for (var i = 0;i < z.childNodes.length;i++)this.changeCellType(z, i, type)},
 
 setColumnExcellType:function(colIndex, type){for (var i = 0;i < this.rowsBuffer.length;i++)if (this.rowsBuffer[i] && this.rowsBuffer[i].tagName=="TR")this.changeCellType(this.rowsBuffer[i], colIndex, type);if (this.cellType[colIndex]=="math")this._strangeParams[i]=type;else
 this.cellType[colIndex]=type},
 



 
 forEachRow:function(custom_code){for (var a in this.rowsAr)if (this.rowsAr[a]&&this.rowsAr[a].idd)custom_code.apply(this, [this.rowsAr[a].idd])},
 forEachRowA:function(custom_code){for (var a =0;a<this.rowsBuffer.length;a++){if (this.rowsBuffer[a])custom_code.call(this, this.render_row(a).idd)}},
 
 forEachCell:function(rowId, custom_code){var z = this.getRowById(rowId);if (!z)return;for (var i = 0;i < this._cCount;i++)custom_code(this.cells3(z, i),i)},
 
 enableAutoWidth:function(mode, max_limit, min_limit){this._awdth=[
 convertStringToBoolean(mode),
 parseInt(max_limit||99999),
 parseInt(min_limit||0)
 ];if (arguments.length == 1)this.objBox.style.overflowX=mode?"hidden":"auto"},

 
 
 updateFromXML:function(url, insert_new, del_missed, afterCall){if (typeof insert_new == "undefined")insert_new=true;this._refresh_mode=[
 true,
 insert_new,
 del_missed
 ];this.load(url,afterCall)
 },
 _refreshFromXML:function(xml){if (this._f_rowsBuffer)this.filterBy(0,"");reset = false;if (window.eXcell_tree){eXcell_tree.prototype.setValueX=eXcell_tree.prototype.setValue;eXcell_tree.prototype.setValue=function(content){var r=this.grid._h2.get[this.cell.parentNode.idd]
 if (r && this.cell.parentNode.valTag){this.setLabel(content)}else
 this.setValueX(content)}};var tree = this.cellType._dhx_find("tree");xml.getXMLTopNode("rows");var pid = xml.doXPath("//rows")[0].getAttribute("parent")||0;var del = {};if (this._refresh_mode[2]){if (tree != -1)this._h2.forEachChild(pid, function(obj){del[obj.id]=true}, this);else
 this.forEachRow(function(id){del[id]=true})};var rows = xml.doXPath("//row");for (var i = 0;i < rows.length;i++){var row = rows[i];var id = row.getAttribute("id");del[id]=false;var pid = row.parentNode.getAttribute("id")||pid;if (this.rowsAr[id] && this.rowsAr[id].tagName!="TR"){if (this._h2)this._h2.get[id].buff.data=row;else
 this.rowsBuffer[this.getRowIndex(id)].data=row;this.rowsAr[id]=row}else if (this.rowsAr[id]){this._process_xml_row(this.rowsAr[id], row, -1);this._postRowProcessing(this.rowsAr[id],true)
 }else if (this._refresh_mode[1]){var dadd={idd: id,
 data: row,
 _parser: this._process_xml_row,
 _locator: this._get_xml_data
 };if (this._refresh_mode[1]=="top")this.rowsBuffer.unshift(dadd);else
 this.rowsBuffer.push(dadd);if (this._h2){reset=true;(this._h2.add(id,(row.parentNode.getAttribute("id")||row.parentNode.getAttribute("parent")))).buff=this.rowsBuffer[this.rowsBuffer.length-1]};this.rowsAr[id]=row;row=this.render_row(this.rowsBuffer.length-1);this._insertRowAt(row,-1)
 }};if (this._refresh_mode[2])for (id in del){if (del[id]&&this.rowsAr[id])this.deleteRow(id)};this._refresh_mode=null;if (window.eXcell_tree)eXcell_tree.prototype.setValue=eXcell_tree.prototype.setValueX;if (reset)this._renderSort();this.callEvent("onXLE", [
 this,
 rows.length
 ]);if (this._f_rowsBuffer)this.filterByAll()},


 
 getCustomCombo:function(id, ind){var cell = this.cells(id, ind).cell;if (!cell._combo)cell._combo=new dhtmlXGridComboObject();return cell._combo},

 
 setTabOrder:function(order){var t = order.split(this.delim);this._tabOrder=[];var max=this._cCount||order.length;for (var i = 0;i < max;i++)t[i]={c: parseInt(t[i]),
 ind: i
 };t.sort(function(a, b){return (a.c > b.c ? 1 : -1)});for (var i = 0;i < max;i++)if (!t[i+1]||( typeof t[i].c == "undefined"))
 this._tabOrder[t[i].ind]=(t[0].ind+1)*-1;else
 this._tabOrder[t[i].ind]=t[i+1].ind},
 
 i18n:{loading: "Loading",
 decimal_separator:".",
 group_separator:","
 },
 
 
 _key_events:{k13_1_0: function(){var rowInd = this.rowsCol._dhx_find(this.row)
 this.selectCell(this.rowsCol[rowInd+1], this.cell._cellIndex, true)},
 k13_0_1: function(){var rowInd = this.rowsCol._dhx_find(this.row)
 this.selectCell(this.rowsCol[rowInd-1], this.cell._cellIndex, true)},
 k13_0_0: function(){this.editStop();this.callEvent("onEnter", [
 (this.row ? this.row.idd : null),
 (this.cell ? this.cell._cellIndex : null)
 ]);this._still_active=true},
 k9_0_0: function(){this.editStop();if (!this.callEvent("onTab",[true])) return true;var z = this._getNextCell(null, 1);if (z){this.selectCell(z.parentNode, z._cellIndex, (this.row != z.parentNode), false, true);this._still_active=true}},
 k9_0_1: function(){this.editStop();if (!this.callEvent("onTab",[false])) return false;var z = this._getNextCell(null, -1);if (z){this.selectCell(z.parentNode, z._cellIndex, (this.row != z.parentNode), false, true);this._still_active=true}},
 k113_0_0: function(){if (this._f2kE)this.editCell()},
 k32_0_0: function(){var c = this.cells4(this.cell);if (!c.changeState||(c.changeState()=== false))
 return false},
 k27_0_0: function(){this.editStop(true)},
 k33_0_0: function(){if (this.pagingOn)this.changePage(this.currentPage-1);else
 this.scrollPage(-1)},
 k34_0_0: function(){if (this.pagingOn)this.changePage(this.currentPage+1);else
 this.scrollPage(1)},
 k37_0_0: function(){if (!this.editor&&this.isTreeGrid())
 this.collapseKids(this.row)
 else
 return false},
 k39_0_0: function(){if (!this.editor&&this.isTreeGrid())
 this.expandKids(this.row)
 else
 return false},
 k40_0_0: function(){var master = this._realfake?this._fake:this;if (this.editor&&this.editor.combo)this.editor.shiftNext();else {if (!this.row.idd)return;var rowInd = Math.max((master._r_select||0),this.getRowIndex(this.row.idd))+1;if (this.rowsBuffer[rowInd]){master._r_select=null;this.selectCell(rowInd, this.cell._cellIndex, true);if (master.pagingOn)master.showRow(master.getRowId(rowInd))}else {this._key_events.k34_0_0.apply(this, []);if (this.pagingOn && this.rowsCol[rowInd])this.selectCell(rowInd, 0, true)}};this._still_active=true},
 k38_0_0: function(){var master = this._realfake?this._fake:this;if (this.editor&&this.editor.combo)this.editor.shiftPrev();else {if (!this.row.idd)return;var rowInd = this.getRowIndex(this.row.idd)+1;if (rowInd != -1 && (!this.pagingOn || (rowInd!=1))){var nrow = this._nextRow(rowInd-1, -1);this.selectCell(nrow, this.cell._cellIndex, true);if (master.pagingOn && nrow)master.showRow(nrow.idd)}else {this._key_events.k33_0_0.apply(this, [])}};this._still_active=true}},
 
 
 
 _build_master_row:function(){var t = document.createElement("DIV");var html = ["<table><tr>"];for (var i = 0;i < this._cCount;i++)html.push("<td></td>");html.push("</tr></table>");t.innerHTML=html.join("");this._master_row=t.firstChild.rows[0]},
 
 _prepareRow:function(new_id){if (!this._master_row)this._build_master_row();var r = this._master_row.cloneNode(true);for (var i = 0;i < r.childNodes.length;i++){r.childNodes[i]._cellIndex=i;if (this._enbCid)r.childNodes[i].id="c_"+new_id+"_"+i;if (this.dragAndDropOff)this.dragger.addDraggableItem(r.childNodes[i], this)};r.idd=new_id;r.grid=this;return r},
 

 _process_jsarray_row:function(r, data){r._attrs={};for (var j = 0;j < r.childNodes.length;j++)r.childNodes[j]._attrs={};this._fillRow(r, (this._c_order ? this._swapColumns(data) : data));return r},
 _get_jsarray_data:function(data, ind){return data[ind]},
 _process_json_row:function(r, data){r._attrs={};for (var j = 0;j < r.childNodes.length;j++)r.childNodes[j]._attrs={};this._fillRow(r, (this._c_order ? this._swapColumns(data.data) : data.data));return r},
 _get_json_data:function(data, ind){return data.data[ind]},
 
 _process_csv_row:function(r, data){r._attrs={};for (var j = 0;j < r.childNodes.length;j++)r.childNodes[j]._attrs={};this._fillRow(r, (this._c_order ? this._swapColumns(data.split(this.csv.cell)) : data.split(this.csv.cell)));return r},
 _get_csv_data:function(data, ind){return data.split(this.csv.cell)[ind]},


 _process_xml_row:function(r, xml){var cellsCol = this.xmlLoader.doXPath(this.xml.cell, xml);var strAr = [];r._attrs=this._xml_attrs(xml);if (this._ud_enabled){var udCol = this.xmlLoader.doXPath("./userdata", xml);for (var i = udCol.length-1;i >= 0;i--)this.setUserData(r.idd,udCol[i].getAttribute("name"), udCol[i].firstChild
 ? udCol[i].firstChild.data
 : "")};for (var j = 0;j < cellsCol.length;j++){var cellVal = cellsCol[this._c_order?this._c_order[j]:j];var cind = r._childIndexes?r._childIndexes[j]:j;var exc = cellVal.getAttribute("type");if (r.childNodes[cind]){if (exc)r.childNodes[cind]._cellType=exc;r.childNodes[cind]._attrs=this._xml_attrs(cellVal)};if (!cellVal.getAttribute("xmlcontent")){if (cellVal.firstChild)cellVal=cellVal.firstChild.data;else
 cellVal=""};strAr.push(cellVal)};for (j < cellsCol.length;j < r.childNodes.length;j++)r.childNodes[j]._attrs={};if (r.parentNode&&r.parentNode.tagName == "row")r._attrs["parent"]=r.parentNode.getAttribute("idd");this._fillRow(r, strAr);return r},
 _get_xml_data:function(data, ind){data=data.firstChild;while (true){if (!data)return "";if (data.tagName == "cell")ind--;if (ind < 0)break;data=data.nextSibling};return (data.firstChild ? data.firstChild.data : "")},

 _fillRow:function(r, text){if (this.editor)this.editStop();for (var i = 0;i < r.childNodes.length;i++){if ((i < text.length)||(this.defVal[i])){var ii=r.childNodes[i]._cellIndex;var val = text[ii];var aeditor = this.cells4(r.childNodes[i]);if ((this.defVal[ii])&&((val == "")||( typeof (val) == "undefined")))
 val=this.defVal[ii];if (aeditor)aeditor.setValue(val)
 }else {r.childNodes[i].innerHTML="&nbsp;";r.childNodes[i]._clearCell=true}};return r},
 
 _postRowProcessing:function(r,donly){if (r._attrs["class"])r._css=r.className=r._attrs["class"];if (r._attrs.locked)r._locked=true;if (r._attrs.bgColor)r.bgColor=r._attrs.bgColor;var cor=0;for (var i = 0;i < r.childNodes.length;i++){var c=r.childNodes[i];var ii=c._cellIndex;var s = c._attrs.style||r._attrs.style;if (s)c.style.cssText+=";"+s;if (c._attrs["class"])c.className=c._attrs["class"];s=c._attrs.align||this.cellAlign[ii];if (s)c.align=s;c.vAlign=c._attrs.valign||this.cellVAlign[ii];var color = c._attrs.bgColor||this.columnColor[ii];if (color)c.bgColor=color;if (c._attrs["colspan"] && !donly){this.setColspan(r.idd, i+cor, c._attrs["colspan"]);cor+=(c._attrs["colspan"]-1)};if (this._hrrar&&this._hrrar[ii]&&!donly){c.style.display="none"}};this.callEvent("onRowCreated", [
 r.idd,
 r,
 null
 ])},
 
 load:function(url, call, type){this.callEvent("onXLS", [this]);if (arguments.length == 2 && typeof call != "function"){type=call;call=null};type=type||"xml";if (!this.xmlFileUrl)this.xmlFileUrl=url;this._data_type=type;this.xmlLoader.onloadAction=function(that, b, c, d, xml){xml=that["_process_"+type](xml);if (!that._contextCallTimer)that.callEvent("onXLE", [that,0,0,xml]);if (call){call();call=null}};this.xmlLoader.loadXML(url)},

 loadXMLString:function(str, afterCall){var t = new dtmlXMLLoaderObject(function(){});t.loadXMLString(str);this.parse(t, afterCall, "xml")
 },

 loadXML:function(url, afterCall){this.load(url, afterCall, "xml")
 },
 
 parse:function(data, call, type){if (arguments.length == 2 && typeof call != "function"){type=call;call=null};type=type||"xml";this._data_type=type;data=this["_process_"+type](data);if (!this._contextCallTimer)this.callEvent("onXLE", [this,0,0,data]);if (call)call()},
 
 xml:{top: "rows",
 row: "./row",
 cell: "./cell",
 s_row: "row",
 s_cell: "cell",
 row_attrs: [],
 cell_attrs: []
 },
 
 csv:{row: "\n",
 cell: ","
 },
 
 _xml_attrs:function(node){var data = {};if (node.attributes.length){for (var i = 0;i < node.attributes.length;i++)data[node.attributes[i].name]=node.attributes[i].value};return data},

 _process_xml:function(xml){if (!xml.doXPath){var t = new dtmlXMLLoaderObject(function(){});if (typeof xml == "string")t.loadXMLString(xml);else {if (xml.responseXML)t.xmlDoc=xml;else
 t.xmlDoc={};t.xmlDoc.responseXML=xml};xml=t};if (this._refresh_mode)return this._refreshFromXML(xml);this._parsing=true;var top = xml.getXMLTopNode(this.xml.top)
 if (top.tagName.toLowerCase()!=this.xml.top) return;this._parseHead(top);var rows = xml.doXPath(this.xml.row, top)
 var cr = parseInt(xml.doXPath("//"+this.xml.top)[0].getAttribute("pos")||0);var total = parseInt(xml.doXPath("//"+this.xml.top)[0].getAttribute("total_count")||0);if (total&&!this.rowsBuffer[total-1])this.rowsBuffer[total-1]=null;if (this.isTreeGrid())
 return this._process_tree_xml(xml);for (var i = 0;i < rows.length;i++){if (this.rowsBuffer[i+cr])continue;var id = rows[i].getAttribute("id")||(i+cr+1);this.rowsBuffer[i+cr]={idd: id,
 data: rows[i],
 _parser: this._process_xml_row,
 _locator: this._get_xml_data
 };this.rowsAr[id]=rows[i]};this.render_dataset();this._parsing=false;return xml.xmlDoc.responseXML?xml.xmlDoc.responseXML:xml.xmlDoc},


 _process_jsarray:function(data){this._parsing=true;if (data&&data.xmlDoc)eval("data="+data.xmlDoc.responseText+";");for (var i = 0;i < data.length;i++){var id = i+1;this.rowsBuffer.push({idd: id,
 data: data[i],
 _parser: this._process_jsarray_row,
 _locator: this._get_jsarray_data
 });this.rowsAr[id]=data[i]};this.render_dataset();this._parsing=false},
 
 _process_csv:function(data){this._parsing=true;if (data.xmlDoc)data=data.xmlDoc.responseText;data=data.replace(/\r/g,"");data=data.split(this.csv.row);if (this._csvHdr){this.clearAll();var thead=data.splice(0,1)[0].split(this.csv.cell);if (!this._csvAID)thead.splice(0,1);this.setHeader(thead.join(this.delim));this.init()};for (var i = 0;i < data.length;i++){if (!data[i] && i==data.length-1)continue;if (this._csvAID){var id = i+1;this.rowsBuffer.push({idd: id,
 data: data[i],
 _parser: this._process_csv_row,
 _locator: this._get_csv_data
 })}else {var temp = data[i].split(this.csv.cell);var id = temp.splice(0,1)[0];this.rowsBuffer.push({idd: id,
 data: temp,
 _parser: this._process_jsarray_row,
 _locator: this._get_jsarray_data
 })};this.rowsAr[id]=data[i]};this.render_dataset();this._parsing=false},
 
 _process_json:function(data){this._parsing=true;if (data&&data.xmlDoc)eval("data="+data.xmlDoc.responseText+";");for (var i = 0;i < data.rows.length;i++){var id = data.rows[i].id;this.rowsBuffer.push({idd: id,
 data: data.rows[i],
 _parser: this._process_json_row,
 _locator: this._get_json_data
 });this.rowsAr[id]=data[i]};this.render_dataset();this._parsing=false},

 render_dataset:function(min, max){if (this._srnd){if (this._fillers)return this._update_srnd_view();max=Math.min((this._get_view_size()+(this._srnd_pr||0)), this.rowsBuffer.length)};if (this.pagingOn){min=Math.max((min||0),(this.currentPage-1)*this.rowsBufferOutSize);max=Math.min(this.currentPage*this.rowsBufferOutSize, this.rowsBuffer.length)
 }else {min=min||0;max=max||this.rowsBuffer.length};for (var i = min;i < max;i++){var r = this.render_row(i)
 
 if (r == -1){if (this.xmlFileUrl){if (this.callEvent("onDynXLS",[i,(this._dpref?this._dpref:(max-i))]))
 this.load(this.xmlFileUrl+getUrlSymbol(this.xmlFileUrl)+"posStart="+i+"&count="+(this._dpref?this._dpref:(max-i)), this._data_type)};max=i;break};if (!r.parentNode||!r.parentNode.tagName){this._insertRowAt(r, i);if (r._attrs["selected"] || r._attrs["select"]){this.selectRow(r,r._attrs["call"]?true:false,true);r._attrs["selected"]=r._attrs["select"]=null}};if (this._ads_count && i-min==this._ads_count){var that=this;this._context_parsing=this._context_parsing||this._parsing;return this._contextCallTimer=window.setTimeout(function(){that._contextCallTimer=null;that.render_dataset(i,max);if (!that._contextCallTimer){if(that._context_parsing)that.callEvent("onXLE",[])
 else 
 that._fixAlterCss();that.callEvent("onDistributedEnd",[]);that._context_parsing=false}},this._ads_time)
 }};if (this._srnd&&!this._fillers)this._fillers=[this._add_filler(max, this.rowsBuffer.length-max)];this.setSizes()},
 
 render_row:function(ind){if (!this.rowsBuffer[ind])return -1;if (this.rowsBuffer[ind]._parser){var r = this.rowsBuffer[ind];if (this.rowsAr[r.idd] && this.rowsAr[r.idd].tagName=="TR")return this.rowsBuffer[ind]=this.rowsAr[r.idd];var row = this._prepareRow(r.idd);this.rowsBuffer[ind]=row;this.rowsAr[r.idd]=row;r._parser.call(this, row, r.data);this._postRowProcessing(row);return row};return this.rowsBuffer[ind]},
 
 
 _get_cell_value:function(row, ind, method){if (row._locator){if (this._c_order)ind=this._c_order[ind];return row._locator.call(this, row.data, ind)};return this.cells3(row, ind)[method ? method : "getValue"]()},

 
 sortRows:function(col, type, order){order=(order||"asc").toLowerCase();type=(type||this.fldSort[col]);col=col||0;if (this.isTreeGrid())
 this.sortTreeRows(col, type, order);else{var arrTS = {};var atype = this.cellType[col];var amet = "getValue";if (atype == "link")amet="getContent";if (atype == "dhxCalendar"||atype == "dhxCalendarA")amet="getDate";for (var i = 0;i < this.rowsBuffer.length;i++)arrTS[this.rowsBuffer[i].idd]=this._get_cell_value(this.rowsBuffer[i], col, amet);this._sortRows(col, type, order, arrTS)};this.callEvent("onAfterSorting", [col,type,order])},
 
 _sortCore:function(col, type, order, arrTS, s){var sort = "sort";if (this._sst){s["stablesort"]=this.rowsCol.stablesort;sort="stablesort"};if (type.length > 4)type=window[type];if (type == 'cus'){var cstr=this._customSorts[col];s[sort](function(a, b){return cstr(arrTS[a.idd], arrTS[b.idd], order, a.idd, b.idd)})}else if (typeof (type)== 'function'){s[sort](function(a, b){return type(arrTS[a.idd], arrTS[b.idd], order, a.idd, b.idd)})}else


 if (type == 'str'){s[sort](function(a, b){if (order == "asc")return arrTS[a.idd] > arrTS[b.idd] ? 1 : -1
 else
 return arrTS[a.idd] < arrTS[b.idd] ? 1 : -1
 })}else if (type == 'int'){s[sort](function(a, b){var aVal = parseFloat(arrTS[a.idd]);aVal=isNaN(aVal) ? -99999999999999 : aVal;var bVal = parseFloat(arrTS[b.idd]);bVal=isNaN(bVal) ? -99999999999999 : bVal;if (order == "asc")return aVal-bVal;else
 return bVal-aVal})}else if (type == 'date'){s[sort](function(a, b){var aVal = Date.parse(arrTS[a.idd])||(Date.parse("01/01/1900"));var bVal = Date.parse(arrTS[b.idd])||(Date.parse("01/01/1900"));if (order == "asc")return aVal-bVal
 else
 return bVal-aVal
 })}},
 
 _sortRows:function(col, type, order, arrTS){this._sortCore(col, type, order, arrTS, this.rowsBuffer);this._reset_view();this.callEvent("onGridReconstructed", [])},

 _reset_view:function(skip){if (!this.obj.rows[0])return;var tb = this.obj.rows[0].parentNode;var tr = tb.removeChild(tb.childNodes[0], true)
 if (_isKHTML)for (var i = tb.parentNode.childNodes.length-1;i >= 0;i--){if (tb.parentNode.childNodes[i].tagName=="TR")tb.parentNode.removeChild(tb.parentNode.childNodes[i],true)}else if (_isIE)for (var i = tb.childNodes.length-1;i >= 0;i--)tb.childNodes[i].removeNode(true);else
 tb.innerHTML="";tb.appendChild(tr)
 this.rowsCol=dhtmlxArray();if (this._sst)this.enableStableSorting(true);this._fillers=this.undefined;if (!skip){if (_isIE && this._srnd){this.render_dataset()}else
 this.render_dataset()}},
 
 
 deleteRow:function(row_id, node){if (!node)node=this.getRowById(row_id)
 
 if (!node)return;this.editStop();if (this.callEvent("onBeforeRowDeleted", [row_id])== false)
 return false;var pid=0;if (this.cellType._dhx_find("tree")!= -1 && !this._realfake){pid=this._h2.get[row_id].parent.id;this._removeTrGrRow(node)}else {if (node.parentNode)node.parentNode.removeChild(node);var ind = this.rowsCol._dhx_find(node);if (ind != -1)this.rowsCol._dhx_removeAt(ind);for (var i = 0;i < this.rowsBuffer.length;i++)if (this.rowsBuffer[i]&&this.rowsBuffer[i].idd == row_id){this.rowsBuffer._dhx_removeAt(i);ind=i;break}};this.rowsAr[row_id]=null;for (var i = 0;i < this.selectedRows.length;i++)if (this.selectedRows[i].idd == row_id)this.selectedRows._dhx_removeAt(i);if (this._srnd){for (var i = 0;i < this._fillers.length;i++){var f = this._fillers[i]
 if (!f)continue;if (f[0] >= ind)f[0]=f[0]-1;else if (f[1] >= ind)f[1]=f[1]-1};this._update_srnd_view()};if (this.pagingOn)this.changePage();if (!this._realfake)this.callEvent("onAfterRowDeleted", [row_id,pid]);this.callEvent("onGridReconstructed", []);if (this._ahgr)this.setSizes();return true},
 
 _addRow:function(new_id, text, ind){if (ind == -1|| typeof ind == "undefined")ind=this.rowsBuffer.length;if (typeof text == "string")text=text.split(this.delim);var row = this._prepareRow(new_id);row._attrs={};for (var j = 0;j < row.childNodes.length;j++)row.childNodes[j]._attrs={};this.rowsAr[row.idd]=row;if (this._h2)this._h2.get[row.idd].buff=row;this._fillRow(row, text)
 this._postRowProcessing(row)
 if (this._skipInsert){this._skipInsert=false;return this.rowsAr[row.idd]=row};if (this.pagingOn){this.rowsBuffer._dhx_insertAt(ind,row);this.rowsAr[row.idd]=row;return row};if (this._fillers){this.rowsCol._dhx_insertAt(ind, null);this.rowsBuffer._dhx_insertAt(ind,row);if (this._fake)this._fake.rowsCol._dhx_insertAt(ind, null);this.rowsAr[row.idd]=row;var found = false;for (var i = 0;i < this._fillers.length;i++){var f = this._fillers[i];if (f&&f[0] <= ind&&(f[0]+f[1])>= ind){f[1]=f[1]+1;f[2].firstChild.style.height=parseInt(f[2].firstChild.style.height)+this._srdh+"px";found=true;if (this._fake)this._fake._fillers[i][1]++};if (f&&f[0] > ind){f[0]=f[0]+1
 if (this._fake)this._fake._fillers[i][0]++}};if (!found)this._fillers.push(this._add_filler(ind, 1, (ind == 0 ? {parentNode: this.obj.rows[0].parentNode,
 nextSibling: (this.rowsCol[1])
 }: this.rowsCol[ind-1])));return row};this.rowsBuffer._dhx_insertAt(ind,row);return this._insertRowAt(row, ind)},
 
 
 addRow:function(new_id, text, ind){var r = this._addRow(new_id, text, ind);if (!this.dragContext)this.callEvent("onRowAdded", [new_id]);if (this.pagingOn)this.changePage(this.currentPage)
 
 if (this._srnd)this._update_srnd_view();r._added=true;if (this._ahgr)this.setSizes();this.callEvent("onGridReconstructed", []);return r},
 
 _insertRowAt:function(r, ind, skip){this.rowsAr[r.idd]=r;if (this._skipInsert){this._skipInsert=false;return r};if ((ind < 0)||((!ind)&&(parseInt(ind) !== 0)))
 ind=this.rowsCol.length;else {if (ind > this.rowsCol.length)ind=this.rowsCol.length};if (this._cssEven){if ((this._cssSP ? this.getLevel(r.idd): ind)%2 == 1)
 r.className+=" "+this._cssUnEven+(this._cssSU ? (" "+this._cssUnEven+"_"+this.getLevel(r.idd)) : "");else
 r.className+=" "+this._cssEven+(this._cssSU ? (" "+this._cssEven+"_"+this.getLevel(r.idd)) : "")};if (!skip)if ((ind == (this.obj.rows.length-1))||(!this.rowsCol[ind]))
 if (_isKHTML)this.obj.appendChild(r);else {this.obj.firstChild.appendChild(r)}else {this.rowsCol[ind].parentNode.insertBefore(r, this.rowsCol[ind])};this.rowsCol._dhx_insertAt(ind, r);return r},
 
 getRowById:function(id){var row = this.rowsAr[id];if (row){if (row.tagName != "TR"){for (var i = 0;i < this.rowsBuffer.length;i++)if (this.rowsBuffer[i] && this.rowsBuffer[i].idd == id)return this.render_row(i);if (this._h2)return this.render_row(null,row.idd)};return row};return null},
 

 cellById:function(row_id, col){return this.cells(row_id, col)},

 cells:function(row_id, col){if (arguments.length == 0)return this.cells4(this.cell);else
 var c = this.getRowById(row_id);var cell = (c._childIndexes ? c.childNodes[c._childIndexes[col]] : c.childNodes[col]);return this.cells4(cell)},
 
 cellByIndex:function(row_index, col){return this.cells2(row_index, col)},
 
 cells2:function(row_index, col){var c = this.render_row(row_index);var cell = (c._childIndexes ? c.childNodes[c._childIndexes[col]] : c.childNodes[col]);return this.cells4(cell)},
 
 cells3:function(row, col){var cell = (row._childIndexes ? row.childNodes[row._childIndexes[col]] : row.childNodes[col]);return this.cells4(cell)},
 
 cells4:function(cell){var type = window["eXcell_"+(cell._cellType||this.cellType[cell._cellIndex])];if (type)return new type(cell)}, 
 cells5:function(cell, type){var type = type||(cell._cellType||this.cellType[cell._cellIndex]);if (!this._ecache[type]){if (!window["eXcell_"+type])var tex = eXcell_ro;else
 var tex = window["eXcell_"+type];this._ecache[type]=new tex(cell)};this._ecache[type].cell=cell;return this._ecache[type]},
 dma:function(mode){if (!this._ecache)this._ecache={};if (mode&&!this._dma){this._dma=this.cells4;this.cells4=this.cells5}else if (!mode&&this._dma){this.cells4=this._dma;this._dma=null}},
 
 
 getRowsNum:function(){return this.rowsBuffer.length},
 
 
 
 enableEditTabOnly:function(mode){if (arguments.length > 0)this.smartTabOrder=convertStringToBoolean(mode);else
 this.smartTabOrder=true},
 
 setExternalTabOrder:function(start, end){var grid = this;this.tabStart=( typeof (start) == "object") ? start : document.getElementById(start);this.tabStart.onkeydown=function(e){var ev = (e||window.event);if (ev.keyCode == 9){ev.cancelBubble=true;grid.selectCell(0, 0, 0, 0, 1);if (grid.smartTabOrder && grid.cells2(0, 0).isDisabled()){grid._key_events["k9_0_0"].call(grid)};this.blur();return false}};if(_isOpera)this.tabStart.onkeypress = this.tabStart.onkeydown;this.tabEnd=( typeof (end) == "object") ? end : document.getElementById(end);this.tabEnd.onkeydown=this.tabEnd.onkeypress=function(e){var ev = (e||window.event);if ((ev.keyCode == 9)&&ev.shiftKey){ev.cancelBubble=true;grid.selectCell((grid.getRowsNum()-1), (grid.getColumnCount()-1), 0, 0, 1);if (grid.smartTabOrder && grid.cells2((grid.getRowsNum()-1), (grid.getColumnCount()-1)).isDisabled()){grid._key_events["k9_0_1"].call(grid)};this.blur();return false}};if(_isOpera)this.tabEnd.onkeypress = this.tabEnd.onkeydown},
 
 uid:function(){if (!this._ui_seed)this._ui_seed=(new Date()).valueOf();return this._ui_seed++},
 
 clearAndLoad:function(){var t=this._pgn_skin;this._pgn_skin=null;this.clearAll();this._pgn_skin=t;this.load.apply(this,arguments)},
 
 getStateOfView:function(){if (this.pagingOn){var start = (this.currentPage-1)*this.rowsBufferOutSize;return [this.currentPage, start, Math.min(start+this.rowsBufferOutSize,this.rowsBuffer.length), this.rowsBuffer.length ]};return [
 Math.floor(this.objBox.scrollTop/this._srdh),
 Math.ceil(parseInt(this.objBox.offsetHeight)/this._srdh),
 this.rowsBuffer.length
 ]}};(function(){function direct_set(name,value){this[name]=value};function direct_call(name,value){this[name].call(this,value)};function joined_call(name,value){this[name].call(this,value.join(this.delim))};function set_options(name,value){for (var i=0;i < value.length;i++)if (typeof value[i] == "object"){var combo = this.getCombo(i);for (var key in value[i])combo.put(key, value[i][key])}};function header_set(name,value,obj){var rows = 1;var header = [];function add(i,j,value){if (!header[j])header[j]=[];if (typeof value == "object")value.toString=function(){return this.text};header[j][i]=value};for (var i=0;i<value.length;i++){if (typeof(value[i])=="object" && value[i].length){for (var j=0;j < value[i].length;j++)add(i,j,value[i][j])}else
 add(i,0,value[i])};for (var i=0;i<header.length;i++)for (var j=0;j<header[0].length;j++){var h=header[i][j];header[i][j]=(h||"").toString()||"&nbsp;";if (h&&h.colspan)for (var k=1;k < h.colspan;k++)add(j+k,i,"#cspan");if (h&&h.rowspan)for (var k=1;k < h.rowspan;k++)add(j,i+k,"#rspan")};this.setHeader(header[0]);for (var i=1;i < header.length;i++)this.attachHeader(header[i])};var columns_map=[
 {name:"label", def:"&nbsp;", operation:"setHeader", type:header_set },
 {name:"id", def:"", operation:"columnIds", type:direct_set },
 {name:"width", def:"*", operation:"setInitWidths", type:joined_call },
 {name:"align", def:"left", operation:"cellAlign", type:direct_set },
 {name:"valign", def:"middle", operation:"cellVAlign", type:direct_set },
 {name:"sort", def:"na", operation:"fldSort", type:direct_set },
 {name:"type", def:"ro", operation:"setColTypes", type:joined_call },
 {name:"options",def:"", operation:"", type:set_options }];dhtmlx.extend_api("dhtmlXGridObject",{_init:function(obj){return [obj.parent]},
 image_path:"setImagePath",
 columns:"columns",
 rows:"rows",
 headers:"headers",
 skin:"setSkin",
 smart_rendering:"enableSmartRendering",
 css:"enableAlterCss",
 auto_height:"enableAutoHeight",
 save_hidden:"enableAutoHiddenColumnsSaving",
 save_cookie:"enableAutoSaving",
 save_size:"enableAutoSizeSaving",
 auto_width:"enableAutoWidth",
 block_selection:"enableBlockSelection",
 csv_id:"enableCSVAutoID",
 csv_header:"enableCSVHeader",
 cell_ids:"enableCellIds",
 colspan:"enableColSpan",
 column_move:"enableColumnMove",
 context_menu:"enableContextMenu",
 distributed:"enableDistributedParsing",
 drag:"enableDragAndDrop",
 drag_order:"enableDragOrder",
 tabulation:"enableEditTabOnly",
 header_images:"enableHeaderImages",
 header_menu:"enableHeaderMenu",
 keymap:"enableKeyboardSupport",
 mouse_navigation:"enableLightMouseNavigation",
 markers:"enableMarkedCells",
 math_editing:"enableMathEditing",
 math_serialization:"enableMathSerialization",
 drag_copy:"enableMercyDrag",
 multiline:"enableMultiline",
 multiselect:"enableMultiselect",
 save_column_order:"enableOrderSaving",
 hover:"enableRowsHover",
 rowspan:"enableRowspan",
 smart:"enableSmartRendering",
 save_sorting:"enableSortingSaving",
 stable_sorting:"enableStableSorting",
 undo:"enableUndoRedo",
 csv_cell:"setCSVDelimiter",
 date_format:"setDateFormat",
 drag_behavior:"setDragBehavior",
 editable:"setEditable",
 without_header:"setNoHeader",
 submit_changed:"submitOnlyChanged",
 submit_serialization:"submitSerialization",
 submit_selected:"submitOnlySelected",
 submit_id:"submitOnlyRowID", 
 xml:"load"
 },{columns:function(obj){for (var j=0;j<columns_map.length;j++){var settings = [];for (var i=0;i<obj.length;i++)settings[i]=obj[i][columns_map[j].name]||columns_map[j].def;var type=columns_map[j].type||direct_call;type.call(this,columns_map[j].operation,settings,obj)};this.init()},
 rows:function(obj){},
 headers:function(obj){for (var i=0;i < obj.length;i++)this.attachHeader(obj[i])}})})();function dhtmlXGridCellObject(obj){this.destructor=function(){this.cell.obj=null;this.cell=null;this.grid=null;this.base=null;return null};this.cell=obj;this.getValue=function(){if ((this.cell.firstChild)&&(this.cell.firstChild.tagName == "TEXTAREA"))
 return this.cell.firstChild.value;else
 return this.cell.innerHTML._dhx_trim()};this.getMathValue=function(){if (this.cell._val)return this.cell._val;else
 return this.getValue()};this.getFont=function(){arOut=new Array(3);if (this.cell.style.fontFamily)arOut[0]=this.cell.style.fontFamily

 if (this.cell.style.fontWeight == 'bold'||this.cell.parentNode.style.fontWeight == 'bold')arOut[1]='bold';if (this.cell.style.fontStyle == 'italic'||this.cell.parentNode.style.fontWeight == 'italic')arOut[1]+='italic';if (this.cell.style.fontSize)arOut[2]=this.cell.style.fontSize
 else
 arOut[2]="";return arOut.join("-")
 };this.getTextColor=function(){if (this.cell.style.color)return this.cell.style.color
 else
 return "#000000"};this.getBgColor=function(){if (this.cell.bgColor)return this.cell.bgColor
 else
 return "#FFFFFF"};this.getHorAlign=function(){if (this.cell.style.textAlign)return this.cell.style.textAlign;else if (this.cell.style.textAlign)return this.cell.style.textAlign;else
 return "left"};this.getWidth=function(){return this.cell.scrollWidth};this.setFont=function(val){fntAr=val.split("-");this.cell.style.fontFamily=fntAr[0];this.cell.style.fontSize=fntAr[fntAr.length-1]

 if (fntAr.length == 3){if (/bold/.test(fntAr[1]))
 this.cell.style.fontWeight="bold";if (/italic/.test(fntAr[1]))
 this.cell.style.fontStyle="italic";if (/underline/.test(fntAr[1]))
 this.cell.style.textDecoration="underline"}};this.setTextColor=function(val){this.cell.style.color=val};this.setBgColor=function(val){if (val == "")val=null;this.cell.bgColor=val};this.setHorAlign=function(val){if (val.length == 1){if (val == 'c')this.cell.style.textAlign='center'

 else if (val == 'l')this.cell.style.textAlign='left';else
 this.cell.style.textAlign='right'}else
 this.cell.style.textAlign=val
 };this.wasChanged=function(){if (this.cell.wasChanged)return true;else
 return false};this.isCheckbox=function(){var ch = this.cell.firstChild;if (ch&&ch.tagName == 'INPUT'){type=ch.type;if (type == 'radio'||type == 'checkbox')return true;else
 return false}else
 return false};this.isChecked=function(){if (this.isCheckbox()){return this.cell.firstChild.checked}};this.isDisabled=function(){return this.cell._disabled};this.setChecked=function(fl){if (this.isCheckbox()){if (fl != 'true'&&fl != 1)fl=false;this.cell.firstChild.checked=fl}};this.setDisabled=function(fl){if (fl != 'true'&&fl != 1)fl=false;if (this.isCheckbox()){this.cell.firstChild.disabled=fl;if (this.disabledF)this.disabledF(fl)};this.cell._disabled=fl}};dhtmlXGridCellObject.prototype={getAttribute: function(name){return this.cell._attrs[name]},
 setAttribute: function(name, value){this.cell._attrs[name]=value},
 getInput:function(){if (this.obj && (this.obj.tagName=="INPUT" || this.obj.tagName=="TEXTAREA")) return this.obj;var inps=(this.obj||this.cell).getElementsByTagName("TEXTAREA");if (!inps.length)inps=(this.obj||this.cell).getElementsByTagName("INPUT");return inps[0]}};dhtmlXGridCellObject.prototype.setValue=function(val){if (( typeof (val)!= "number")&&(!val||val.toString()._dhx_trim() == "")){val="&nbsp;"
 this.cell._clearCell=true}else
 this.cell._clearCell=false;this.setCValue(val)};dhtmlXGridCellObject.prototype.getTitle=function(){return (_isIE ? this.cell.innerText : this.cell.textContent)};dhtmlXGridCellObject.prototype.setCValue=function(val, val2){this.cell.innerHTML=val;this.grid.callEvent("onCellChanged", [
 this.cell.parentNode.idd,
 this.cell._cellIndex,
 (arguments.length > 1 ? val2 : val)
 ])};dhtmlXGridCellObject.prototype.setCTxtValue=function(val){this.cell.innerHTML="";this.cell.appendChild(document.createTextNode(val));this.grid.callEvent("onCellChanged", [
 this.cell.parentNode.idd,
 this.cell._cellIndex,
 val
 ])};dhtmlXGridCellObject.prototype.setLabel=function(val){this.cell.innerHTML=val};dhtmlXGridCellObject.prototype.getMath=function(){if (this._val)return this.val;else
 return this.getValue()};function eXcell(){this.obj=null;this.val=null;this.changeState=function(){return false
 };this.edit=function(){this.val=this.getValue()
 };this.detach=function(){return false
 };this.getPosition=function(oNode){var oCurrentNode = oNode;var iLeft = 0;var iTop = 0;while (oCurrentNode.tagName != "BODY"){iLeft+=oCurrentNode.offsetLeft;iTop+=oCurrentNode.offsetTop;oCurrentNode=oCurrentNode.offsetParent};return new Array(iLeft, iTop)}};eXcell.prototype=new dhtmlXGridCellObject;function eXcell_ed(cell){if (cell){this.cell=cell;this.grid=this.cell.parentNode.grid};this.edit=function(){this.cell.atag=((!this.grid.multiLine)&&(_isKHTML||_isMacOS||_isFF)) ? "INPUT" : "TEXTAREA";this.val=this.getValue();this.obj=document.createElement(this.cell.atag);this.obj.setAttribute("autocomplete", "off");this.obj.style.height=(this.cell.offsetHeight-(_isIE ? 4 : 4))+"px";this.obj.className="dhx_combo_edit";this.obj.wrap="soft";this.obj.style.textAlign=this.cell.style.textAlign;this.obj.onclick=function(e){(e||event).cancelBubble=true
 };this.obj.onmousedown=function(e){(e||event).cancelBubble=true
 };this.obj.value=this.val
 this.cell.innerHTML="";this.cell.appendChild(this.obj);if (_isFF){this.obj.style.overflow="visible";if ((this.grid.multiLine)&&(this.obj.offsetHeight >= 18)&&(this.obj.offsetHeight < 40)){this.obj.style.height="36px";this.obj.style.overflow="scroll"}};this.obj.onselectstart=function(e){if (!e)e=event;e.cancelBubble=true;return true};if (_isIE)this.obj.focus();this.obj.focus()
 };this.getValue=function(){if ((this.cell.firstChild)&&((this.cell.atag)&&(this.cell.firstChild.tagName == this.cell.atag)))
 return this.cell.firstChild.value;if (this.cell._clearCell)return "";return this.cell.innerHTML.toString()._dhx_trim()};this.detach=function(){this.setValue(this.obj.value);return this.val != this.getValue()}};eXcell_ed.prototype=new eXcell;function eXcell_edtxt(cell){if (cell){this.cell=cell;this.grid=this.cell.parentNode.grid};this.getValue=function(){if ((this.cell.firstChild)&&((this.cell.atag)&&(this.cell.firstChild.tagName == this.cell.atag)))
 return this.cell.firstChild.value;if (this.cell._clearCell)return "";return (_isIE ? this.cell.innerText : this.cell.textContent)};this.setValue=function(val){if (!val||val.toString()._dhx_trim() == ""){val=" ";this.cell._clearCell=true}else
 this.cell._clearCell=false;this.setCTxtValue(val)}};eXcell_edtxt.prototype=new eXcell_ed;function eXcell_edn(cell){if (cell){this.cell=cell;this.grid=this.cell.parentNode.grid};this.getValue=function(){if ((this.cell.firstChild)&&(this.cell.firstChild.tagName == "TEXTAREA"))
 return this.cell.firstChild.value;if (this.cell._clearCell)return "";return this.grid._aplNFb(this.cell.innerHTML.toString()._dhx_trim(), this.cell._cellIndex)};this.detach=function(){var tv = this.obj.value;this.setValue(tv);return this.val != this.getValue()}};eXcell_edn.prototype=new eXcell_ed;eXcell_edn.prototype.setValue=function(val){if (!val||val.toString()._dhx_trim() == ""){this.cell._clearCell=true;return this.setCValue("&nbsp;",0)}else
 this.cell._clearCell=false;this.setCValue(this.grid._aplNF(val, this.cell._cellIndex))};function eXcell_ch(cell){if (cell){this.cell=cell;this.grid=this.cell.parentNode.grid};this.disabledF=function(fl){if ((fl == true)||(fl == 1))
 this.cell.innerHTML=this.cell.innerHTML.replace("item_chk0.", "item_chk0_dis.").replace("item_chk1.",
 "item_chk1_dis.");else
 this.cell.innerHTML=this.cell.innerHTML.replace("item_chk0_dis.", "item_chk0.").replace("item_chk1_dis.",
 "item_chk1.")};this.changeState=function(){if ((!this.grid.isEditable)||(this.cell.parentNode._locked)||(this.isDisabled()))
 return;if (this.grid.callEvent("onEditCell", [
 0,
 this.cell.parentNode.idd,
 this.cell._cellIndex
 ])){this.val=this.getValue()

 if (this.val == "1")this.setValue("0")
 else
 this.setValue("1")

 this.cell.wasChanged=true;this.grid.callEvent("onEditCell", [
 1,
 this.cell.parentNode.idd,
 this.cell._cellIndex
 ]);this.grid.callEvent("onCheckbox", [
 this.cell.parentNode.idd,
 this.cell._cellIndex,
 (this.val != '1')
 ]);this.grid.callEvent("onCheck", [
 this.cell.parentNode.idd,
 this.cell._cellIndex,
 (this.val != '1')
 ])}else {this.editor=null}};this.getValue=function(){return this.cell.chstate ? this.cell.chstate.toString() : "0"};this.isCheckbox=function(){return true};this.isChecked=function(){if (this.getValue()== "1")
 return true;else
 return false};this.setChecked=function(fl){this.setValue(fl.toString())
 };this.detach=function(){return this.val != this.getValue()};this.edit=null};eXcell_ch.prototype=new eXcell;eXcell_ch.prototype.setValue=function(val){this.cell.style.verticalAlign="middle";if (val){val=val.toString()._dhx_trim();if ((val == "false")||(val == "0"))
 val=""};if (val){val="1";this.cell.chstate="1"}else {val="0";this.cell.chstate="0"
 };var obj = this;this.setCValue("<img src='"+this.grid.imgURL+"item_chk"+val
 +".gif' onclick='new eXcell_ch(this.parentNode).changeState();(arguments[0]||event).cancelBubble=true;'>",
 this.cell.chstate)};function eXcell_ra(cell){this.base=eXcell_ch;this.base(cell)
 this.grid=cell.parentNode.grid;this.disabledF=function(fl){if ((fl == true)||(fl == 1))
 this.cell.innerHTML=this.cell.innerHTML.replace("radio_chk0.", "radio_chk0_dis.").replace("radio_chk1.",
 "radio_chk1_dis.");else
 this.cell.innerHTML=this.cell.innerHTML.replace("radio_chk0_dis.", "radio_chk0.").replace("radio_chk1_dis.",
 "radio_chk1.")};this.changeState=function(mode){if (mode===false && this.getValue()==1) return;if ((!this.grid.isEditable)||(this.cell.parentNode._locked))
 return;if (this.grid.callEvent("onEditCell", [
 0,
 this.cell.parentNode.idd,
 this.cell._cellIndex
 ])!= false){this.val=this.getValue()

 if (this.val == "1")this.setValue("0")
 else
 this.setValue("1")
 this.cell.wasChanged=true;this.grid.callEvent("onEditCell", [
 1,
 this.cell.parentNode.idd,
 this.cell._cellIndex
 ]);this.grid.callEvent("onCheckbox", [
 this.cell.parentNode.idd,
 this.cell._cellIndex,
 (this.val != '1')
 ]);this.grid.callEvent("onCheck", [
 this.cell.parentNode.idd,
 this.cell._cellIndex,
 (this.val != '1')
 ])}else {this.editor=null}};this.edit=null};eXcell_ra.prototype=new eXcell_ch;eXcell_ra.prototype.setValue=function(val){this.cell.style.verticalAlign="middle";if (val){val=val.toString()._dhx_trim();if ((val == "false")||(val == "0"))
 val=""};if (val){if (!this.grid._RaSeCol)this.grid._RaSeCol=[];if (this.grid._RaSeCol[this.cell._cellIndex]){var z = this.grid.cells4(this.grid._RaSeCol[this.cell._cellIndex]);z.setValue("0")
 if (this.grid.rowsAr[z.cell.parentNode.idd])this.grid.callEvent("onEditCell", [
 1,
 z.cell.parentNode.idd,
 z.cell._cellIndex
 ])};this.grid._RaSeCol[this.cell._cellIndex]=this.cell;val="1";this.cell.chstate="1"}else {val="0";this.cell.chstate="0"
 };this.setCValue("<img src='"+this.grid.imgURL+"radio_chk"+val+".gif' onclick='new eXcell_ra(this.parentNode).changeState(false);'>",
 this.cell.chstate)};function eXcell_txt(cell){if (cell){this.cell=cell;this.grid=this.cell.parentNode.grid};this.edit=function(){this.val=this.getValue()
 this.obj=document.createElement("TEXTAREA");this.obj.className="dhx_textarea";this.obj.onclick=function(e){(e||event).cancelBubble=true
 };var arPos = this.grid.getPosition(this.cell);this.obj.value=this.val;this.obj.style.display="";this.obj.style.textAlign=this.cell.style.textAlign;if (_isFF){var z_ff = document.createElement("DIV");z_ff.appendChild(this.obj);z_ff.style.overflow="auto";z_ff.className="dhx_textarea";this.obj.style.margin="0px 0px 0px 0px";this.obj.style.border="0px";this.obj=z_ff};document.body.appendChild(this.obj);if(_isOpera)this.obj.onkeypress=function(ev){if (ev.keyCode == 9)return false};this.obj.onkeydown=function(e){var ev = (e||event);if (ev.keyCode == 9){globalActiveDHTMLGridObject.entBox.focus();globalActiveDHTMLGridObject.doKey({keyCode: ev.keyCode,
 shiftKey: ev.shiftKey,
 srcElement: "0"
 });return false}};this.obj.style.left=arPos[0]+"px";this.obj.style.top=arPos[1]+this.cell.offsetHeight+"px";if (this.cell.offsetWidth < 200)var pw = 200;else
 var pw = this.cell.offsetWidth;this.obj.style.width=pw+(_isFF ? 18 : 16)+"px"

 if (_isFF){this.obj.firstChild.style.width=parseInt(this.obj.style.width)+"px";this.obj.firstChild.style.height=this.obj.offsetHeight-3+"px"};if (_isIE){this.obj.select();this.obj.value=this.obj.value};if (_isFF)this.obj.firstChild.focus();else {this.obj.focus()
 }};this.detach=function(){var a_val = "";if (_isFF)a_val=this.obj.firstChild.value;else
 a_val=this.obj.value;if (a_val == ""){this.cell._clearCell=true}else
 this.cell._clearCell=false;this.setValue(a_val);document.body.removeChild(this.obj);this.obj=null;return this.val != this.getValue()};this.getValue=function(){if (this.obj){if (_isFF)return this.obj.firstChild.value;else
 return this.obj.value};if (this.cell._clearCell)return "";if ((!this.grid.multiLine))
 return this.cell._brval||this.cell.innerHTML;else
 return this.cell.innerHTML.replace(/<br[^>]*>/gi, "\n")._dhx_trim()}};eXcell_txt.prototype=new eXcell;function eXcell_txttxt(cell){if (cell){this.cell=cell;this.grid=this.cell.parentNode.grid};this.getValue=function(){if ((this.cell.firstChild)&&(this.cell.firstChild.tagName == "TEXTAREA"))
 return this.cell.firstChild.value;if (this.cell._clearCell)return "";if ((!this.grid.multiLine)&&this.cell._brval)
 return this.cell._brval;return (_isIE ? this.cell.innerText : this.cell.textContent)};this.setValue=function(val){this.cell._brval=val;if (!val||val.toString()._dhx_trim() == "")
 val=" ";this.setCTxtValue(val)}};eXcell_txttxt.prototype=new eXcell_txt;eXcell_txt.prototype.setValue=function(val){if (!val||val.toString()._dhx_trim() == ""){val="&nbsp;"
 this.cell._clearCell=true}else
 this.cell._clearCell=false;this.cell._brval=val;if ((!this.grid.multiLine))
 this.setCValue(val, val);else
 this.setCValue(val.replace(/\n/g, "<br/>"), val)};function eXcell_co(cell){if (cell){this.cell=cell;this.grid=this.cell.parentNode.grid;this.combo=(this.cell._combo||this.grid.getCombo(this.cell._cellIndex));this.editable=true
 };this.shiftNext=function(){var z = this.list.options[this.list.selectedIndex+1];if (z)z.selected=true;this.obj.value=this.list.options[this.list.selectedIndex].text;return true};this.shiftPrev=function(){if (this.list.selectedIndex != 0){var z = this.list.options[this.list.selectedIndex-1];if (z)z.selected=true;this.obj.value=this.list.options[this.list.selectedIndex].text};return true};this.edit=function(){this.val=this.getValue();this.text=this.getText()._dhx_trim();var arPos = this.grid.getPosition(this.cell) 

 this.obj=document.createElement("TEXTAREA");this.obj.className="dhx_combo_edit";this.obj.style.height=(this.cell.offsetHeight-4)+"px";this.obj.wrap="soft";this.obj.style.textAlign=this.cell.style.textAlign;this.obj.onclick=function(e){(e||event).cancelBubble=true
 };this.obj.value=this.text
 this.obj.onselectstart=function(e){if (!e)e=event;e.cancelBubble=true;return true};var editor_obj = this;this.obj.onkeyup=function(e){var key=(e||event).keyCode;if (key==38 || key==40 || key==9)return;var val = this.readonly ? String.fromCharCode(key) : this.value;var c = editor_obj.list.options;for (var i = 0;i < c.length;i++)if (c[i].text.indexOf(val)== 0)
 return c[i].selected=true};this.list=document.createElement("SELECT");this.list.className='dhx_combo_select';this.list.style.width=this.cell.offsetWidth+"px";this.list.style.left=arPos[0]+"px";this.list.style.top=arPos[1]+this.cell.offsetHeight+"px";this.list.onclick=function(e){var ev = e||window.event;var cell = ev.target||ev.srcElement

 
 if (cell.tagName == "OPTION")cell=cell.parentNode;editor_obj.editable=false;editor_obj.grid.editStop()};var comboKeys = this.combo.getKeys();var fl = false
 var selOptId = 0;for (var i = 0;i < comboKeys.length;i++){var val = this.combo.get(comboKeys[i])
 this.list.options[this.list.options.length]=new Option(val, comboKeys[i]);if (comboKeys[i] == this.val){selOptId=this.list.options.length-1;fl=true}};if (fl == false){this.list.options[this.list.options.length]=new Option(this.text, this.val === null ? "" : this.val);selOptId=this.list.options.length-1};document.body.appendChild(this.list) 
 this.list.size="6";this.cstate=1;if (this.editable){this.cell.innerHTML=""}else {this.obj.style.width="1px";this.obj.style.height="1px"};this.cell.appendChild(this.obj);this.list.options[selOptId].selected=true;if ((!_isFF)||(this.editable)){this.obj.focus();this.obj.focus()};if (!this.editable){this.obj.style.visibility="hidden";this.list.focus();this.list.onkeydown=function(e){e=e||window.event;editor_obj.grid.setActive(true)

 if (e.keyCode < 30)return editor_obj.grid.doKey({target: editor_obj.cell,
 keyCode: e.keyCode,
 shiftKey: e.shiftKey,
 ctrlKey: e.ctrlKey
 })
 }}};this.getValue=function(){return ((this.cell.combo_value == window.undefined) ? "" : this.cell.combo_value)};this.detach=function(){if (this.val != this.getValue()){this.cell.wasChanged=true};if (this.list.parentNode != null){if (this.editable){var ind = this.list.options[this.list.selectedIndex]
 if (ind&&ind.text == this.obj.value)this.setValue(this.list.value)
 else{var combo=(this.cell._combo||this.grid.getCombo(this.cell._cellIndex));var val=combo.values._dhx_find(this.obj.value);if (val!=-1)this.setValue(combo.keys[val]);else this.setCValue(this.cell.combo_value=this.obj.value)}}else
 this.setValue(this.list.value)
 };if (this.list.parentNode)this.list.parentNode.removeChild(this.list);if (this.obj.parentNode)this.obj.parentNode.removeChild(this.obj);return this.val != this.getValue()}};eXcell_co.prototype=new eXcell;eXcell_co.prototype.getText=function(){return this.cell.innerHTML};eXcell_co.prototype.setValue=function(val){if (typeof (val)== "object"){var optCol = this.grid.xmlLoader.doXPath("./option", val);if (optCol.length)this.cell._combo=new dhtmlXGridComboObject();for (var j = 0;j < optCol.length;j++)this.cell._combo.put(optCol[j].getAttribute("value"),
 optCol[j].firstChild
 ? optCol[j].firstChild.data
 : "");val=val.firstChild.data};if ((val||"").toString()._dhx_trim() == "")
 val=null
 this.cell.combo_value=val;if (val !== null)this.setCValue((this.cell._combo||this.grid.getCombo(this.cell._cellIndex)).get(val)||val, val);else
 this.setCValue("&nbsp;", val)};function eXcell_coro(cell){this.base=eXcell_co;this.base(cell)
 this.editable=false};eXcell_coro.prototype=new eXcell_co;function eXcell_cotxt(cell){this.base=eXcell_co;this.base(cell)
};eXcell_cotxt.prototype=new eXcell_co;eXcell_cotxt.prototype.getText=function(){return (_isIE ? this.cell.innerText : this.cell.textContent)};eXcell_cotxt.prototype.setValue=function(val){if (typeof (val)== "object"){var optCol = this.grid.xmlLoader.doXPath("./option", val);if (optCol.length)this.cell._combo=new dhtmlXGridComboObject();for (var j = 0;j < optCol.length;j++)this.cell._combo.put(optCol[j].getAttribute("value"),
 optCol[j].firstChild
 ? optCol[j].firstChild.data
 : "");val=val.firstChild.data};if ((val||"").toString()._dhx_trim() == "")
 val=null

 if (val !== null)this.setCTxtValue((this.cell._combo||this.grid.getCombo(this.cell._cellIndex)).get(val)||val, val);else
 this.setCTxtValue(" ", val);this.cell.combo_value=val};function eXcell_corotxt(cell){this.base=eXcell_co;this.base(cell)
 this.editable=false};eXcell_corotxt.prototype=new eXcell_cotxt;function eXcell_cp(cell){try{this.cell=cell;this.grid=this.cell.parentNode.grid}catch (er){};this.edit=function(){this.val=this.getValue()
 this.obj=document.createElement("SPAN");this.obj.style.border="1px solid black";this.obj.style.position="absolute";var arPos = this.grid.getPosition(this.cell);this.colorPanel(4, this.obj)
 document.body.appendChild(this.obj);this.obj.style.left=arPos[0]+"px";this.obj.style.top=arPos[1]+this.cell.offsetHeight+"px"};this.toolDNum=function(value){if (value.length == 1)value='0'+value;return value};this.colorPanel=function(index, parent){var tbl = document.createElement("TABLE");parent.appendChild(tbl)
 tbl.cellSpacing=0;tbl.editor_obj=this;tbl.style.cursor="default";tbl.onclick=function(e){var ev = e||window.event
 var cell = ev.target||ev.srcElement;var ed = cell.parentNode.parentNode.parentNode.editor_obj
 ed.setValue(cell._bg)
 ed.grid.editStop()};var cnt = 256 / index;for (var j = 0;j <= (256 / cnt);j++){var r = tbl.insertRow(j);for (var i = 0;i <= (256 / cnt);i++){for (var n = 0;n <= (256 / cnt);n++){R=new Number(cnt*j)-(j == 0 ? 0 : 1)
 G=new Number(cnt*i)-(i == 0 ? 0 : 1)
 B=new Number(cnt*n)-(n == 0 ? 0 : 1)
 var rgb =
 this.toolDNum(R.toString(16))+""+this.toolDNum(G.toString(16))+""+this.toolDNum(B.toString(16));var c = r.insertCell(i);c.width="10px";c.innerHTML="&nbsp;";c.title=rgb.toUpperCase()
 c.style.backgroundColor="#"+rgb
 c._bg="#"+rgb;if (this.val != null&&"#"+rgb.toUpperCase()== this.val.toUpperCase()){c.style.border="2px solid white"
 }}}}};this.getValue=function(){return this.cell.firstChild._bg||""};this.getRed=function(){return Number(parseInt(this.getValue().substr(1, 2), 16))
 };this.getGreen=function(){return Number(parseInt(this.getValue().substr(3, 2), 16))
 };this.getBlue=function(){return Number(parseInt(this.getValue().substr(5, 2), 16))
 };this.detach=function(){if (this.obj.offsetParent != null)document.body.removeChild(this.obj);return this.val != this.getValue()}};eXcell_cp.prototype=new eXcell;eXcell_cp.prototype.setValue=function(val){this.setCValue("<div style='width:100%;height:"+((this.grid.multiLine?cell.offsetHeight-2:16))+";background-color:"+(val||"")
 +";border:0px;'>&nbsp;</div>",
 val);this.cell.firstChild._bg=val};function eXcell_img(cell){try{this.cell=cell;this.grid=this.cell.parentNode.grid}catch (er){};this.getValue=function(){if (this.cell.firstChild.tagName == "IMG")return this.cell.firstChild.src+(this.cell.titFl != null
 ? "^"+this.cell._brval
 : "");else if (this.cell.firstChild.tagName == "A"){var out = this.cell.firstChild.firstChild.src+(this.cell.titFl != null ? "^"+this.cell._brval : "");out+="^"+this.cell.lnk;if (this.cell.trg)out+="^"+this.cell.trg
 return out}};this.isDisabled=function(){return true}};eXcell_img.prototype=new eXcell;eXcell_img.prototype.getTitle=function(){return this.cell._brval
};eXcell_img.prototype.setValue=function(val){var title = val;if (val.indexOf("^")!= -1){var ar = val.split("^");val=ar[0]
 title=this.cell._attrs.title||ar[1];if (ar.length > 2){this.cell.lnk=ar[2]

 if (ar[3])this.cell.trg=ar[3]
 };this.cell.titFl="1"};this.setCValue("<img src='"+this.grid.iconURL+(val||"")._dhx_trim()+"' border='0'>", val);if (this.cell.lnk){this.cell.innerHTML="<a href='"+this.cell.lnk+"' target='"+this.cell.trg+"'>"+this.cell.innerHTML+"</a>"
 };this.cell._brval=title};function eXcell_price(cell){this.base=eXcell_ed;this.base(cell)
 this.getValue=function(){if (this.cell.childNodes.length > 1)return this.cell.childNodes[1].innerHTML.toString()._dhx_trim()
 else
 return "0"}};eXcell_price.prototype=new eXcell_ed;eXcell_price.prototype.setValue=function(val){if (isNaN(parseFloat(val))){val=this.val||0};var color = "green";if (val < 0)color="red";this.setCValue("<span>$</span><span style='padding-right:2px;color:"+color+";'>"+val+"</span>", val)};function eXcell_dyn(cell){this.base=eXcell_ed;this.base(cell)
 this.getValue=function(){return this.cell.firstChild.childNodes[1].innerHTML.toString()._dhx_trim()
 }};eXcell_dyn.prototype=new eXcell_ed;eXcell_dyn.prototype.setValue=function(val){if (!val||isNaN(Number(val))){if (val!=="")val=0};if (val > 0){var color = "green";var img = "dyn_up.gif"}else if (val == 0){var color = "black";var img = "dyn_.gif"}else {var color = "red";var img = "dyn_down.gif"};this.setCValue("<div style='position:relative;padding-right:2px;width:100%;overflow:hidden;white-space:nowrap;'><img src='"+this.grid.imgURL+""+img
 +"' height='15' style='position:absolute;top:0px;left:0px;'><span style=' padding-left:20px;width:100%;color:"+color+";'>"+val
 +"</span></div>",
 val)};function eXcell_ro(cell){if (cell){this.cell=cell;this.grid=this.cell.parentNode.grid};this.edit=function(){};this.isDisabled=function(){return true};this.getValue=function(){return this.cell._clearCell?"":this.cell.innerHTML.toString()._dhx_trim()}};eXcell_ro.prototype=new eXcell;function eXcell_ron(cell){this.cell=cell;this.grid=this.cell.parentNode.grid;this.edit=function(){};this.isDisabled=function(){return true};this.getValue=function(){return this.cell._clearCell?"":this.grid._aplNFb(this.cell.innerHTML.toString()._dhx_trim(), this.cell._cellIndex)}};eXcell_ron.prototype=new eXcell;eXcell_ron.prototype.setValue=function(val){if (val === 0){}else if (!val||val.toString()._dhx_trim() == ""){this.setCValue("&nbsp;");return this.cell._clearCell=true};this.cell._clearCell=false;this.setCValue(val?this.grid._aplNF(val, this.cell._cellIndex):"0")};function eXcell_rotxt(cell){this.cell=cell;this.grid=this.cell.parentNode.grid;this.edit=function(){};this.isDisabled=function(){return true};this.setValue=function(val){if (!val||val.toString()._dhx_trim() == ""){val=" ";this.cell._clearCell = true}else
 this.cell._clearCell = false;this.setCTxtValue(val)};this.getValue=function(){if (this.cell._clearCell)return "";return (_isIE ? this.cell.innerText : this.cell.textContent)}};eXcell_rotxt.prototype=new eXcell;function dhtmlXGridComboObject(){this.keys=new dhtmlxArray();this.values=new dhtmlxArray();this.put=function(key, value){for (var i = 0;i < this.keys.length;i++){if (this.keys[i] == key){this.values[i]=value;return true}};this.values[this.values.length]=value;this.keys[this.keys.length]=key};this.get=function(key){for (var i = 0;i < this.keys.length;i++){if (this.keys[i] == key){return this.values[i]}};return null};this.clear=function(){this.keys=new dhtmlxArray();this.values=new dhtmlxArray()};this.remove=function(key){for (var i = 0;i < this.keys.length;i++){if (this.keys[i] == key){this.keys._dhx_removeAt(i);this.values._dhx_removeAt(i);return true}}};this.size=function(){var j = 0;for (var i = 0;i < this.keys.length;i++){if (this.keys[i] != null)j++};return j};this.getKeys=function(){var keyAr = new Array(0);for (var i = 0;i < this.keys.length;i++){if (this.keys[i] != null)keyAr[keyAr.length]=this.keys[i]};return keyAr};this.save=function(){this._save=new Array();for (var i = 0;i < this.keys.length;i++)this._save[i]=[
 this.keys[i],
 this.values[i]
 ]};this.restore=function(){if (this._save){this.keys[i]=new Array();this.values[i]=new Array();for (var i = 0;i < this._save.length;i++){this.keys[i]=this._save[i][0];this.values[i]=this._save[i][1]}}};return this};function Hashtable(){this.keys=new dhtmlxArray();this.values=new dhtmlxArray();return this};Hashtable.prototype=new dhtmlXGridComboObject;dhtmlXGridObject.prototype._process_json_row=function(r, data){r._attrs=data;for (var j = 0;j < r.childNodes.length;j++)r.childNodes[j]._attrs={};if (data.userdata)for (var a in data.userdata)this.setUserData(r.idd,a,data.userdata[a])
 
 for (var i=0;i<data.data.length;i++)if (typeof data.data[i] == "object"){r.childNodes[i]._attrs=data.data[i];if (data.data[i].type)r.childNodes[i]._cellType=data.data[i].type;data.data[i]=data.data[i].value};this._fillRow(r, (this._c_order ? this._swapColumns(data.data) : data.data));return r};dhtmlXGridObject.prototype._process_json=function(data){this._parsing=true;try {if (data&&data.xmlDoc)eval("data="+data.xmlDoc.responseText+";");else if (typeof data == "string")eval("data="+data+";")}catch(e){dhtmlxError.throwError("LoadXML", "Incorrect JSON", [
 (data.xmlDoc||data),
 this
 ]);data = {rows:[]}};var cr = parseInt(data.pos||0);var total = parseInt(data.total_count||0);if (total&&!this.rowsBuffer[total-1])this.rowsBuffer[total-1]=null;if (this.isTreeGrid())
 return this._process_tree_json(data);for (var i = 0;i < data.rows.length;i++){if (this.rowsBuffer[i+cr])continue;var id = data.rows[i].id;this.rowsBuffer[i+cr]={idd: id,
 data: data.rows[i],
 _parser: this._process_json_row,
 _locator: this._get_json_data
 };this.rowsAr[id]=data[i]};this.render_dataset();this._parsing=false};dhtmlXGridObject.prototype._process_tree_json=function(data,top,pid){this._parsing=true;var main=false;if (!top){this.render_row=this.render_row_tree;main=true;top=data;pid=top.parent||0;if (pid=="0")pid=0;if (!this._h2)this._h2=new dhtmlxHierarchy();if (this._fake)this._fake._h2=this._h2};if (top.rows)for (var i = 0;i < top.rows.length;i++){var id = top.rows[i].id;var row=this._h2.add(id,pid);row.buff={idd:id, data:top.rows[i], _parser: this._process_json_row, _locator:this._get_json_data };if (top.rows[i].open)row.state="minus";this.rowsAr[id]=row.buff;this._process_tree_json(top.rows[i],top.rows[i],id)};if (main){if (pid!=0)this._h2.change(pid,"state","minus")
 this._updateTGRState(this._h2.get[pid]);this._h2_to_buff();this.render_dataset();if (this._slowParse===false){this.forEachRow(function(id){this.render_row_tree(0,id)
 })
 };this._parsing=false}};dhtmlXGridObject.prototype.filterBy=function(column, value, preserve){if (this.isTreeGrid()) return this.filterTreeBy(column, value, preserve);if (this._f_rowsBuffer){if (!preserve){this.rowsBuffer=dhtmlxArray([].concat(this._f_rowsBuffer));if (this._fake)this._fake.rowsBuffer=this.rowsBuffer}}else
 this._f_rowsBuffer=[].concat(this.rowsBuffer);if (!this.rowsBuffer.length)return;var d=true;this.dma(true)
 if (typeof(column)=="object")
 for (var j=0;j<value.length;j++)this._filterA(column[j],value[j]);else
 this._filterA(column,value);this.dma(false)
 if (this.pagingOn && this.rowsBuffer.length/this.rowsBufferOutSize < (this.currentPage-1)) this.changePage(0);this._reset_view();this.callEvent("onGridReconstructed",[])
};dhtmlXGridObject.prototype._filterA=function(column,value){if (value=="")return;var d=true;if (typeof(value)=="function") d=false;else value=(value||"").toString().toLowerCase();if (!this.rowsBuffer.length)return;for (var i=this.rowsBuffer.length-1;i>=0;i--)if (d?(this._get_cell_value(this.rowsBuffer[i],column).toString().toLowerCase().indexOf(value)==-1):(!value(this._get_cell_value(this.rowsBuffer[i],column),this.rowsBuffer[i].idd)))
 this.rowsBuffer.splice(i,1)};dhtmlXGridObject.prototype.getFilterElement=function(index){if (!this.filters)return;for (var i=0;i < this.filters.length;i++){if (this.filters[i][1]==index)return (this.filters[i][0].combo||this.filters[i][0])};return null};dhtmlXGridObject.prototype.collectValues=function(column){var value=this.callEvent("onCollectValues",[column]);if (value!==true)return value;if (this.isTreeGrid()) return this.collectTreeValues(column);this.dma(true)
 column=this._m_order?this._m_order[column]:column;var c={};var f=[];this._build_m_order();var col=this._f_rowsBuffer||this.rowsBuffer;for (var i=0;i<col.length;i++){var val=this._get_cell_value(col[i],column);if (val && (!col[i]._childIndexes || col[i]._childIndexes[column]!=col[i]._childIndexes[column-1])) c[val]=true};this.dma(false)
 
 var vals=this.combos[column];for (d in c)if (c[d]===true)f.push(vals?(vals.get(d)||d):d);return f.sort()};dhtmlXGridObject.prototype._build_m_order=function(){if (this._c_order){this._m_order=[]
 for (var i=0;i < this._c_order.length;i++){this._m_order[this._c_order[i]]=i}}};dhtmlXGridObject.prototype.filterByAll=function(){var a=[];var b=[];this._build_m_order();for (var i=0;i<this.filters.length;i++){var ind=this._m_order?this._m_order[this.filters[i][1]]:this.filters[i][1];b.push(ind);var val=this.filters[i][0]._filter?this.filters[i][0]._filter():this.filters[i][0].value;var vals;if (typeof val != "function" && (vals=this.combos[ind])){ind=vals.values._dhx_find(val);val=(ind==-1)?val:vals.keys[ind]};a.push(val)};if (!this.callEvent("onFilterStart",[b,a])) return;this.filterBy(b,a);if (this._cssEven)this._fixAlterCss();this.callEvent("onFilterEnd",[this.filters])};dhtmlXGridObject.prototype.makeFilter=function(id,column,preserve){if (!this.filters)this.filters=[];if (typeof(id)!="object")
 id=document.getElementById(id);if(!id)return;var self=this;if (!id.style.width)id.style.width = "90%";if (id.tagName=='SELECT'){this.filters.push([id,column]);this._loadSelectOptins(id,column);id.onchange=function(){self.filterByAll()};if(_isIE)id.style.marginTop="1px";this.attachEvent("onEditCell",function(stage,a,ind){this._build_m_order();if (stage==2 && this.filters && ( this._m_order?(ind==this._m_order[column]):(ind==column) ))
 this._loadSelectOptins(id,column);return true})}else if (id.tagName=='INPUT'){this.filters.push([id,column]);id.value='';id.onkeydown=function(){if (this._timer)window.clearTimeout(this._timer);this._timer=window.setTimeout(function(){if (id.value != id.old_value){self.filterByAll();id.old_value=id.value}},500)}}else if (id.tagName=='DIV' && id.className=="combo"){this.filters.push([id,column]);id.style.padding="0px";id.style.margin="0px";if (!window.dhx_globalImgPath)window.dhx_globalImgPath=this.imgURL;var z=new dhtmlXCombo(id,"_filter","90%");z.filterSelfA=z.filterSelf;z.filterSelf=function(){if (this.getSelectedIndex()==0) this.setComboText("");this.filterSelfA.apply(this,arguments);this.optionsArr[0].hide(false)};z.enableFilteringMode(true);id.combo=z;id.value="";this._loadComboOptins(id,column);z.attachEvent("onChange",function(){id.value=z.getSelectedValue();self.filterByAll()})};if (id.parentNode)id.parentNode.className+=" filter";this._filters_ready()};dhtmlXGridObject.prototype.findCell=function(value, c_ind, count){var res = new Array();value=value.toString().toLowerCase();if (typeof count != "number")count = count?1:0;if (!this.rowsBuffer.length)return res;for (var i = (c_ind||0);i < this._cCount;i++){if (this._h2)this._h2.forEachChild(0,function(el){if (count && res.length==count)return res;if (this._get_cell_value(el.buff,i).toString().toLowerCase().indexOf(value) != -1){res.push([el.id,i])}},this)
 else
 for (var j=0;j < this.rowsBuffer.length;j++)if (this._get_cell_value(this.rowsBuffer[j],i).toString().toLowerCase().indexOf(value) != -1){res.push([this.rowsBuffer[j].idd,i]);if (count && res.length==count)return res};if (typeof (c_ind)!= "undefined")
 return res};return res};dhtmlXGridObject.prototype.makeSearch=function(id,column){if (typeof(id)!="object")
 id=document.getElementById(id);if(!id)return;var self=this;if (id.tagName=='INPUT'){id.onkeypress=function(){if (this._timer)window.clearTimeout(this._timer);this._timer=window.setTimeout(function(){if (id.value=="")return;var z=self.findCell(id.value,column,true);if (z.length){if (self._h2)self.openItem(z[0][0]);self.selectCell(self.getRowIndex(z[0][0]),(column||0))
 }},500)}};if (id.parentNode)id.parentNode.className+=" filter"};dhtmlXGridObject.prototype._loadSelectOptins=function(t,c){var l=this.collectValues(c);var v=t.value;t.innerHTML="";t.options[0]=new Option("","");var f=this._filter_tr?this._filter_tr[c]:null;for (var i=0;i<l.length;i++)t.options[t.options.length]=new Option(f?f(l[i]):l[i],l[i]);t.value=v};dhtmlXGridObject.prototype.setSelectFilterLabel=function(ind,fun){if (!this._filter_tr)this._filter_tr=[];this._filter_tr[ind]=fun};dhtmlXGridObject.prototype._loadComboOptins=function(t,c){var l=this.collectValues(c);t.combo.clearAll();t.combo.render(false);t.combo.addOption("","&nbsp;");for (var i=0;i<l.length;i++)t.combo.addOption(l[i],l[i]);t.combo.render(true)};dhtmlXGridObject.prototype.refreshFilters=function(){for (var i=0;i<this.filters.length;i++){switch(this.filters[i][0].tagName.toLowerCase()){case "input":
 break;case "select":
 this._loadSelectOptins.apply(this,this.filters[i]);break;case "div":
 this._loadComboOptins.apply(this,this.filters[i]);break}}};dhtmlXGridObject.prototype._filters_ready=function(fl,code){this.attachEvent("onXLE",this.refreshFilters);this.attachEvent("onRowCreated",function(id,r){if (this._f_rowsBuffer)for (var i=0;i<this._f_rowsBuffer.length;i++)if (this._f_rowsBuffer[i].idd == id)return this._f_rowsBuffer[i]=r})
 this.attachEvent("onClearAll",function(){this._f_rowsBuffer=null;if (!this.obj.rows.length)this.filters=[]});if (window.dhtmlXCombo)this.attachEvent("onScroll",dhtmlXCombo.prototype.closeAll);this._filters_ready=function(){}};dhtmlXGridObject.prototype._in_header_text_filter=function(t,i){t.innerHTML="<input type='text' style='width:90%;font-size:8pt;font-family:Tahoma;-moz-user-select:text;'>";t.onclick=t.onmousedown = function(e){(e||event).cancelBubble=true;return true};t.onselectstart=function(){return (event.cancelBubble=true)};this.makeFilter(t.firstChild,i)};dhtmlXGridObject.prototype._in_header_text_filter_inc=function(t,i){t.innerHTML="<input type='text' style='width:90%;font-size:8pt;font-family:Tahoma;-moz-user-select:text;'>";t.onclick=t.onmousedown = function(e){(e||event).cancelBubble=true;return true};t.onselectstart=function(){return (event.cancelBubble=true)};this.makeFilter(t.firstChild,i);t.firstChild._filter=function(){return function(val){return (val.toString().toLowerCase().indexOf(t.firstChild.value.toLowerCase())==0)}};this._filters_ready()};dhtmlXGridObject.prototype._in_header_select_filter=function(t,i){t.innerHTML="<select style='width:90%;font-size:8pt;font-family:Tahoma;'></select>";t.onclick=function(e){(e||event).cancelBubble=true;return false};this.makeFilter(t.firstChild,i)};dhtmlXGridObject.prototype._in_header_select_filter_strict=function(t,i){t.innerHTML="<select style='width:90%;font-size:8pt;font-family:Tahoma;'></select>";t.onclick=function(e){(e||event).cancelBubble=true;return false};this.makeFilter(t.firstChild,i);t.firstChild._filter=function(){return function(val){if (t.firstChild.value.toLowerCase()== "") return true;return (val.toString().toLowerCase()==t.firstChild.value.toLowerCase())}};this._filters_ready()};dhtmlXGridObject.prototype._in_header_combo_filter=function(t,i){t.innerHTML="<div style='width:100%;padding-left:2px;overflow:hidden;font-size:8pt;font-family:Tahoma;-moz-user-select:text;' class='combo'></div>";t.onselectstart=function(){return (event.cancelBubble=true)};t.onclick=t.onmousedown=function(e){(e||event).cancelBubble=true;return true};this.makeFilter(t.firstChild,i)};dhtmlXGridObject.prototype._in_header_text_search=function(t,i){t.innerHTML="<input type='text' style='width:90%;font-size:8pt;font-family:Tahoma;-moz-user-select:text;'>";t.onclick= t.onmousedown = function(e){(e||event).cancelBubble=true;return true};t.onselectstart=function(){return (event.cancelBubble=true)};this.makeSearch(t.firstChild,i)};dhtmlXGridObject.prototype._in_header_numeric_filter=function(t,i){this._in_header_text_filter.call(this,t,i);t.firstChild._filter=function(){var v=this.value;var r;var op="==";var num=parseFloat(v.replace("=",""));var num2=null;if (v){if (v.indexOf("..")!=-1){v=v.split("..");num=parseFloat(v[0]);num2=parseFloat(v[1]);return function(v){if (v>=num && v<=num2)return true;return false}};r=v.match(/>|>=|<=|</)
 if (r){op=r[0];num=parseFloat(v.replace(op,""))};return Function("v"," if (v "+op+" "+num+" )return true;return false;")}}};dhtmlXGridObject.prototype._in_header_master_checkbox=function(t,i,c){t.innerHTML=c[0]+"<input type='checkbox' />"+c[1];var self=this;t.firstChild.onclick=function(e){self._build_m_order();var j=self._m_order?self._m_order[i]:i;var val=this.checked?1:0;self.forEachRowA(function(id){var c=this.cells(id,j);if (c.isCheckbox()) c.setValue(val)});(e||event).cancelBubble=true}};dhtmlXGridObject.prototype._in_header_stat_total=function(t,i,c){var calck=function(){var summ=0;for (var j=0;j<this.rowsBuffer.length;j++){var v=parseFloat(this._get_cell_value(this.rowsBuffer[j],i));summ+=isNaN(v)?0:v};return this._maskArr[i]?this._aplNF(summ,i):(Math.round(summ*100)/100)};this._stat_in_header(t,calck,i,c,c)};dhtmlXGridObject.prototype._in_header_stat_multi_total=function(t,i,c){var cols=c[1].split(":");c[1]="";for(var k = 0;k < cols.length;k++){cols[k]=parseInt(cols[k])};var calck=function(){var summ=0;for (var j=0;j<this.rowsBuffer.length;j++){var v = 1;for(var k = 0;k < cols.length;k++){v *= parseFloat(this._get_cell_value(this.rowsBuffer[j],cols[k]))
 };summ+=isNaN(v)?0:v};return this._maskArr[i]?this._aplNF(summ,i):(Math.round(summ*100)/100)};var track=[];for(var i = 0;i < cols.length;i++){track[cols[i]]=true};this._stat_in_header(t,calck,track,c,c)};dhtmlXGridObject.prototype._in_header_stat_max=function(t,i,c){var calck=function(){var summ=-999999999;if (this.getRowsNum()==0) return "&nbsp;";for (var j=0;j<this.rowsBuffer.length;j++)summ=Math.max(summ,parseFloat(this._get_cell_value(this.rowsBuffer[j],i)));return this._maskArr[i]?this._aplNF(summ,i):summ};this._stat_in_header(t,calck,i,c)};dhtmlXGridObject.prototype._in_header_stat_min=function(t,i,c){var calck=function(){var summ=999999999;if (this.getRowsNum()==0) return "&nbsp;";for (var j=0;j<this.rowsBuffer.length;j++)summ=Math.min(summ,parseFloat(this._get_cell_value(this.rowsBuffer[j],i)));return this._maskArr[i]?this._aplNF(summ,i):summ};this._stat_in_header(t,calck,i,c)};dhtmlXGridObject.prototype._in_header_stat_average=function(t,i,c){var calck=function(){var summ=0;var count=0;if (this.getRowsNum()==0) return "&nbsp;";for (var j=0;j<this.rowsBuffer.length;j++){var v=parseFloat(this._get_cell_value(this.rowsBuffer[j],i));summ+=isNaN(v)?0:v;count++};return this._maskArr[i]?this._aplNF(summ/count,i):(Math.round(summ/count*100)/100)};this._stat_in_header(t,calck,i,c)};dhtmlXGridObject.prototype._in_header_stat_count=function(t,i,c){var calck=function(){return this.getRowsNum()};this._stat_in_header(t,calck,i,c)};dhtmlXGridObject.prototype._stat_in_header=function(t,calck,i,c){var that=this;var f=function(){this.dma(true)
 t.innerHTML=(c[0]?c[0]:"")+calck.call(this)+(c[1]?c[1]:"");this.dma(false)
 this.callEvent("onStatReady",[])
 };if (!this._stat_events){this._stat_events=[];this.attachEvent("onClearAll",function(){if (!this.hdr.rows[1]){for (var i=0;i<this._stat_events.length;i++)for (var j=0;j < 4;j++)this.detachEvent(this._stat_events[i][j]);this._stat_events=[]}})
 };this._stat_events.push([
 this.attachEvent("onGridReconstructed",f),
 this.attachEvent("onXLE",f),
 this.attachEvent("onFilterEnd",f),
 this.attachEvent("onEditCell",function(stage,id,ind){if (stage==2 && ( ind==i || ( i && i[ind])) ) f.call(this);return true})]);t.innerHTML=""};dhtmlXGridObject.prototype.unGroup=function(){if (!this._groups)return;this._dndProblematic=false;delete this._groups;delete this._gIndex;if (this._fake)this._mirror_rowsCol();this.forEachRow(function(id){this.rowsAr[id].style.display=''})
 this._reset_view();this.callEvent("onGridReconstructed",[])
 this.callEvent("onUnGroup",[])};dhtmlXGridObject.prototype._mirror_rowsCol=function(){this._fake._groups=this._groups;this._fake._gIndex=this._gIndex;this.rowsBuffer=dhtmlxArray();for (var i=0;i<this.rowsCol.length;i++)if (!this.rowsCol[i]._cntr)this.rowsBuffer.push(this.rowsCol[i]);this._fake.rowsBuffer=dhtmlxArray();for (var i=0;i<this._fake.rowsCol.length;i++)if (!this._fake.rowsCol[i]._cntr)this._fake.rowsBuffer.push(this._fake.rowsCol[i])};dhtmlXGridObject.prototype.groupBy=function(ind,mask){if (this._groups)this.unGroup();this._dndProblematic=true;this._groups={};if (!mask){mask=["#title"];for (var i=1;i<this._cCount;i++)mask.push("#cspan")};this._gmask=document.createElement("TR");this._gmask.origin = mask;var ltd,rindex=0;for (var i=0;i<mask.length;i++){if (mask[i]=="#cspan")ltd.colSpan=(parseInt(ltd.colSpan)||1)+1
 else {ltd=document.createElement("TD");ltd._cellIndex=i;if (this._hrrar[i] && !this._fake)ltd.style.display="none";ltd.className="group_row";ltd.innerHTML="&nbsp;";if (mask[i]=="#title")this._gmask._title=rindex;else ltd.align=this.cellAlign[i]||"left";this._gmask.appendChild(ltd);if (mask[i].indexOf("#stat")==0){this._gmask._math=true;ltd._counter=[this["_g_"+mask[i].replace("#","")],i,rindex]};rindex++}};for (var a in this._groups)this._groups[a]=this.undefined;this._gIndex=ind;if (this._fake &&!this._realfake){this._fake._groups=[];this._fake._gIndex=this._gIndex};this._nextRow=function(ind,dir){var r=this.rowsCol[ind+dir];if (r && ( r.style.display=="none" || r._cntr)) return this._nextRow(ind+dir,dir);return r};if (!this.__sortRowsBG){this._key_events=dhtmlXHeir({},this._key_events)
 this._key_events.k38_0_0=function(){if (this.editor && this.editor.combo)this.editor.shiftPrev();else{var rowInd = this.row.rowIndex;if (!rowInd)return;var nrow=this._nextRow(rowInd-1,-1);if (nrow)this.selectCell(nrow,this.cell._cellIndex,true)}};this._key_events.k13_1_0=this._key_events.k13_0_1=function(){};this._key_events.k40_0_0=function(){if (this.editor && this.editor.combo)this.editor.shiftNext();else{var rowInd = this.row.rowIndex;if (!rowInd)return;var nrow=this._nextRow(rowInd-1,1);if (nrow)this.selectCell(nrow,this.cell._cellIndex,true)}};this.attachEvent("onFilterStart",function(){if (this._groups)this._groups=this.undefined;return true});this.attachEvent("onFilterEnd",function(){if (typeof this._gIndex != "undefined")this.groupBy(this._gIndex,this._gmask.origin)});this.sortRows_bg=this.sortRows;this.sortRows=function(ind,type,dir){if (typeof(this._groups)=="undefined") return this.sortRows_bg.apply(this,arguments);this.callEvent("onBeforeSorting",[ind,(type||"str"),(dir||"asc")])};this.attachEvent("onBeforeSorting",function(ind,type,dir){if (typeof(this._groups)=="undefined") return true;if (ind==this._gIndex)this._sortByGroup(ind,type,dir);else this._sortInGroup(ind,type,dir);this.setSortImgState(true,ind,dir)
 if (this._fake){this._mirror_rowsCol();this._fake._groups=[];this._fake._reset_view()};this.setSortImgState(true,ind,dir);this.callEvent("onAfterSorting",[ind,type,dir]);return false});this.attachEvent("onClearAll",function(){this.unGroup()});this.attachEvent("onBeforeRowDeleted",function(id){if (!this._groups)return true;if (!this.rowsAr[id])return true;var val=this.cells(id,this._gIndex).getValue();if (val==="")val=" ";var z=this._groups[val];this._dec_group(z);return true});this.attachEvent("onCheckbox",function(id,index,value){this.callEvent("onEditCell",[2,id,index,(value?1:0),(value?0:1)])});this.attachEvent("onXLE",this.updateGroups);this.attachEvent("onColumnHidden",this.hideGroupColumn);this.attachEvent("onEditCell",function(stage,id,ind,val,oldval){if (!this._groups)return true;if (stage==2 && val!=oldval && ind==this._gIndex){if (oldval==="")oldval=" ";this._dec_group(this._groups[oldval]);var r=this.rowsAr[id];var i=this.rowsCol._dhx_find(r)
 var ni=this._inc_group(val);var n=this.rowsCol[ni];if (r==n)n=n.nextSibling;var p=r.parentNode;var o=r.rowIndex;p.removeChild(r);if (n)p.insertBefore(r,n);else
 p.appendChild(r);this.rowsCol._dhx_insertAt(ni,r);if (ni<i)i++;this.rowsCol._dhx_removeAt(i,r);this._fixAlterCss()}else if (stage==2 && val!=oldval){this.updateGroups();this._updateGroupView(this._groups[this.cells(id,this._gIndex).getValue()||" "])};return true})
 this.__sortRowsBG=true};this._groupExisting();if (this._hrrar)for (var i=0;i<this._hrrar.length;i++)if (this._hrrar[i])this.hideGroupColumn(i,true);this.callEvent("onGroup",[]);if (this._ahgr || this._awdth)this.setSizes()};dhtmlXGridObject.prototype._sortInGroup=function(col,type,order){var b=this._groups_get();b.reverse();for (var i=0;i<b.length;i++){var c=b[i]._cntr._childs;var a={};for (var j=0;j<c.length;j++){var cell = this.cells3(c[j],col);a[c[j].idd]=cell.getDate?cell.getDate():cell.getValue()};this._sortCore(col,type,order,a,c)};this._groups_put(b);this.setSizes();this.callEvent("onGridReconstructed",[])
};dhtmlXGridObject.prototype._sortByGroup=function(col,type,order){var b=this._groups_get();var a=[];for (var i=0;i<b.length;i++){b[i].idd="_sort_"+i;a["_sort_"+i]=b[i]._cntr.text};this._sortCore(col,type,order,a,b);this._groups_put(b);this.callEvent("onGridReconstructed",[])
 this.setSizes()};dhtmlXGridObject.prototype._inc_group=function(val,hidden,skip){if (val==="")val=" ";if (!this._groups[val]){this._groups[val]={text:val,row:this._addPseudoRow(),count:0,state:hidden?"plus":"minus"}};var z=this._groups[val];z.row._cntr=z;var ind=this.rowsCol._dhx_find(z.row)+z.count+1;z.count++;if (!skip){this._updateGroupView(z);this.updateGroups()};return ind};dhtmlXGridObject.prototype._dec_group=function(z){if (!z)return;z.count--;if (z.count==0){z.row.parentNode.removeChild(z.row);this.rowsCol._dhx_removeAt(this.rowsCol._dhx_find(z.row));delete this._groups[z.text]}else
 this._updateGroupView(z);if (this._fake && !this._realfake)this._fake._dec_group(this._fake._groups[z.text]);this.updateGroups();return true};dhtmlXGridObject.prototype._insertRowAt_gA=dhtmlXGridObject.prototype._insertRowAt;dhtmlXGridObject.prototype._insertRowAt=function(r,ind,skip){if (typeof(this._groups)!="undefined"){if (this._realfake)var val=this._fake._bfs_cells(r.idd,this._gIndex).getValue();else
 if (this._bfs_cells3)var val=this._bfs_cells3(r,this._gIndex).getValue();else
 var val=this.cells3(r,this._gIndex).getValue();if (!val)val=" ";ind=this._inc_group(val,r.style.display=="none")};var res=this._insertRowAt_gA(r,ind,skip);if (typeof(this._groups)!="undefined"){this.expandGroup(val);this._updateGroupView(this._groups[val]);this.updateGroups()};return res};dhtmlXGridObject.prototype._updateGroupView=function(z){if (this._fake && !this._realfake)return z.row.firstChild.innerHTML="&nbsp;";var mask = this._gmask||this._fake._gmask;var html="<img style='margin-bottom:-4px' src='"+this.imgURL+z.state+".gif'> ";if (this.customGroupFormat)html+=this.customGroupFormat(z.text,z.count);else html+=z.text+" ( "+z.count+" ) ";z.row.childNodes[mask._title].innerHTML=html};dhtmlXGridObject.prototype._addPseudoRow=function(skip){var mask = this._gmask||this._fake._gmask;var r=mask.cloneNode(true)
 
 for (var i=0;i<r.childNodes.length;i++)r.childNodes[i]._cellIndex=mask.childNodes[i]._cellIndex;var that=this;r.onclick=function(e){if (that._fake && that._realfake)that._fake._switchGroupState(that._fake._groups[this._cntr.text].row);else
 that._switchGroupState(this);(e||event).cancelBubble="true"};r.ondblclick=function(e){(e||event).cancelBubble="true"};if (!skip){if (_isKHTML)this.obj.appendChild(r)
 else
 this.obj.firstChild.appendChild(r)
 this.rowsCol.push(r)};return r};dhtmlXGridObject.prototype._groups_get=function(){var b=[];this._temp_par=this.obj.parentNode;this._temp_par.removeChild(this.obj);var a=[];for (var i=this.rowsCol.length-1;i>=0;i--){if (this.rowsCol[i]._cntr){this.rowsCol[i]._cntr._childs=a;a=[];b.push(this.rowsCol[i])}else a.push(this.rowsCol[i]);this.rowsCol[i].parentNode.removeChild(this.rowsCol[i])};return b};dhtmlXGridObject.prototype._groups_put=function(b){this.rowsCol=new dhtmlxArray(0);for (var i=0;i<b.length;i++){var gr=b[i]._cntr;this.obj.firstChild.appendChild(gr.row);this.rowsCol.push(gr.row)
 gr.row.idd=null;for (var j=0;j<gr._childs.length;j++){this.obj.firstChild.appendChild(gr._childs[j]);this.rowsCol.push(gr._childs[j])
 };delete gr._childs};this._temp_par.appendChild(this.obj)};dhtmlXGridObject.prototype._groupExisting=function(b){if (!this.getRowsNum()) return;var b=[];this._temp_par=this.obj.parentNode;this._temp_par.removeChild(this.obj);var a=[];var mlen=this.rowsCol.length;for (var i=0;i<mlen;i++){var val=this.cells4(this.rowsCol[i].childNodes[this._gIndex]).getValue();if (!val)val=" ";if (!this._groups[val]){this._groups[val]={text:val,row:this._addPseudoRow(true),count:0,state:"minus"};var z=this._groups[val];z.row._cntr=z;this._groups[val]._childs=[];b.push(z.row)
 };this._groups[val].count++;this._groups[val]._childs.push(this.rowsCol[i]);this.rowsCol[i].parentNode.removeChild(this.rowsCol[i])};for (var i=0;i<b.length;i++)this._updateGroupView(b[i]._cntr)
 this._groups_put(b);if (this._fake && !this._realfake){this._mirror_rowsCol();this._fake._groups=[];this._fake._reset_view()};this.callEvent("onGridReconstructed",[])
 this.updateGroups()};dhtmlXGridObject.prototype._switchGroupState=function(row){var z=row._cntr;if (this._fake && !this._realfake){z.state=this._fake._groups[row._cntr.text].row._cntr.state;this._fake._switchGroupState(this._fake._groups[row._cntr.text].row)
 };var ind=this.rowsCol._dhx_find(z.row)+1;z.state=z.state=="minus"?"plus":"minus";var st=z.state=="plus"?"none":"";while(this.rowsCol[ind] && !this.rowsCol[ind]._cntr){this.rowsCol[ind].style.display=st;ind++};this._updateGroupView(z);this.callEvent("onGroupStateChanged",[z.text, (z.state=="minus")]);this.setSizes()};dhtmlXGridObject.prototype.expandGroup=function(val){if (this._groups[val].state=="plus")this._switchGroupState(this._groups[val].row)};dhtmlXGridObject.prototype.collapseGroup=function(val){if (this._groups[val].state=="minus")this._switchGroupState(this._groups[val].row)};dhtmlXGridObject.prototype.expandAllGroups=function(){for(var i in this._groups)if (this._groups[i] && this._groups[i].state=="plus")this._switchGroupState(this._groups[i].row)};dhtmlXGridObject.prototype.collapseAllGroups=function(){for(var i in this._groups)if (this._groups[i] && this._groups[i].state=="minus")this._switchGroupState(this._groups[i].row)};dhtmlXGridObject.prototype.hideGroupColumn=function(ind,state){if (this._fake)return;var rind=-1;var row = this._gmask.childNodes;for (var i=0;i<row.length;i++)if (row[i]._cellIndex==ind){rind = i;break};if (rind == -1)return;for (var a in this._groups)this._groups[a].row.childNodes[rind].style.display=state?"none":""};dhtmlXGridObject.prototype.groupStat=function(name,ind,math){math = this["_g_"+(math||"stat_total")];var summ=0;var index=0;this.forEachRowInGroup(name,function(id){summ=math(summ,this.cells(id,ind).getValue()*1,index)
 index++})
 return summ};dhtmlXGridObject.prototype.forEachRowInGroup=function(name,code){var row=this._groups[name].row.nextSibling;if (row){while (row && !row._cntr){code.call(this,row.idd);row=row.nextSibling}}else {var cs=this._groups[name]._childs;if (cs)for (var i=0;i<cs.length;i++)code.call(this,cs[i].idd)}};dhtmlXGridObject.prototype.updateGroups=function(){if (!this._gmask || !this._gmask._math || this._parsing)return;var r=this._gmask.childNodes;for (var i=0;i<r.length;i++)if (r[i]._counter)this._b_processing.apply(this,r[i]._counter)
};dhtmlXGridObject.prototype._b_processing=function(a,ind,rind){var c=0,j=0;if (!this._ecache[this.cellType[ind]])this.cells5({parentNode:{grid:this}},this.cellType[ind]);for (var i=this.rowsCol.length-1;i>=0;i--){if (!this.rowsCol[i]._cntr){c=a(c,this.cells3(this.rowsCol[i],ind).getValue()*1,j);j++}else {this.cells5(this.rowsCol[i].childNodes[rind],this.cellType[ind]).setValue(c);j=c=0}}};dhtmlXGridObject.prototype._g_stat_total=function(c,n,i){return c+n};dhtmlXGridObject.prototype._g_stat_min=function(c,n,i){if (!i)c=Infinity;return Math.min(c,n)};dhtmlXGridObject.prototype._g_stat_max=function(c,n,i){if (!i)c=-Infinity;return Math.max(c,n)};dhtmlXGridObject.prototype._g_stat_average=function(c,n,i){return (c*i+n)/(i+1)};dhtmlXGridObject.prototype._g_stat_count=function(c,n,i){return c++};dhtmlXGridObject.prototype.enableDragAndDrop=function(mode){if (mode=="temporary_disabled"){this.dADTempOff=false;mode=true}else
 this.dADTempOff=true;this.dragAndDropOff=convertStringToBoolean(mode);this._drag_validate=true};dhtmlXGridObject.prototype.setDragBehavior=function(mode){this.dadmodec=this.dadmodefix=0;switch (mode) {case "child": this.dadmode=0;this._sbmod=false;break;case "sibling": this.dadmode=1;this._sbmod=false;break;case "sibling-next": this.dadmode=1;this._sbmod=true;break;case "complex": this.dadmode=2;this._sbmod=false;break;case "complex-next": this.dadmode=2;this._sbmod=true;break}};dhtmlXGridObject.prototype.enableDragOrder=function(mode){this._dndorder=convertStringToBoolean(mode)};dhtmlXGridObject.prototype._checkParent=function(row,ids){var z=this._h2.get[row.idd].parent;if (!z.parent)return;for (var i=0;i<ids.length;i++)if (ids[i]==z.id)return true;return this._checkParent(this.rowsAr[z.id],ids)};dhtmlXGridObject.prototype._createDragNode=function(htmlObject,e){this.editStop();if (window.dhtmlDragAndDrop.dragNode)return null;if (!this.dADTempOff)return null;htmlObject.parentObject=new Object();htmlObject.parentObject.treeNod=this;var text=this.callEvent("onBeforeDrag",[htmlObject.parentNode.idd,htmlObject._cellIndex]);if (!text)return null;var z=new Array();z[this.selMultiRows?z.length:0]=htmlObject.parentNode.idd;if (this.isTreeGrid()){for (var i=z.length-1;i>=0;i--)if (this._checkParent(this.rowsAr[z[i]],z)) z.splice(i,1)};var self=this;if (z.length && this._dndorder)z.sort(function(a,b){return (self.rowsAr[a].rowIndex>self.rowsAr[b].rowIndex?1:-1)});var el = this.getFirstParentOfType(_isIE?e.srcElement:e.target,"TD");if (el)this._dndExtra=el._cellIndex;this._dragged=new Array();for (var i=0;i<z.length;i++)if (this.rowsAr[z[i]]){this._dragged[this._dragged.length]=this.rowsAr[z[i]];this.rowsAr[z[i]].treeNod=this};htmlObject.parentObject.parentNode=htmlObject.parentNode;var dragSpan=document.createElement('div');dragSpan.innerHTML=(text!==true?text:this.rowToDragElement(htmlObject.parentNode.idd));dragSpan.style.position="absolute";dragSpan.className="dragSpanDiv";return dragSpan};dhtmlXGridObject.prototype._createSdrgc=function(){this._sdrgc=document.createElement("DIV");this._sdrgc.innerHTML="&nbsp;";this._sdrgc.className="gridDragLine";this.objBox.appendChild(this._sdrgc)};function dragContext(a,b,c,d,e,f,j,h,k,l){this.source=a||"grid";this.target=b||"grid";this.mode=c||"move";this.dropmode=d||"child";this.sid=e||0;this.tid=f;this.sobj=j||null;this.tobj=h||null;this.sExtra=k||null;this.tExtra=l||null;return this};dragContext.prototype.valid=function(){if (this.sobj!=this.tobj)return true;if (this.sid==this.tid)return false;if (this.target=="treeGrid"){var z=this.tid
 while (z = this.tobj.getParentId(z)){if (this.sid==z)return false}};return true};dragContext.prototype.close=function(){this.sobj=null;this.tobj=null};dragContext.prototype.copy=function(){return new dragContext(this.source,this.target,this.mode,this.dropmode,this.sid,this.tid,this.sobj,this.tobj,this.sExtra,this.tExtra)};dragContext.prototype.set=function(a,b){this[a]=b;return this};dragContext.prototype.uid=function(a,b){this.nid=this.sid;while (this.tobj.rowsAr[this.nid])this.nid=this.nid+((new Date()).valueOf());return this};dragContext.prototype.data=function(){if (this.sobj==this.tobj)return this.sobj._getRowArray(this.sobj.rowsAr[this.sid]);if (this.source=="tree")return this.tobj.treeToGridElement(this.sobj,this.sid,this.tid);else
 return this.tobj.gridToGrid(this.sid,this.sobj,this.tobj)};dragContext.prototype.childs=function(){if (this.source=="treeGrid")return this.sobj._h2.get[this.sid]._xml_await?this.sobj._h2.get[this.sid].has_kids:null;return null};dragContext.prototype.pid=function(){if (!this.tid)return 0;if (!this.tobj._h2)return 0;if (this.target=="treeGrid")if (this.dropmode=="child")return this.tid;else{var z=this.tobj.rowsAr[this.tid];var apid=this.tobj._h2.get[z.idd].parent.id;if ((this.alfa)&&(this.tobj._sbmod)&&(z.nextSibling)){var zpid=this.tobj._h2.get[z.nextSibling.idd].parent.id;if (zpid==this.tid)return this.tid;if (zpid!=apid)return zpid};return apid}};dragContext.prototype.ind=function(){if (this.tid==window.unknown)return 0;if (this.target=="treeGrid"){if (this.dropmode=="child")this.tobj.openItem(this.tid);else
 this.tobj.openItem(this.tobj.getParentId(this.tid))};var ind=this.tobj.rowsCol._dhx_find(this.tobj.rowsAr[this.tid]);if ((this.alfa)&&(this.tobj._sbmod)&&(this.dropmode=="sibling")){var z=this.tobj.rowsAr[this.tid];if ((z.nextSibling)&&(this._h2.get[z.nextSibling.idd].parent.id==this.tid))
 return ind+1};return (ind+1+((this.target=="treeGrid" && ind>=0 && this.tobj._h2.get[this.tobj.rowsCol[ind].idd].state=="minus")?this.tobj._getOpenLenght(this.tobj.rowsCol[ind].idd,0):0))};dragContext.prototype.img=function(){if ((this.target!="grid")&&(this.sobj._h2))
 return this.sobj.getItemImage(this.sid);else return null};dragContext.prototype.slist=function(){var res=new Array();for (var i=0;i<this.sid.length;i++)res[res.length]=this.sid[i][(this.source=="tree")?"id":"idd"];return res.join(",")};dhtmlXGridObject.prototype._drag=function(sourceHtmlObject,dhtmlObject,targetHtmlObject,lastLanding){if (this._realfake)return this._fake._drag() 
 
 var z=(this.lastLanding)
 
 if (this._autoOpenTimer)window.clearTimeout(this._autoOpenTimer);var r1=targetHtmlObject.parentNode;var r2=sourceHtmlObject.parentObject;if (!r1.idd){r1.grid=this;this.dadmodefix=0};var c=new dragContext(0,0,0,(r1.grid.dadmodec?"sibling":"child"));if (r2 && r2.childNodes)c.set("source","tree").set("sobj",r2.treeNod).set("sid",c.sobj._dragged);else{if (r2.treeNod.isTreeGrid && r2.treeNod.isTreeGrid()) c.set("source","treeGrid");c.set("sobj",r2.treeNod).set("sid",c.sobj._dragged)};if (r1.grid.isTreeGrid())
 c.set("target","treeGrid");else
 c.set("dropmode","sibling");c.set("tobj",r1.grid).set("tid",r1.idd);var el = this.getFirstParentOfType(lastLanding,"TD")
 if (el)c.set("tExtra",el._cellIndex);if (el)c.set("sExtra",c.sobj._dndExtra);if (c.sobj.dpcpy)c.set("mode","copy");if (c.tobj._realfake)c.tobj=c.tobj._fake;if (c.sobj._realfake)c.sobj=c.sobj._fake;c.tobj._clearMove();if (r2 && r2.treeNod && r2.treeNod._nonTrivialRow)r2.treeNod._nonTrivialRow(this,c.tid,c.dropmode,r2);else {c.tobj.dragContext=c;if (!c.tobj.callEvent("onDrag",[c.slist(),c.tid,c.sobj,c.tobj,c.sExtra,c.tExtra])) return c.tobj.dragContext=null;var result=new Array();if (typeof(c.sid)=="object"){var nc=c.copy();for (var i=0;i<c.sid.length;i++){if (!nc.set("alfa",(!i)).set("sid",c.sid[i][(c.source=="tree"?"id":"idd")]).valid()) continue;nc.tobj._dragRoutine(nc);if (nc.target=="treeGrid" && nc.dropmode == "child")nc.tobj.openItem(nc.tid);result[result.length]=nc.nid;nc.set("dropmode","sibling").set("tid",nc.nid)};nc.close()}else
 c.tobj._dragRoutine(c);if (c.tobj.laterLink)c.tobj.laterLink();c.tobj.callEvent("onDrop",[c.slist(),c.tid,result.join(","),c.sobj,c.tobj,c.sExtra,c.tExtra])};c.tobj.dragContext=null;c.close()};dhtmlXGridObject.prototype._dragRoutine=function(c){if ((c.sobj==c.tobj)&&(c.source=="grid")&&(c.mode=="move")&&!this._fake){if (c.sobj._dndProblematic)return;var fr=c.sobj.rowsAr[c.sid];var bind=c.sobj.rowsCol._dhx_find(fr);c.sobj.rowsCol._dhx_removeAt(c.sobj.rowsCol._dhx_find(fr));c.sobj.rowsBuffer._dhx_removeAt(c.sobj.rowsBuffer._dhx_find(fr));c.sobj.rowsBuffer._dhx_insertAt(c.ind(),fr);if (c.tobj._fake){c.tobj._fake.rowsCol._dhx_removeAt(bind);var tr=c.tobj._fake.rowsAr[c.sid];tr.parentNode.removeChild(tr)};c.sobj._insertRowAt(fr,c.ind());c.nid=c.sid;c.sobj.callEvent("onGridReconstructed",[]);return};var new_row;if (this._h2 && typeof c.tid !="undefined" && c.dropmode=="sibling" && (this._sbmod || c.tid)){if (c.alfa && this._sbmod && this._h2.get[c.tid].childs.length){this.openItem(c.tid)
 new_row=c.uid().tobj.addRowBefore(c.nid,c.data(),this._h2.get[c.tid].childs[0].id,c.img(),c.childs())}else
 new_row=c.uid().tobj.addRowAfter(c.nid,c.data(),c.tid,c.img(),c.childs())}else
 new_row=c.uid().tobj.addRow(c.nid,c.data(),c.ind(),c.pid(),c.img(),c.childs());if (c.source=="tree"){this.callEvent("onRowAdded",[c.nid]);var sn=c.sobj._globalIdStorageFind(c.sid);if (sn.childsCount){var nc=c.copy().set("tid",c.nid).set("dropmode",c.target=="grid"?"sibling":"child");for(var j=0;j<sn.childsCount;j++){c.tobj._dragRoutine(nc.set("sid",sn.childNodes[j].id));if (c.mode=="move")j--};nc.close()}}else{c.tobj._copyUserData(c);this.callEvent("onRowAdded",[c.nid]);if ((c.source=="treeGrid")){if (c.sobj==c.tobj)new_row._xml=c.sobj.rowsAr[c.sid]._xml;var snc=c.sobj._h2.get[c.sid];if ((snc)&&(snc.childs.length)){var nc=c.copy().set("tid",c.nid);if(c.target=="grid")nc.set("dropmode","sibling");else {nc.tobj.openItem(c.tid);nc.set("dropmode","child")};var l=snc.childs.length;for(var j=0;j<l;j++){c.sobj.render_row_tree(null,snc.childs[j].id);c.tobj._dragRoutine(nc.set("sid",snc.childs[j].id));if (l!=snc.childs.length){j--;l=snc.childs.length}};nc.close()}}};if (c.mode=="move"){c.sobj[(c.source=="tree")?"deleteItem":"deleteRow"](c.sid);if ((c.sobj==c.tobj)&&(!c.tobj.rowsAr[c.sid])) {c.tobj.changeRowId(c.nid,c.sid);c.nid=c.sid}}};dhtmlXGridObject.prototype.gridToGrid = function(rowId,sgrid,tgrid){var z=new Array();for (var i=0;i<sgrid.hdr.rows[0].cells.length;i++)z[i]=sgrid.cells(rowId,i).getValue();return z};dhtmlXGridObject.prototype.checkParentLine=function(node,id){if ((!this._h2)||(!id)||(!node)) return false;if (node.id==id)return true;else return this.checkParentLine(node.parent,id)};dhtmlXGridObject.prototype._dragIn=function(htmlObject,shtmlObject,x,y){if (!this.dADTempOff)return 0;var tree=this.isTreeGrid();if (this._drag_validate){if(htmlObject.parentNode==shtmlObject.parentNode)return 0;if ((tree)&&((this.checkParentLine(this._h2.get[htmlObject.parentNode.idd],shtmlObject.parentNode.idd))))
 return 0};var obj=shtmlObject.parentNode.idd?shtmlObject.parentNode:shtmlObject.parentObject;if (!this.callEvent("onDragIn",[obj.idd||obj.id,htmlObject.parentNode.idd,obj.grid||obj.treeNod,htmlObject.parentNode.grid]))
 return this._setMove(htmlObject,x,y,true);this._setMove(htmlObject,x,y);if ((tree)&&(htmlObject.parentNode.expand!="")){this._autoOpenTimer=window.setTimeout(new callerFunction(this._autoOpenItem,this),1000);this._autoOpenId=htmlObject.parentNode.idd}else
 if (this._autoOpenTimer)window.clearTimeout(this._autoOpenTimer);return htmlObject};dhtmlXGridObject.prototype._autoOpenItem=function(e,gridObject){gridObject.openItem(gridObject._autoOpenId)};dhtmlXGridObject.prototype._dragOut=function(htmlObject){this._clearMove();var obj=htmlObject.parentNode.parentObject?htmlObject.parentObject.id:htmlObject.parentNode.idd;this.callEvent("onDragOut",[obj]);if (this._autoOpenTimer)window.clearTimeout(this._autoOpenTimer)};dhtmlXGridObject.prototype._setMove=function(htmlObject,x,y,skip){if (!htmlObject.parentNode.idd)return;var t=_isChrome;_isChrome = true;var a1=getAbsoluteTop(htmlObject);var a2=getAbsoluteTop(this.objBox);_isChrome = t;if ( (a1-a2-parseInt(this.objBox.scrollTop))>(parseInt(this.objBox.offsetHeight)-50) )
 this.objBox.scrollTop=parseInt(this.objBox.scrollTop)+20;if ( (a1-a2)<(parseInt(this.objBox.scrollTop)+30) )
 this.objBox.scrollTop=parseInt(this.objBox.scrollTop)-20;if (skip)return 0;if (this.dadmode==2){var z=y-a1+this.objBox.scrollTop+(document.body.scrollTop||document.documentElement.scrollTop)-2-htmlObject.offsetHeight/2;if ((Math.abs(z)-htmlObject.offsetHeight/6)>0)
 {this.dadmodec=1;if (z<0)this.dadmodefix=-1;else this.dadmodefix=1}else this.dadmodec=0}else
 this.dadmodec=this.dadmode;if (this.dadmodec){if (!this._sdrgc)this._createSdrgc();this._sdrgc.style.display="block";this._sdrgc.style.top=a1-a2+((this.dadmodefix>=0)?htmlObject.offsetHeight:0)+"px"}else{this._llSelD=htmlObject;if (htmlObject.parentNode.tagName=="TR")for (var i=0;i<htmlObject.parentNode.childNodes.length;i++){var z= htmlObject.parentNode.childNodes[i];z._bgCol=z.style.backgroundColor;z.style.backgroundColor="#FFCCCC"}}};dhtmlXGridObject.prototype._clearMove=function(){if (this._sdrgc)this._sdrgc.style.display="none";if ((this._llSelD)&&(this._llSelD.parentNode.tagName=="TR"))
 for (var i=0;i<this._llSelD.parentNode.childNodes.length;i++)this._llSelD.parentNode.childNodes[i].style.backgroundColor=this._llSelD._bgCol;this._llSelD=null};dhtmlXGridObject.prototype.rowToDragElement=function(gridRowId){var out=this.cells(gridRowId,0).getValue();return out};dhtmlXGridObject.prototype._copyUserData = function(c){if(!c.tobj.UserData[c.nid] || c.tobj!=c.sobj)c.tobj.UserData[c.nid] = new Hashtable();var z1 = c.sobj.UserData[c.sid];var z2 = c.tobj.UserData[c.nid];if (z1){z2.keys = z2.keys.concat(z1.keys);z2.values = z2.values.concat(z1.values)}};dhtmlXGridObject.prototype.moveRow=function(rowId,mode,targetId,targetGrid){switch(mode){case "row_sibling":
 this.moveRowTo(rowId,targetId,"move","sibling",this,targetGrid);break;case "up":
 this.moveRowUp(rowId);break;case "down":
 this.moveRowDown(rowId);break}};dhtmlXGridObject.prototype._process_xmlA=function(xml){if (!xml.doXPath){var t = new dtmlXMLLoaderObject(function(){});if (typeof xml == "string")t.loadXMLString(xml);else {if (xml.responseXML)t.xmlDoc=xml;else
 t.xmlDoc={};t.xmlDoc.responseXML=xml};xml=t};this._parsing=true;var top=xml.getXMLTopNode(this.xml.top)
 
 this._parseHead(top);var rows=xml.doXPath(this.xml.row,top)
 var cr=parseInt(xml.doXPath("//"+this.xml.top)[0].getAttribute("pos")||0);var total=parseInt(xml.doXPath("//"+this.xml.top)[0].getAttribute("total_count")||0);if (total && !this.rowsBuffer[total-1])this.rowsBuffer[total-1]=null;if (this.isTreeGrid()){this._get_xml_data = this._get_xml_dataA;this._process_xml_row = this._process_xml_rowA;return this._process_tree_xml(xml)};for (var i=0;i < rows.length;i++){if (this.rowsBuffer[i+cr])continue;var id=rows[i].getAttribute("id")||this.uid();this.rowsBuffer[i+cr]={idd:id, data:rows[i], _parser: this._process_xml_rowA, _locator:this._get_xml_dataA };this.rowsAr[id]=rows[i]};this.render_dataset();this._parsing=false;return xml.xmlDoc.responseXML?xml.xmlDoc.responseXML:xml.xmlDoc};dhtmlXGridObject.prototype._process_xmlB=function(xml){if (!xml.doXPath){var t = new dtmlXMLLoaderObject(function(){});if (typeof xml == "string")t.loadXMLString(xml);else {if (xml.responseXML)t.xmlDoc=xml;else
 t.xmlDoc={};t.xmlDoc.responseXML=xml};xml=t};this._parsing=true;var top=xml.getXMLTopNode(this.xml.top)
 
 this._parseHead(top);var rows=xml.doXPath(this.xml.row,top)
 var cr=parseInt(xml.doXPath("//"+this.xml.top)[0].getAttribute("pos")||0);var total=parseInt(xml.doXPath("//"+this.xml.top)[0].getAttribute("total_count")||0);if (total && !this.rowsBuffer[total-1])this.rowsBuffer[total-1]=null;if (this.isTreeGrid()){this._get_xml_data = this._get_xml_dataB;this._process_xml_row = this._process_xml_rowB;return this._process_tree_xml(xml)};for (var i=0;i < rows.length;i++){if (this.rowsBuffer[i+cr])continue;var id=rows[i].getAttribute("id")||this.uid();this.rowsBuffer[i+cr]={idd:id, data:rows[i], _parser: this._process_xml_rowB, _locator:this._get_xml_dataB };this.rowsAr[id]=rows[i]};this.render_dataset();this._parsing=false;return xml.xmlDoc.responseXML?xml.xmlDoc.responseXML:xml.xmlDoc};dhtmlXGridObject.prototype._process_xml_rowA=function(r,xml){var strAr = [];r._attrs=this._xml_attrs(xml);for(var j=0;j<this.columnIds.length;j++){var cid=this.columnIds[j];var cellVal=r._attrs[cid]||"";if (r.childNodes[j])r.childNodes[j]._attrs={};strAr.push(cellVal)};this._fillRow(r,(this._c_order?this._swapColumns(strAr):strAr));return r};dhtmlXGridObject.prototype._get_xml_dataA=function(data,ind){return data.getAttribute(this.getColumnId(ind))};dhtmlXGridObject.prototype._process_xml_rowB=function(r,xml){var strAr = [];r._attrs=this._xml_attrs(xml);if (this._ud_enabled){var udCol = this.xmlLoader.doXPath("./userdata",xml);for (var i = udCol.length - 1;i >= 0;i--)this.setUserData(udCol[i].getAttribute("name"),udCol[i].firstChild?udCol[i].firstChild.data:"")};for (var jx=0;jx < xml.childNodes.length;jx++){var cellVal=xml.childNodes[jx];if (!cellVal.tagName)continue;var j=this.getColIndexById(cellVal.tagName);if (isNaN(j)) continue;var exc=cellVal.getAttribute("type");if (exc)r.childNodes[j]._cellType=exc;r.childNodes[j]._attrs=this._xml_attrs(cellVal);if (cellVal.getAttribute("xmlcontent"))
 {}else if (cellVal.firstChild)cellVal=cellVal.firstChild.data;else cellVal="";strAr[j]=cellVal};for (var i=0;i < r.childNodes.length;i++){if (!r.childNodes[i]._attrs)r.childNodes[i]._attrs={}};this._fillRow(r,(this._c_order?this._swapColumns(strAr):strAr));return r};dhtmlXGridObject.prototype._get_xml_dataB=function(data,ind){var id=this.getColumnId(ind);data=data.firstChild;while (true){if (!data)return "";if (data.tagName==id)return (data.firstChild?data.firstChild.data:"")
 data=data.nextSibling};return ""};dhtmlXGridObject.prototype.attachHeaderA=dhtmlXGridObject.prototype.attachHeader;dhtmlXGridObject.prototype.attachHeader=function()
{this.attachHeaderA.apply(this,arguments);if (this._realfake)return true;this.formAutoSubmit();if (typeof(this.FormSubmitOnlyChanged)=="undefined")
 this.submitOnlyChanged(true);if (typeof(this._submitAR)=="undefined")
 this.submitAddedRows(true);var that=this;this._added_rows=[];this._deleted_rows=[];this.attachEvent("onRowAdded",function(id){that._added_rows.push(id);that.forEachCell(id,function(a){a.cell.wasChanged=true})
 return true});this.attachEvent("onBeforeRowDeleted",function(id){that._deleted_rows.push(id);return true});this.attachHeader=this.attachHeaderA};dhtmlXGridObject.prototype.formAutoSubmit = function()
{this.parentForm = this.detectParentFormPresent();if (this.parentForm === false){return false};if (this.formEventAttached)return;this.formInputs = new Array();var self = this;dhtmlxEvent(this.parentForm, 'submit', function() {if (self.entBox)self.parentFormOnSubmit()});this.formEventAttached = true};dhtmlXGridObject.prototype.parentFormOnSubmit = function()
{this.formCreateInputCollection();if (!this.callEvent("onBeforeFormSubmit",[])) return false};dhtmlXGridObject.prototype.submitOnlyChanged = function(mode)
{this.FormSubmitOnlyChanged = convertStringToBoolean(mode)};dhtmlXGridObject.prototype.submitColumns=function(names){if (typeof names == "string")names=names.split(this.delim);this._submit_cols=names};dhtmlXGridObject.prototype.setFieldName=function(mask){mask=mask.replace(/\{GRID_ID\}/g,"'+a1+'");mask=mask.replace(/\{ROW_ID\}/g,"'+a2+'");mask=mask.replace(/\{ROW_INDEX\}/g,"'+this.getRowIndex(a2)+'");mask=mask.replace(/\{COLUMN_INDEX\}/g,"'+a3+'");mask=mask.replace(/\{COLUMN_ID\}/g,"'+this.getColumnId(a3)+'");this._input_mask=Function("a1","a2","a3","return '"+mask+"';")};dhtmlXGridObject.prototype.submitSerialization = function(mode)
{this.FormSubmitSerialization = convertStringToBoolean(mode)};dhtmlXGridObject.prototype.submitAddedRows = function(mode)
{this._submitAR = convertStringToBoolean(mode)};dhtmlXGridObject.prototype.submitOnlySelected = function(mode)
{this.FormSubmitOnlySelected = convertStringToBoolean(mode)};dhtmlXGridObject.prototype.submitOnlyRowID = function(mode)
{this.FormSubmitOnlyRowID = convertStringToBoolean(mode)};dhtmlXGridObject.prototype.createFormInput = function(name,value){var input = document.createElement('input');input.type = 'hidden';if (this._input_mask)input.name=this._input_mask.apply(this,name);else
 input.name =((this.globalBox||this.entBox).id||'dhtmlXGrid')+'_'+name;input.value = value;this.parentForm.appendChild(input);this.formInputs.push(input)};dhtmlXGridObject.prototype.createFormInputRow = function(r){var id=(this.globalBox||this.entBox).id;for (var j=0;j<this._cCount;j++){var foo_cell = this.cells3(r, j);if (((!this.FormSubmitOnlyChanged)|| foo_cell.wasChanged()) && (!this._submit_cols || this._submit_cols[j]))
 this.createFormInput(this._input_mask?[id,r.idd,j]:(r.idd+'_'+j),foo_cell.getValue())}};dhtmlXGridObject.prototype.formCreateInputCollection = function()
{if (this.parentForm == false){return false};for (var i=0;i<this.formInputs.length;i++){this.parentForm.removeChild(this.formInputs[i])};this.formInputs = new Array();if (this.FormSubmitSerialization){this.createFormInput("serialized",this.serialize())}else if (this.FormSubmitOnlySelected){if (this.FormSubmitOnlyRowID)this.createFormInput("selected",this.getSelectedId());else
 for(var i=0;i<this.selectedRows.length;i++)this.createFormInputRow(this.selectedRows[i])}else{if (this._submitAR){if (this._added_rows.length)this.createFormInput("rowsadded",this._added_rows.join(","));if (this._deleted_rows.length)this.createFormInput("rowsdeleted",this._deleted_rows.join(","))};this.forEachRow(function(id){this.getRowById(id);this.createFormInputRow(this.rowsAr[id])})
 
 }};dhtmlXGridObject.prototype.detectParentFormPresent = function()
{var parentForm = false;var parent = this.entBox;while(parent && parent.tagName && parent != document.body){if (parent.tagName.toLowerCase()== 'form') {parentForm = parent;break}else {parent = parent.parentNode}};return parentForm};dhtmlXGridObject.prototype.enableHeaderMenu=function()
{var that=this;this.attachEvent("onInit",function(){this.hdr.oncontextmenu = function(e){return that._doHContClick(e||window.event)};{
 this.startColResizeA=this.startColResize;this.startColResize=function(e){if (e.button==2 || (_isMacOS&&e.ctrlKey))
 return this._doHContClick(e)
 return this.startColResizeA(e)}};this._chm_ooc=this.obj.onclick;this._chm_hoc=this.hdr.onclick;this.hdr.onclick=function(e){if (e && ( e.button==2 || (_isMacOS&&e.ctrlKey))) return false;that._showHContext(false);return that._chm_hoc.apply(this,arguments)
 };this.obj.onclick=function(){that._showHContext(false);return that._chm_ooc.apply(this,arguments)
 }});dhtmlxEvent(document.body,"click",function(){if (that._hContext)that._showHContext(false)})
 if (this.hdr.rows.length)this.callEvent("onInit",[]);this.enableHeaderMenu=function(){}};dhtmlXGridObject.prototype._doHContClick=function(ev)
{function mouseCoords(ev){if(ev.pageX || ev.pageY){return {x:ev.pageX, y:ev.pageY}};var d = ((_isIE)&&(document.compatMode != "BackCompat"))?document.documentElement:document.body;return {x:ev.clientX + d.scrollLeft - d.clientLeft,
 y:ev.clientY + d.scrollTop - d.clientTop
 }};this._createHContext();var coords = mouseCoords(ev);this._showHContext(true,coords.x,coords.y);ev[_isIE?"srcElement":"target"].oncontextmenu = function(e){(e||event).cancelBubble=true;return false};ev.cancelBubble=true;if (ev.preventDefault)ev.preventDefault();return false};dhtmlXGridObject.prototype._createHContext=function()
{if (this._hContext)return this._hContext;var d = document.createElement("DIV");d.oncontextmenu = function(e){(e||event).cancelBubble=true;return false};d.onclick=function(e){(e||event).cancelBubble=true;return true};d.className="dhx_header_cmenu";d.style.width=d.style.height="5px";d.style.display="none";var a=[];var i=0;if (this._fake)i=this._fake._cCount;var true_ind=i;for (var i;i<this.hdr.rows[1].cells.length;i++){var c=this.hdr.rows[1].cells[i];if (c.firstChild && c.firstChild.tagName=="DIV")var val=c.firstChild.innerHTML;else var val = c.innerHTML;a.push("<div class='dhx_header_cmenu_item'><input type='checkbox' column='"+true_ind+"' len='"+(c.colSpan||1)+"' checked='true' />"+val+"</div>");true_ind+=(c.colSpan||1)};d.innerHTML=a.join("");var that=this;var f=function(){var c=this.getAttribute("column");if (!this.checked && !that._checkLast(c)) return this.checked=true;if (that._realfake)that=that._fake;for (var i=0;i<this.getAttribute("len");i++)
 that.setColumnHidden((c*1+i*1),!this.checked);if(this.checked && that.getColWidth(c)==0) 
 that.adjustColumnSize(c)};for (var i=0;i<d.childNodes.length;i++)d.childNodes[i].firstChild.onclick=f;document.body.insertBefore(d,document.body.firstChild);this._hContext=d;d.style.position="absolute";d.style.zIndex=999;d.style.width='auto'
 d.style.height='auto'
 d.style.display='block'};dhtmlXGridObject.prototype._checkLast=function(ind){for (var i=0;i < this._cCount;i++)if ((!this._hrrar || !this._hrrar[i])&&(i!=ind))
 return true;return false};dhtmlXGridObject.prototype._updateHContext=function()
{for (var i=0;i<this._hContext.childNodes.length;i++){var c=this._hContext.childNodes[i].firstChild;var col=c.getAttribute("column");if (this.isColumnHidden(col)|| (this.getColWidth(col)==0))
 c.checked=false}};dhtmlXGridObject.prototype._showHContext=function(mode,x,y)
{if (mode && this.enableColumnMove){this._hContext.parentNode.removeChild(this._hContext);this._hContext=null};this._createHContext();this._hContext.style.display=(mode?'block':'none');if (mode){this._updateHContext(true);this._hContext.style.left=x+"px";this._hContext.style.top=y+"px"}};function eXcell_math(cell){if (cell){this.cell = cell;this.grid = this.cell.parentNode.grid};this.edit = function(){this.grid.editor = new eXcell_ed(this.cell);this.grid.editor.getValue=function(){return this.cell.original||this.getTitle()};this.grid.editor.setValue=this.setValue;this.grid.editor.edit()};this.isDisabled = function(){return !this.grid._mathEdit};this.setValue = function(val){val=this.grid._compileSCL(val,this.cell);if (this.grid._strangeParams[this.cell._cellIndex])this.grid.cells5(this.cell,this.grid._strangeParams[this.cell._cellIndex]).setValue(val);else{this.setCValue(val);this.cell._clearCell=false}};this.getValue = function(){if (this.grid._strangeParams[this.cell._cellIndex])return this.grid.cells5(this.cell,this.grid._strangeParams[this.cell._cellIndex]).getValue();return this.cell.innerHTML}};eXcell_math.prototype = new eXcell;dhtmlXGridObject.prototype._init_point_bm=dhtmlXGridObject.prototype._init_point;dhtmlXGridObject.prototype._init_point = function(){this._mat_links={};this._aggregators=[];this.attachEvent("onClearAll",function(){this._mat_links={};this._aggregators=[]})
 this.attachEvent("onCellChanged",function(id,ind){if (this._mat_links[id]){var cell=this._mat_links[id][ind];if (cell){for (var i=0;i<cell.length;i++)this.cells5(cell[i]).setValue(this._calcSCL(cell[i]))}};if (!this._parsing && this._aggregators[ind]){var pid=this._h2.get[id].parent.id;if (pid!=0){var ed=this.cells(pid,ind);ed.setValue(this._calcSCL(ed.cell))}}})
 this.attachEvent("onAfterRowDeleted",function(id,pid){if (pid!=0)if (!this._parsing && this._aggregators.length){for (var ind=0;ind < this._aggregators.length;ind++){if (this._aggregators[ind]){var ed=this.cells(pid,ind);ed.setValue(this._calcSCL(ed.cell))}}};return true})
 this.attachEvent("onXLE",function(){for (var i=0;i < this._aggregators.length;i++){if (this._aggregators[i])this._h2.forEachChild(0,function(el){if (el.childs.length!=0){var ed=this.cells(el.id,i);ed.setValue(this._calcSCL(ed.cell))}},this)}})
 this._init_point=this._init_point_bm;if (this._init_point)this._init_point()};dhtmlXGridObject.prototype.enableMathSerialization=function(status){this._mathSerialization=convertStringToBoolean(status)};dhtmlXGridObject.prototype.setMathRound=function(digits){this._roundDl=digits;this._roundD=Math.pow(10,digits)};dhtmlXGridObject.prototype.enableMathEditing=function(status){this._mathEdit=convertStringToBoolean(status)};dhtmlXGridObject.prototype._calcSCL=function(cell){if (!cell._code)return cell.innerHTML;try{var agrid=this;var z=eval(cell._code)}catch(e){return ("#SCL")};if (this._roundD){var pre=Math.abs(z)<1?"0":"";z=Math.round(z*this._roundD).toString();if (z==0)return 0;if (this._roundDl>0){var n=z.length-this._roundDl;if (n<0){z=("000000000"+z).substring(9+n);n=0};return (pre+z.substring(0,n)+"."+z.substring(n,z.length))}};return z};dhtmlXGridObject.prototype._countTotal=function(row,cell){var b=0;var z=this._h2.get[row];for (var i=0;i<z.childs.length;i++){if (!z.childs[i].buff)return b;if (z.childs[i].buff._parser){this._h2.forEachChild(row,function(el){if (el.childs.length==0)b+=this._get_cell_value(el.buff,cell)*1},this)
 return b};b+=this._get_cell_value(z.childs[i].buff,cell)*1};return b};dhtmlXGridObject.prototype._compileSCL=function(code,cell){if (!code)return code;code=code.toString();if (code.indexOf("=")!=0) {this._reLink([],cell);return code};cell.original=code;var linked=null;code=code.replace("=","");if (code.indexOf("sum")!=-1){code=code.replace("sum","(agrid._countTotal('"+cell.parentNode.idd+"',"+cell._cellIndex+"))");if (!this._aggregators)this._aggregators=[];this._aggregators[cell._cellIndex]="sum";cell._code=code;return this._parsing?"":this._calcSCL(cell)};if (code.indexOf("[[")!=-1){var test = /(\[\[([^\,]*)\,([^\]]*)]\])/g;var agrid=this;linked=linked||(new Array());code=code.replace(test,
 function ($0,$1,$2,$3){if ($2=="-")$2=cell.parentNode.idd;if ($2.indexOf("#")==0)
 $2=agrid.getRowId($2.replace("#",""));linked[linked.length]=[$2,$3];return "(agrid.cells(\""+$2+"\","+$3+").getValue()*1)"})};if (code.indexOf(":")!=-1){var test = /:(\w+)/g;var agrid=this;var id=cell.parentNode.idd;linked=linked||(new Array());code=code.replace(test,
 function ($0,$1,$2,$3){linked[linked.length]=[id,agrid.getColIndexById($1)];return '(agrid.cells("'+id+'",agrid.getColIndexById("'+$1+'")).getValue()*1)'})}else{var test = /c([0-9]+)/g;var agrid=this;var id=cell.parentNode.idd;linked=linked||(new Array());code=code.replace(test,
 function ($0,$1,$2,$3){linked[linked.length]=[id,$1];return "(agrid.cells(\""+id+"\","+$1+").getValue()*1)"})};this._reLink(linked,cell);cell._code=code;return this._calcSCL(cell)};dhtmlXGridObject.prototype._reLink=function(ar,cell){if (!ar.length)return;for (var i=0;i<ar.length;i++){if (!this._mat_links[ar[i][0]])this._mat_links[ar[i][0]]={};var t=this._mat_links[ar[i][0]];if (!t[ar[i][1]])t[ar[i][1]]=[];t[ar[i][1]].push(cell)}};if (_isKHTML){(function(){var default_replace = String.prototype.replace;String.prototype.replace = function(search,replace){if(typeof replace != "function"){return default_replace.apply(this,arguments)
 };var str = "" + this;var callback = replace;if(!(search instanceof RegExp)){var idx = str.indexOf(search);return (
 idx == -1 ? str :
 default_replace.apply(str,[search,callback(search, idx, str)])
 )
 };var reg = search;var result = [];var lastidx = reg.lastIndex;var re;while((re = reg.exec(str)) != null){var idx = re.index;var args = re.concat(idx, str);result.push(
 str.slice(lastidx,idx),
 callback.apply(null,args).toString()
 );if(!reg.global){lastidx += RegExp.lastMatch.length;break
 }else{lastidx = reg.lastIndex}};result.push(str.slice(lastidx));return result.join("")
 }})()};dhtmlXGridObject.prototype.insertColumn=function(ind,header,type,width,sort,align,valign,reserved,columnColor){ind=parseInt(ind);if (ind>this._cCount)ind=this._cCount;if (!this._cMod)this._cMod=this._cCount;this._processAllArrays(this._cCount,ind-1,[(header||"&nbsp;"),(width||100),(type||"ed"),(align||"left"),(valign||""),(sort||"na"),(columnColor||""),"",this._cMod,(width||100)]);this._processAllRows("_addColInRow",ind);if (typeof(header)=="object")
 for (var i=1;i < this.hdr.rows.length;i++){if (header[i-1]=="#rspan"){var pind=i-1;var found=false;var pz=null;while(!found){var pz=this.hdr.rows[pind];for (var j=0;j<pz.cells.length;j++)if (pz.cells[j]._cellIndex==ind){found=j;break};pind--};this.hdr.rows[pind+1].cells[j].rowSpan=(this.hdr.rows[pind].cells[j].rowSpan||1)+1}else 
 this.setHeaderCol(ind,(header[i-1]||"&nbsp;"),i)}else
 this.setHeaderCol(ind,(header||"&nbsp;"));this.hdr.rows[0].cells[ind]
 this._cCount++;this._cMod++;this._master_row=null;this.setSizes()};dhtmlXGridObject.prototype.deleteColumn=function(ind){ind=parseInt(ind);if (this._cCount==0)return;if (!this._cMod)this._cMod=this._cCount;if (ind>=this._cCount)return;this._processAllArrays(ind,this._cCount-1,[null,null,null,null,null,null,null,null,null,null,null]);this._processAllRows("_deleteColInRow",ind);this._cCount--;this._master_row=null;this.setSizes()};dhtmlXGridObject.prototype._processAllRows = function(method,oldInd,newInd){this[method](this.obj.rows[0],oldInd,newInd,0);var z=this.hdr.rows.length;for (var i=0;i<z;i++)this[method](this.hdr.rows[i],oldInd,newInd,i);if (this.ftr){var z=this.ftr.firstChild.rows.length;for (var i=0;i<z;i++)this[method](this.ftr.firstChild.rows[i],oldInd,newInd,i)};this.forEachRow(function(id){if (this.rowsAr[id] && this.rowsAr[id].tagName=="TR")this[method](this.rowsAr[id],oldInd,newInd,-1)})};dhtmlXGridObject.prototype._processAllArrays = function(oldInd,newInd,vals){var ars=["hdrLabels","initCellWidth","cellType","cellAlign","cellVAlign","fldSort","columnColor","_hrrar","_c_order"];if (this.cellWidthPX.length)ars.push("cellWidthPX");if (this.cellWidthPC.length)ars.push("cellWidthPC");if (this._col_combos)ars.push("_col_combos");if (this._mCols)ars[ars.length]="_mCols";if (this.columnIds)ars[ars.length]="columnIds";if (this._maskArr)ars.push("_maskArr");if (this._drsclmW)ars.push("_drsclmW");if (this.clists)ars.push("clists");ars.push("combos");if (this._customSorts)ars.push("_customSorts");if (this._aggregators)ars.push("_aggregators");var mode=(oldInd<=newInd);if (!this._c_order){this._c_order=new Array();var l=this._cCount;for (var i=0;i<l;i++)this._c_order[i]=i};for (var i=0;i<ars.length;i++){var t=this[ars[i]];if (t){if (mode){var val=t[oldInd];for (var j=oldInd;j<newInd;j++)t[j]=t[j+1];t[newInd]=val}else {var val=t[oldInd];for (var j=oldInd;j>(newInd+1);j--)
 t[j]=t[j-1];t[newInd+1]=val};if (vals)t[newInd+(mode?0:1)]=vals[i]}}};dhtmlXGridObject.prototype.moveColumn = function(oldInd,newInd){newInd--;oldInd=parseInt(oldInd);newInd=parseInt(newInd);if (newInd<oldInd)var tInd=newInd+1;else var tInd=newInd;if (!this.callEvent("onBeforeCMove",[oldInd,tInd])) return false;if (oldInd==tInd)return;this.editStop();this._processAllRows("_moveColInRow",oldInd,newInd);this._processAllArrays(oldInd,newInd);if (this.fldSorted)this.setSortImgPos(this.fldSorted._cellIndex);this.callEvent("onAfterCMove",[oldInd,tInd])};dhtmlXGridObject.prototype._swapColumns = function(cols){var z=new Array();for (var i=0;i<this._cCount;i++){var n=cols[this._c_order[i]];if (typeof(n)=="undefined") n="";z[i]=n};return z};dhtmlXGridObject.prototype._moveColInRow = function(row,oldInd,newInd){var c=row.childNodes[oldInd];var ci=row.childNodes[newInd+1];if (!c)return;if (ci)row.insertBefore(c,ci);else
 row.appendChild(c);for (var i=0;i<row.childNodes.length;i++)row.childNodes[i]._cellIndex=row.childNodes[i]._cellIndexS=i};dhtmlXGridObject.prototype._addColInRow = function(row,ind,old,mod){var cind=ind;if (row._childIndexes){if (row._childIndexes[ind-1]==row._childIndexes[ind] || !row.childNodes[row._childIndexes[ind-1]]){for (var i=row._childIndexes.length;i>=ind;i--)row._childIndexes[i]=i?(row._childIndexes[i-1]+1):0;row._childIndexes[ind]--}else
 for (var i = row._childIndexes.length;i >= ind;i--)row._childIndexes[i]=i?(row._childIndexes[i-1]+1):0;var cind=row._childIndexes[ind]};var c=row.childNodes[cind];var z=document.createElement((mod)?"TD":"TH");if (mod){z._attrs={}}else z.style.width=(parseInt(this.cellWidthPX[ind])||"100")+"px";if (c)row.insertBefore(z,c);else
 row.appendChild(z);if (this.dragAndDropOff && row.idd)this.dragger.addDraggableItem(row.childNodes[cind],this);for (var i=cind+1;i<row.childNodes.length;i++){row.childNodes[i]._cellIndex=row.childNodes[i]._cellIndexS=row.childNodes[i]._cellIndex+1};if (row.childNodes[cind])row.childNodes[cind]._cellIndex=row.childNodes[cind]._cellIndexS=ind;if (row.idd || typeof(row.idd)!="undefined"){this.cells3(row,ind).setValue("");z.align=this.cellAlign[ind];z.style.verticalAlign=this.cellVAlign[ind];z.bgColor=this.columnColor[ind]}else if (z.tagName=="TD"){if (!row.idd && this.forceDivInHeader)z.innerHTML="<div class='hdrcell'>&nbsp;</div>";else z.innerHTML="&nbsp;"}};dhtmlXGridObject.prototype._deleteColInRow = function(row,ind){if (row._childIndexes)ind=row._childIndexes[ind];var c=row.childNodes[ind];if (!c)return;if (c.colSpan && c.colSpan>1 && c.parentNode.idd){var t=c.colSpan-1;var v=this.cells4(c).getValue();this.setColspan(c.parentNode.idd,c._cellIndex,1)
 if (t>1){var cind=c._cellIndex*1;this.setColspan(c.parentNode.idd,cind+1,t)
 this.cells(c.parentNode.idd,c._cellIndex*1+1).setValue(v)
 row._childIndexes.splice(cind,1)
 for (var i=cind;i < row._childIndexes.length;i++)row._childIndexes[i]-=1}}else if (row._childIndexes){row._childIndexes.splice(ind,1);for (var i=ind;i<row._childIndexes.length;i++)row._childIndexes[i]--};if (c)row.removeChild(c);for (var i=ind;i<row.childNodes.length;i++)row.childNodes[i]._cellIndex=row.childNodes[i]._cellIndexS=row.childNodes[i]._cellIndex-1};dhtmlXGridObject.prototype.enableColumnMove = function(mode,columns){this._mCol=convertStringToBoolean(mode);if (typeof(columns)!="undefined")
 this._mCols=columns.split(",");if (!this._mmevTrue){dhtmlxEvent(this.hdr,"mousedown",this._startColumnMove);dhtmlxEvent(document.body,"mousemove",this._onColumnMove);dhtmlxEvent(document.body,"mouseup",this._stopColumnMove);this._mmevTrue=true}};dhtmlXGridObject.prototype._startColumnMove = function(e){e=e||event;var el = e.target||e.srcElement;var zel=el;while(zel.tagName!="TABLE")zel=zel.parentNode;var grid=zel.grid;if (!grid)return;grid.setActive();if (!grid._mCol || e.button==2)return;el = grid.getFirstParentOfType(el,"TD")
 if(el.style.cursor!="default")return true;if ((grid)&&(!grid._colInMove)){grid.resized = null;if ((!grid._mCols)||(grid._mCols[el._cellIndex]=="true"))
 grid._colInMove=el._cellIndex+1};return true};dhtmlXGridObject.prototype._onColumnMove = function(e){e=e||event;var grid=window.globalActiveDHTMLGridObject;if ((grid)&&(grid._colInMove)){if (grid._showHContext)grid._showHContext(false)
 if (typeof(grid._colInMove)!="object"){var z=document.createElement("DIV");z._aIndex=(grid._colInMove-1);z._bIndex=null;z.innerHTML=grid.getHeaderCol(z._aIndex);z.className="dhx_dragColDiv";z.style.position="absolute";document.body.appendChild(z);grid._colInMove=z};var cor=[];cor[0]=(document.body.scrollLeft||document.documentElement.scrollLeft);cor[1]=(document.body.scrollTop||document.documentElement.scrollTop);grid._colInMove.style.left=e.clientX+cor[0]+8+"px";grid._colInMove.style.top=e.clientY+cor[1]+8+"px";var el = e.target||e.srcElement;while ((el)&&(typeof(el._cellIndexS)=="undefined"))
 el=el.parentNode;if (grid._colInMove._oldHe){grid._colInMove._oldHe.className=grid._colInMove._oldHe.className.replace(/columnTarget(L|R)/g,"");grid._colInMove._oldHe=null;grid._colInMove._bIndex=null};if (el){if (grid.hdr.rows[1]._childIndexes)var he=grid.hdr.rows[1].cells[grid.hdr.rows[1]._childIndexes[el._cellIndexS]];else
 var he=grid.hdr.rows[1].cells[el._cellIndexS];var z=e.clientX-(getAbsoluteLeft(he)-grid.hdrBox.scrollLeft);if (z/he.offsetWidth>0.5){he.className+=" columnTargetR";grid._colInMove._bIndex=el._cellIndexS}else {he.className+=" columnTargetL";grid._colInMove._bIndex=el._cellIndexS-1};if (he.offsetLeft<(grid.objBox.scrollLeft+20))
 grid.objBox.scrollLeft=Math.max(0,he.offsetLeft-20);if ((he.offsetLeft+he.offsetWidth-grid.objBox.scrollLeft)>(grid.objBox.offsetWidth-20))
 grid.objBox.scrollLeft=Math.min(grid.objBox.scrollLeft+he.offsetWidth+20,grid.objBox.scrollWidth-grid.objBox.offsetWidth);grid._colInMove._oldHe=he};e.cancelBubble = true;return false};return true};dhtmlXGridObject.prototype._stopColumnMove = function(e){e=e||event;var grid=window.globalActiveDHTMLGridObject;if ((grid)&&(grid._colInMove)){if (typeof(grid._colInMove)=="object"){grid._colInMove.parentNode.removeChild(grid._colInMove);if (grid._colInMove._bIndex!=null)grid.moveColumn(grid._colInMove._aIndex,grid._colInMove._bIndex+1);if (grid._colInMove._oldHe)grid._colInMove._oldHe.className=grid._colInMove._oldHe.className.replace(/columnTarget(L|R)/g,"");grid._colInMove._oldHe=null;grid._colInMove.grid=null;grid.resized = true};grid._colInMove=0};return true};dhtmlXGridObject.prototype.loadCSVFile = function(path,afterCall){this.load(path,afterCall,"csv")
};dhtmlXGridObject.prototype.enableCSVAutoID = function(mode){this._csvAID=convertStringToBoolean(mode)};dhtmlXGridObject.prototype.enableCSVHeader = function(mode){this._csvHdr=convertStringToBoolean(mode)};dhtmlXGridObject.prototype.setCSVDelimiter = function(str){this.csv.cell=str};dhtmlXGridObject.prototype._csvAID = true;dhtmlXGridObject.prototype.loadCSVString = function(str){this.parse(str,"csv")
};dhtmlXGridObject.prototype.serializeToCSV = function(textmode){this.editStop()
 if (this._mathSerialization)this._agetm="getMathValue";else if (this._strictText || textmode)this._agetm="getTitle";else this._agetm="getValue";var out=[];if (this._csvHdr){for (var j=1;j < this.hdr.rows.length;j++){var a=[];for (var i=0;i<this._cCount;i++)if ((!this._srClmn)||(this._srClmn[i]))
 a.push(this.getColumnLabel(i,j-1));out.push(a.join(this.csv.cell))}};var i=0;var leni=this.rowsBuffer.length;for(i;i<leni;i++){var temp=this._serializeRowToCVS(null,i) 
 if (temp!="")out.push(temp)};return out.join(this.csv.row)};dhtmlXGridObject.prototype._serializeRowToCVS = function(r,i,start,end){var out = new Array();if (!r){r=this.render_row(i)
 if (this._fake && !this._fake.rowsAr[r.idd])this._fake.render_row(i)};if (!this._csvAID)out[out.length]=r.idd;start = start||0;end = end||this._cCount;var changeFl=false;var ind=start;while (r.childNodes[start]._cellIndex>ind && start)start--;for(var jj=start;ind<end;jj++){if (!r.childNodes[jj])break;var real_ind=r.childNodes[jj]._cellIndex;if ((!this._srClmn)||(this._srClmn[real_ind])){var cvx=r.childNodes[jj];var zx=this.cells(r.idd,real_ind);while (ind!=real_ind){ind++;out.push("")
 if (ind>=end)break};if (ind>=end)break;ind++;if (zx.cell)zxVal=zx[this._agetm]();else zxVal="";if ((this._chAttr)&&(zx.wasChanged()))
 changeFl=true;out[out.length]=((zxVal===null)?"":zxVal)

 if ( this._ecspn && cvx.colSpan && cvx.colSpan >1 ){cvx=cvx.colSpan-1;for (var u=0;u<cvx;u++){out[out.length] = "";ind++}}}else ind++};if ((this._onlChAttr)&&(!changeFl)) return "";return out.join(this.csv.cell)};dhtmlXGridObject.prototype.toClipBoard=function(val){if (window.clipboardData)window.clipboardData.setData("Text",val);else
 (new Clipboard()).copy(val)};dhtmlXGridObject.prototype.fromClipBoard=function(){if (window.clipboardData)return window.clipboardData.getData("Text");else
 return (new Clipboard()).paste()};dhtmlXGridObject.prototype.cellToClipboard = function(rowId,cellInd){if ((!rowId)||(!cellInd)){if (!this.selectedRows[0])return;rowId=this.selectedRows[0].idd;cellInd=this.cell._cellIndex};var ed=this.cells(rowId,cellInd);this.toClipBoard(((ed.getLabel?ed.getLabel():ed.getValue())||"").toString())};dhtmlXGridObject.prototype.updateCellFromClipboard = function(rowId,cellInd){if ((!rowId)||(!cellInd)){if (!this.selectedRows[0])return;rowId=this.selectedRows[0].idd;cellInd=this.cell._cellIndex};var ed=this.cells(rowId,cellInd);ed[ed.setImage?"setLabel":"setValue"](this.fromClipBoard())};dhtmlXGridObject.prototype.rowToClipboard = function(rowId){var out="";if (this._mathSerialization)this._agetm="getMathValue";else if (this._strictText)this._agetm="getTitle";else this._agetm="getValue";if (rowId)out=this._serializeRowToCVS(this.getRowById(rowId));else
 for (var i=0;i<this.selectedRows.length;i++){if (out)out+=this.csv.row;out+=this._serializeRowToCVS(this.selectedRows[i])};this.toClipBoard(out)};dhtmlXGridObject.prototype.updateRowFromClipboard = function(rowId){var csv=this.fromClipBoard();if (!csv)return;if (rowId)var r=this.getRowById(rowId);else
 var r=this.selectedRows[0];if (!r)return;csv=(csv.split(this.csv.row)[0]).split(this.csv.cell);if (!this._csvAID)csv.splice(0,1);for (var i=0;i<csv.length;i++){var ed=this.cells3(r,i);ed[ed.setImage?"setLabel":"setValue"](csv[i])}};dhtmlXGridObject.prototype.addRowFromClipboard = function(){var csv=this.fromClipBoard();if (!csv)return;var z=csv.split(this.csv.row);for (var i=0;i<z.length;i++)if (z[i]){csv=z[i].split(this.csv.cell);if (this._csvAID)this.addRow(this.getRowsNum()+2,csv);else{if (this.rowsAr[csv[0]])csv[0]=this.uid();this.addRow(csv[0],csv.slice(1))}}};dhtmlXGridObject.prototype.gridToClipboard = function(){this.toClipBoard(this.serializeToCSV())};dhtmlXGridObject.prototype.gridFromClipboard = function(){var csv=this.fromClipBoard();if (!csv)return;this.loadCSVString(csv)};dhtmlXGridObject.prototype.getXLS = function(path){if (!this.xslform){this.xslform=document.createElement("FORM");this.xslform.action=(path||"")+"xls.php";this.xslform.method="post";this.xslform.target=(_isIE?"_blank":"");document.body.appendChild(this.xslform);var i1=document.createElement("INPUT");i1.type="hidden";i1.name="csv";this.xslform.appendChild(i1);var i2=document.createElement("INPUT");i2.type="hidden";i2.name="csv_header";this.xslform.appendChild(i2)};var cvs = this.serializeToCSV();this.xslform.childNodes[0].value = cvs;var cvs_header = [];var l = this._cCount;for (var i=0;i<l;i++){cvs_header.push(this.getHeaderCol(i))};cvs_header = cvs_header.join(',');this.xslform.childNodes[1].value = cvs_header;this.xslform.submit()};dhtmlXGridObject.prototype.printView = function(before,after){var html="<style>TD {font-family:Arial;text-align:center;padding-left:2px;padding-right:2px};\n td.filter input, td.filter select {display:none};\n </style>";var st_hr=null;if (this._fake){st_hr=[].concat(this._hrrar);for (var i=0;i<this._fake._cCount;i++)this._hrrar[i]=null};html+="<base href='"+document.location.href+"'></base>";if (!this.parentGrid)html+=(before||"");html += '<table width="100%" border="2px" cellpadding="0" cellspacing="0">';var row_length = Math.max(this.rowsBuffer.length,this.rowsCol.length);var col_length = this._cCount;var width = this._printWidth();html += '<tr class="header_row_1">';for (var i=0;i<col_length;i++){if (this._hrrar && this._hrrar[i])continue;var hcell=this.hdr.rows[1].cells[this.hdr.rows[1]._childIndexes?this.hdr.rows[1]._childIndexes[parseInt(i)]:i];var colspan=(hcell.colSpan||1);var rowspan=(hcell.rowSpan||1);for (var j=1;j<colspan;j++)width[i]+=width[j];html += '<td rowspan="'+rowspan+'" width="'+width[i]+'%" style="background-color:lightgrey;" colspan="'+colspan+'">'+this.getHeaderCol(i)+'</td>';i+=colspan-1};html += '</tr>';for (var i=2;i<this.hdr.rows.length;i++){if (_isIE){html+="<tr style='background-color:lightgrey' class='header_row_"+i+"'>";var cells=this.hdr.rows[i].childNodes;for (var j=0;j < cells.length;j++)if (!this._hrrar || !this._hrrar[cells[j]._cellIndex]){html+=cells[j].outerHTML};html+="</tr>"}else
 html+="<tr class='header_row_"+i+"' style='background-color:lightgrey'>"+(this._fake?this._fake.hdr.rows[i].innerHTML:"")+this.hdr.rows[i].innerHTML+"</tr>"};for (var i=0;i<row_length;i++){html += '<tr>';if (this.rowsCol[i] && this.rowsCol[i]._cntr){html+=this.rowsCol[i].innerHTML.replace(/<img[^>]*>/gi,"")+'</tr>';continue};if (this.rowsCol[i] && this.rowsCol[i].style.display=="none")continue;var row_id
 if (this.rowsCol[i])row_id=this.rowsCol[i].idd;else if (this.rowsBuffer[i])row_id=this.rowsBuffer[i].idd;else continue;for (var j=0;j<col_length;j++){if (this._hrrar && this._hrrar[j])continue;if(this.rowsAr[row_id] && this.rowsAr[row_id].tagName=="TR"){var c=this.cells(row_id, j);if (c._setState)var value="";else if (c.getContent)value = c.getContent();else if (c.getImage || c.combo)var value=c.cell.innerHTML;else var value = c.getValue()}else 
 var value=this._get_cell_value(this.rowsBuffer[i],j);var color = this.columnColor[j]?'background-color:'+this.columnColor[j]+';':'';var align = this.cellAlign[j]?'text-align:'+this.cellAlign[j]+';':'';var cspan = c.getAttribute("colspan");html += '<td style="'+color+align+'" '+(cspan?'colSpan="'+cspan+'"':'')+'>'+(value===""?"&nbsp;":value)+'</td>';if (cspan)j+=cspan-1};html += '</tr>';if (this.rowsCol[i] && this.rowsCol[i]._expanded){var sub=this.cells4(this.rowsCol[i]._expanded.ctrl);if (sub.getSubGrid)html += '<tr><td colspan="'+col_length+'">'+sub.getSubGrid().printView()+'</td></tr>';else
 html += '<tr><td colspan="'+col_length+'">'+this.rowsCol[i]._expanded.innerHTML+'</td></tr>'}};if (this.ftr)for (var i=1;i<this.ftr.childNodes[0].rows.length;i++)html+="<tr style='background-color:lightgrey'>"+((this._fake && _isFF)?this._fake.ftr.childNodes[0].rows[i].innerHTML:"")+this.ftr.childNodes[0].rows[i].innerHTML+"</tr>";html += '</table>';if (this.parentGrid)return html;html+=(after||"");var d = window.open('', '_blank');d.document.write(html);d.document.write("<script>window.onerror=function(){return true}</script>");d.document.close();if (this._fake){this._hrrar=st_hr}};dhtmlXGridObject.prototype._printWidth=function(){var width = [];var total_width = 0;for (var i=0;i<this._cCount;i++){var w = this.getColWidth(i);width.push(w);total_width += w};var percent_width = [];var total_percent_width = 0;for (var i=0;i<width.length;i++){var p = Math.floor((width[i]/total_width)*100);total_percent_width += p;percent_width.push(p)};percent_width[percent_width.length-1] += 100-total_percent_width;return percent_width};dhtmlXGridObject.prototype.loadObject = function(obj){};dhtmlXGridObject.prototype.loadJSONFile = function(path){};dhtmlXGridObject.prototype.serializeToObject = function(){};dhtmlXGridObject.prototype.serializeToJSON = function(){};if (!window.clipboardData)window.clipboardData={_make:function(){var clip = Components.classes['@mozilla.org/widget/clipboard;1'].createInstance(Components.interfaces.nsIClipboard);if (!clip)return null;var trans = Components.classes['@mozilla.org/widget/transferable;1'].createInstance(Components.interfaces.nsITransferable);if (!trans)return null;trans.addDataFlavor('text/unicode');var str = Components.classes["@mozilla.org/supports-string;1"].createInstance(Components.interfaces.nsISupportsString);this._p=[clip,trans,str];return true},
 setData:function(type,text){try{netscape.security.PrivilegeManager.enablePrivilege('UniversalXPConnect')}catch(e){dhtmlxError.throwError("Clipboard","Access to clipboard denied",[type,text]);return ""};if (!this._make()) return false;this._p[2].data=text;this._p[1].setTransferData("text/unicode",this._p[2],text.length*2);var clipid=Components.interfaces.nsIClipboard;this._p[0].setData(this._p[1],null,clipid.kGlobalClipboard)},
 getData:function(type){try{netscape.security.PrivilegeManager.enablePrivilege('UniversalXPConnect')}catch(e){dhtmlxError.throwError("Clipboard","Access to clipboard denied",[type]);return ""};if (!this._make()) return false;this._p[0].getData(this._p[1],this._p[0].kGlobalClipboard);var strLength = new Object();var str = new Object();try{this._p[1].getTransferData("text/unicode",str,strLength)}catch(e){return ""};if (str)str = str.value.QueryInterface(Components.interfaces.nsISupportsString);if (str)return str.data.substring(0,strLength.value / 2);return ""}};dhtmlXGridObject.prototype.enableBlockSelection = function(mode)
{if (typeof this._bs_mode == "undefined"){var self = this;this.obj.onmousedown = function(e) {if (self._bs_mode)self._OnSelectionStart((e||event),this);return true};this._CSVRowDelimiter = this.csv.row;this.attachEvent("onResize", function() {self._HideSelection();return true});this.attachEvent("onFilterEnd",this._HideSelection)};if (mode===false){this._bs_mode=false;return this._HideSelection()}else this._bs_mode=true};dhtmlXGridObject.prototype.forceLabelSelection = function(mode)
{this._strictText = convertStringToBoolean(mode)
};dhtmlXGridObject.prototype.disableBlockSelection = function()
{this.obj.onmousedown = null};dhtmlXGridObject.prototype._OnSelectionStart = function(event, obj)
{var self = this;if (event.button == 2)return;var src = event.srcElement || event.target;if (this.editor){if (src.tagName && (src.tagName=="INPUT" || src.tagName=="TEXTAREA")) return;this.editStop()};if (!self.isActive)self.setActive(true);var pos = this.getPosition(this.obj);var x = event.clientX - pos[0] +document.body.scrollLeft;var y = event.clientY - pos[1] +document.body.scrollTop;this._CreateSelection(x-4, y-4);if (src == this._selectionObj){this._HideSelection();this._startSelectionCell = null}else {while (src.tagName.toLowerCase()!= 'td')
 src = src.parentNode;this._startSelectionCell = src};this.obj.onmousedown = null;this.obj[_isIE?"onmouseleave":"onmouseout"] = function(e){if (self._blsTimer)window.clearTimeout(self._blsTimer)};this.obj.onmmold=this.obj.onmousemove;this._init_pos=[x,y];this.obj.onmousemove = function(e) {e = e||event;e.returnValue = false;self._OnSelectionMove(e)};this._oldDMP=document.body.onmouseup;document.body.onmouseup = function(e) {e = e||event;self._OnSelectionStop(e, this);return true};document.body.onselectstart = function(){return false}};dhtmlXGridObject.prototype._getCellByPos = function(x,y){x=x;y=y;var _x=0;for (var i=0;i < this.obj.rows.length;i++){y-=this.obj.rows[i].offsetHeight;if (y<=0){_x=this.obj.rows[i];break}};if (!_x || !_x.idd)return null;for (var i=0;i < this._cCount;i++){x-=this.obj.rows[0].childNodes[i].offsetWidth;if (x<=0){while(true){if (_x._childIndexes && _x._childIndexes[i+1]==_x._childIndexes[i])_x=_x.previousSibling;else 
 return this.cells(_x.idd,i).cell}}};return null};dhtmlXGridObject.prototype._OnSelectionMove = function(event)
{var self=this;this._ShowSelection();var pos = this.getPosition(this.obj);var X = event.clientX - pos[0]+document.body.scrollLeft;var Y = event.clientY - pos[1]+document.body.scrollTop;if ((Math.abs(this._init_pos[0]-X)<5) && (Math.abs(this._init_pos[1]-Y)<5)) return this._HideSelection();if(this._startSelectionCell==null)this._endSelectionCell = this._startSelectionCell = this.getFirstParentOfType(event.srcElement || event.target,"TD");else
 if (event.srcElement || event.target){if ((event.srcElement || event.target).className == "dhtmlxGrid_selection")
 this._endSelectionCell=(this._getCellByPos(X,Y)||this._endSelectionCell);else {var t = this.getFirstParentOfType(event.srcElement || event.target,"TD");if (t.parentNode.idd)this._endSelectionCell = t}};var BottomRightX = this.objBox.scrollLeft + this.objBox.clientWidth;var BottomRightY = this.objBox.scrollTop + this.objBox.clientHeight;var TopLeftX = this.objBox.scrollLeft;var TopLeftY = this.objBox.scrollTop;var nextCall=false;if (this._blsTimer)window.clearTimeout(this._blsTimer);if (X+20 >= BottomRightX){this.objBox.scrollLeft = this.objBox.scrollLeft+20;nextCall=true}else if (X-20 < TopLeftX){this.objBox.scrollLeft = this.objBox.scrollLeft-20;nextCall=true};if (Y+20 >= BottomRightY && !this._realfake){this.objBox.scrollTop = this.objBox.scrollTop+20;nextCall=true}else if (Y-20 < TopLeftY && !this._realfake){this.objBox.scrollTop = this.objBox.scrollTop-20;nextCall=true};this._selectionArea = this._RedrawSelectionPos(this._startSelectionCell, this._endSelectionCell);if (nextCall){var a=event.clientX;var b=event.clientY;this._blsTimer=window.setTimeout(function(){self._OnSelectionMove({clientX:a,clientY:b})},100)}};dhtmlXGridObject.prototype._OnSelectionStop = function(event)
{var self = this;if (this._blsTimer)window.clearTimeout(this._blsTimer);this.obj.onmousedown = function(e) {if (self._bs_mode)self._OnSelectionStart((e||event), this);return true};this.obj.onmousemove = this.obj.onmmold||null;document.body.onmouseup = this._oldDMP||null;if ( parseInt( this._selectionObj.style.width )< 2 && parseInt( this._selectionObj.style.height ) < 2) {this._HideSelection()}else {var src = this.getFirstParentOfType(event.srcElement || event.target,"TD");if ((!src)|| (!src.parentNode.idd)){src=this._endSelectionCell};if (!src)return this._HideSelection();while (src.tagName.toLowerCase()!= 'td')
 src = src.parentNode;this._stopSelectionCell = src;this._selectionArea = this._RedrawSelectionPos(this._startSelectionCell, this._stopSelectionCell);this.callEvent("onBlockSelected",[])};document.body.onselectstart = function(){}};dhtmlXGridObject.prototype._RedrawSelectionPos = function(LeftTop, RightBottom)
{var pos = {};pos.LeftTopCol = LeftTop._cellIndex;pos.LeftTopRow = this.getRowIndex( LeftTop.parentNode.idd );pos.RightBottomCol = RightBottom._cellIndex;pos.RightBottomRow = this.getRowIndex( RightBottom.parentNode.idd );var LeftTop_width = LeftTop.offsetWidth;var LeftTop_height = LeftTop.offsetHeight;LeftTop = this.getPosition(LeftTop, this.obj);var RightBottom_width = RightBottom.offsetWidth;var RightBottom_height = RightBottom.offsetHeight;RightBottom = this.getPosition(RightBottom, this.obj);if (LeftTop[0] < RightBottom[0]){var Left = LeftTop[0];var Right = RightBottom[0] + RightBottom_width}else {var foo = pos.RightBottomCol;pos.RightBottomCol = pos.LeftTopCol;pos.LeftTopCol = foo;var Left = RightBottom[0];var Right = LeftTop[0] + LeftTop_width};if (LeftTop[1] < RightBottom[1]){var Top = LeftTop[1];var Bottom = RightBottom[1] + RightBottom_height}else {var foo = pos.RightBottomRow;pos.RightBottomRow = pos.LeftTopRow;pos.LeftTopRow = foo;var Top = RightBottom[1];var Bottom = LeftTop[1] + LeftTop_height};var Width = Right - Left;var Height = Bottom - Top;this._selectionObj.style.left = Left + 'px';this._selectionObj.style.top = Top + 'px';this._selectionObj.style.width = Width + 'px';this._selectionObj.style.height = Height + 'px';return pos};dhtmlXGridObject.prototype._CreateSelection = function(x, y)
{if (this._selectionObj == null){var div = document.createElement('div');div.style.position = 'absolute';div.style.display = 'none';div.className = 'dhtmlxGrid_selection';this._selectionObj = div;this._selectionObj.onmousedown = function(e){e=e||event;if (e.button==2 || (_isMacOS&&e.ctrlKey))
 return this.parentNode.grid.callEvent("onBlockRightClick", ["BLOCK",e])};this._selectionObj.oncontextmenu=function(e){(e||event).cancelBubble=true;return false};this.objBox.appendChild(this._selectionObj)};this._selectionObj.style.width = '0px';this._selectionObj.style.height = '0px';this._selectionObj.style.left = x + 'px';this._selectionObj.style.top = y + 'px';this._selectionObj.startX = x;this._selectionObj.startY = y};dhtmlXGridObject.prototype._ShowSelection = function()
{if (this._selectionObj)this._selectionObj.style.display = ''};dhtmlXGridObject.prototype._HideSelection = function()
{if (this._selectionObj)this._selectionObj.style.display = 'none';this._selectionArea = null};dhtmlXGridObject.prototype.copyBlockToClipboard = function()
{if ( this._selectionArea != null ){var serialized = new Array();if (this._mathSerialization)this._agetm="getMathValue";else if (this._strictText)this._agetm="getTitle";else this._agetm="getValue";for (var i=this._selectionArea.LeftTopRow;i<=this._selectionArea.RightBottomRow;i++){var data = this._serializeRowToCVS(this.rowsBuffer[i], null, this._selectionArea.LeftTopCol, this._selectionArea.RightBottomCol+1);if (!this._csvAID)serialized[serialized.length] = data.substr( data.indexOf( this.csv.cell ) + 1 );else
 serialized[serialized.length] = data};serialized = serialized.join(this._CSVRowDelimiter);this.toClipBoard(serialized)}};dhtmlXGridObject.prototype.pasteBlockFromClipboard = function()
{var serialized = this.fromClipBoard();if (this._selectionArea != null){var startRow = this._selectionArea.LeftTopRow;var startCol = this._selectionArea.LeftTopCol}else if (this.cell != null && !this.editor){var startRow = this.getRowIndex( this.cell.parentNode.idd );var startCol = this.cell._cellIndex}else {return false};serialized = serialized.split(this._CSVRowDelimiter);if ((serialized.length >1)&&(serialized[serialized.length-1]==""))
 serialized.splice(serialized.length-1,1);for (var i=0;i<serialized.length;i++){serialized[i] = serialized[i].split(this.csv.cell)};var endRow = startRow+serialized.length;var endCol = startCol+serialized[0].length;if (endCol > this._cCount)endCol = this._cCount;var k = 0;for (var i=startRow;i<endRow;i++){var row = this.render_row(i);if (row==-1)continue;var l = 0;for (var j=startCol;j<endCol;j++){var ed = this.cells3(row, j);if (ed.isDisabled()) {l++;continue};if (this._onEditUndoRedo)this._onEditUndoRedo(2, row.idd, j, serialized[ k ][ l ], ed.getValue());if (ed.combo){var comboVa = ed.combo.values;for(var n=0;n<comboVa.length;n++)if (serialized[ k ][ l ] == comboVa[n]){ed.setValue( ed.combo.keys[ n ]);comboVa=null;break};if (comboVa!=null)ed.setValue( serialized[ k ][ l++ ] )}else
 ed[ ed.setImage ? "setLabel" : "setValue" ]( serialized[ k ][ l++ ] );ed.cell.wasChanged=true};this.callEvent("onRowPaste",[row.idd])
 k++}};dhtmlXGridObject.prototype.enablePaging = function(fl,pageSize,pagesInGrp,parentObj,showRecInfo,recInfoParentObj){this._pgn_parentObj = typeof(parentObj)=="string" ? document.getElementById(parentObj) : parentObj;this._pgn_recInfoParentObj = typeof(recInfoParentObj)=="string" ? document.getElementById(recInfoParentObj) : recInfoParentObj;this.pagingOn = fl;this.showRecInfo = showRecInfo;this.rowsBufferOutSize = parseInt(pageSize);this.currentPage = 1;this.pagesInGroup = parseInt(pagesInGrp);this._init_pgn_events()
 this.setPagingSkin("default")};dhtmlXGridObject.prototype.setXMLAutoLoading = function(filePath,bufferSize){this.xmlFileUrl = filePath;this._dpref = bufferSize};dhtmlXGridObject.prototype.changePageRelative = function(ind){this.changePage(this.currentPage+ind)};dhtmlXGridObject.prototype.changePage = function(pageNum){if (arguments.length==0)pageNum=this.currentPage||0;pageNum=parseInt(pageNum);pageNum=Math.max(1,Math.min(pageNum,Math.ceil(this.rowsBuffer.length/this.rowsBufferOutSize)));if(!this.callEvent("onBeforePageChanged",[this.currentPage,pageNum]))
 return;this.currentPage = parseInt(pageNum);this._reset_view();this._fixAlterCss();this.callEvent("onPageChanged",this.getStateOfView())};dhtmlXGridObject.prototype.setPagingSkin = function(name){this._pgn_skin=this["_pgn_"+name];if (name=="toolbar")this._pgn_skin_tlb=arguments[1]};dhtmlXGridObject.prototype.setPagingTemplates = function(a,b){this._pgn_templateA=this._pgn_template_compile(a);this._pgn_templateB=this._pgn_template_compile(b);this._page_skin_update()};dhtmlXGridObject.prototype._page_skin_update = function(name){if (!this.pagesInGroup)this.pagesInGroup=Math.ceil(Math.min(5,this.rowsBuffer.length/this.rowsBufferOutSize));var totalPages=Math.ceil(this.rowsBuffer.length/this.rowsBufferOutSize);if (totalPages && totalPages<this.currentPage)return this.changePage(totalPages);if (this.pagingOn && this._pgn_skin)this._pgn_skin.apply(this,this.getStateOfView())};dhtmlXGridObject.prototype._init_pgn_events = function(name){this.attachEvent("onXLE",this._page_skin_update)
 this.attachEvent("onClearAll",this._page_skin_update)
 this.attachEvent("onPageChanged",this._page_skin_update)
 this.attachEvent("onGridReconstructed",this._page_skin_update)
 
 this._init_pgn_events=function(){}};dhtmlXGridObject.prototype._pgn_default=function(page,start,end){if (!this.pagingBlock){this.pagingBlock = document.createElement("DIV");this.pagingBlock.className = "pagingBlock";this.recordInfoBlock = document.createElement("SPAN");this.recordInfoBlock.className = "recordsInfoBlock";if (!this._pgn_parentObj)return;this._pgn_parentObj.appendChild(this.pagingBlock)
 if(this._pgn_recInfoParentObj && this.showRecInfo)this._pgn_recInfoParentObj.appendChild(this.recordInfoBlock)
 
 
 if (!this._pgn_templateA){this._pgn_templateA=this._pgn_template_compile("[prevpages:&lt:&nbsp;] [currentpages:,&nbsp;] [nextpages:&gt:&nbsp;]");this._pgn_templateB=this._pgn_template_compile("Results <b>[from]-[to]</b> of <b>[total]</b>")}};var details=this.getStateOfView();this.pagingBlock.innerHTML = this._pgn_templateA.apply(this,details);this.recordInfoBlock.innerHTML = this._pgn_templateB.apply(this,details);this._pgn_template_active(this.pagingBlock);this._pgn_template_active(this.recordInfoBlock);this.callEvent("onPaging",[])};dhtmlXGridObject.prototype._pgn_block=function(sep){var start=Math.floor((this.currentPage-1)/this.pagesInGroup)*this.pagesInGroup;var max=Math.min(Math.ceil(this.rowsBuffer.length/this.rowsBufferOutSize),start+this.pagesInGroup);var str=[];for (var i=start+1;i<=max;i++)if (i==this.currentPage)str.push("<a class='dhx_not_active'><b>"+i+"</b></a>");else
 str.push("<a onclick='this.grid.changePage("+i+");return false;'>"+i+"</a>");return str.join(sep)};dhtmlXGridObject.prototype._pgn_link=function(mode,ac,ds){if (mode=="prevpages" || mode=="prev"){if (this.currentPage==1)return ds;return '<a onclick=\'this.grid.changePageRelative(-1*'+(mode=="prev"?'1':'this.grid.pagesInGroup')+');return false;\'>'+ac+'</a>'
 };if (mode=="nextpages" || mode=="next"){if (this.rowsBuffer.length/this.rowsBufferOutSize <= this.currentPage )return ds;if (this.rowsBuffer.length/(this.rowsBufferOutSize*(mode=="next"?'1':this.pagesInGroup)) <= 1 ) return ds;return '<a onclick=\'this.grid.changePageRelative('+(mode=="next"?'1':'this.grid.pagesInGroup')+');return false;\'>'+ac+'</a>'
 };if (mode=="current"){var i=this.currentPage+(ac?parseInt(ac):0);if (i<1 || Math.ceil(this.rowsBuffer.length/this.rowsBufferOutSize)< i ) return ds;return '<a '+(i==this.currentPage?"class='dhx_active_page_link' ":"")+'onclick=\'this.grid.changePage('+i+');return false;\'>'+i+'</a>'
 };return ac};dhtmlXGridObject.prototype._pgn_template_active=function(block){var tags=block.getElementsByTagName("A");if (tags)for (var i=0;i < tags.length;i++){tags[i].grid=this}};dhtmlXGridObject.prototype._pgn_template_compile=function(template){template=template.replace(/\[([^\]]*)\]/g,function(a,b){b=b.split(":");switch (b[0]){case "from": 
 return '"+(arguments[1]*1+(arguments[2]*1?1:0))+"';case "total":
 return '"+arguments[3]+"';case "to":
 return '"+arguments[2]+"';case "current":
 case "prev":
 case "next":
 case "prevpages":
 case "nextpages":
 return '"+this._pgn_link(\''+b[0]+'\',\''+b[1]+'\',\''+b[2]+'\')+"'
 case "currentpages":
 return '"+this._pgn_block(\''+b[1]+'\')+"'
 }})
 return new Function('return "'+template+'";')
};dhtmlXGridObject.prototype.i18n.paging={results:"Results",
 records:"Records from ",
 to:" to ",
 page:"Page ",
 perpage:"rows per page",
 first:"To first Page",
 previous:"Previous Page",
 found:"Found records",
 next:"Next Page",
 last:"To last Page",
 of:" of ",
 notfound:"No Records Found"
};dhtmlXGridObject.prototype.setPagingWTMode = function(navButtons,navLabel,pageSelect,perPageSelect){this._WTDef=[navButtons,navLabel,pageSelect,perPageSelect]};dhtmlXGridObject.prototype._pgn_bricks = function(page, start, end){var tmp = (this.skin_name||"").split("_")[1];var sfx="";if(tmp=="light" || tmp=="modern" || tmp=="skyblue")sfx = "_"+tmp;this.pagerElAr = new Array();this.pagerElAr["pagerCont"] = document.createElement("DIV");this.pagerElAr["pagerBord"] = document.createElement("DIV");this.pagerElAr["pagerLine"] = document.createElement("DIV");this.pagerElAr["pagerBox"] = document.createElement("DIV");this.pagerElAr["pagerInfo"] = document.createElement("DIV");this.pagerElAr["pagerInfoBox"] = document.createElement("DIV");var se = (this.globalBox||this.objBox);this.pagerElAr["pagerCont"].style.width = se.clientWidth+"px";this.pagerElAr["pagerCont"].style.overflow = "hidden";this.pagerElAr["pagerCont"].style.clear = "both";this.pagerElAr["pagerBord"].className = "dhx_pbox"+sfx;this.pagerElAr["pagerLine"].className = "dhx_pline"+sfx;this.pagerElAr["pagerBox"].style.clear = "both";this.pagerElAr["pagerInfo"].className = "dhx_pager_info"+sfx;this.pagerElAr["pagerCont"].appendChild(this.pagerElAr["pagerBord"]);this.pagerElAr["pagerCont"].appendChild(this.pagerElAr["pagerLine"]);this.pagerElAr["pagerCont"].appendChild(this.pagerElAr["pagerInfo"]);this.pagerElAr["pagerLine"].appendChild(this.pagerElAr["pagerBox"]);this.pagerElAr["pagerInfo"].appendChild(this.pagerElAr["pagerInfoBox"]);this._pgn_parentObj.innerHTML = "";this._pgn_parentObj.appendChild(this.pagerElAr["pagerCont"]);if(this.rowsBuffer.length>0){var lineWidth = 20;var lineWidthInc = 22;if(page>this.pagesInGroup){var pageCont = document.createElement("DIV");var pageBox = document.createElement("DIV");pageCont.className = "dhx_page"+sfx;pageBox.innerHTML = "&larr;";pageCont.appendChild(pageBox);this.pagerElAr["pagerBox"].appendChild(pageCont);var self = this;pageCont.pgnum = (Math.ceil(page/this.pagesInGroup)-1)*this.pagesInGroup;pageCont.onclick = function(){self.changePage(this.pgnum)};lineWidth +=lineWidthInc};for(var i=1;i<=this.pagesInGroup;i++){var pageCont = document.createElement("DIV");var pageBox = document.createElement("DIV");pageCont.className = "dhx_page"+sfx;pageNumber = ((Math.ceil(page/this.pagesInGroup)-1)*this.pagesInGroup)+i;if(pageNumber>Math.ceil(this.rowsBuffer.length/this.rowsBufferOutSize))
 break;pageBox.innerHTML = pageNumber;pageCont.appendChild(pageBox);if(page==pageNumber){pageCont.className += " dhx_page_active"+sfx;pageBox.className = "dhx_page_active"+sfx}else{var self = this;pageCont.pgnum = pageNumber;pageCont.onclick = function(){self.changePage(this.pgnum)}};lineWidth +=(parseInt(lineWidthInc/3)*pageNumber.toString().length)+15;pageBox.style.width = (parseInt(lineWidthInc/3)*pageNumber.toString().length)+8+"px";this.pagerElAr["pagerBox"].appendChild(pageCont)};if(Math.ceil(page/this.pagesInGroup)*this.pagesInGroup<Math.ceil(this.rowsBuffer.length/this.rowsBufferOutSize)){var pageCont = document.createElement("DIV");var pageBox = document.createElement("DIV");pageCont.className = "dhx_page"+sfx;pageBox.innerHTML = "&rarr;";pageCont.appendChild(pageBox);this.pagerElAr["pagerBox"].appendChild(pageCont);var self = this;pageCont.pgnum = (Math.ceil(page/this.pagesInGroup)*this.pagesInGroup)+1;pageCont.onclick = function(){self.changePage(this.pgnum)};lineWidth +=lineWidthInc};this.pagerElAr["pagerLine"].style.width = lineWidth+"px"};if(this.rowsBuffer.length>0 && this.showRecInfo)this.pagerElAr["pagerInfoBox"].innerHTML = this.i18n.paging.records+(start+1)+this.i18n.paging.to+end+this.i18n.paging.of+this.rowsBuffer.length;else if(this.rowsBuffer.length==0){this.pagerElAr["pagerLine"].parentNode.removeChild(this.pagerElAr["pagerLine"]);this.pagerElAr["pagerInfoBox"].innerHTML = this.i18n.paging.notfound};this.pagerElAr["pagerBox"].appendChild(document.createElement("SPAN")).innerHTML = "&nbsp;";this.pagerElAr["pagerBord"].appendChild(document.createElement("SPAN")).innerHTML = "&nbsp;";this.pagerElAr["pagerCont"].appendChild(document.createElement("SPAN")).innerHTML = "&nbsp;";this.callEvent("onPaging",[])};dhtmlXGridObject.prototype._pgn_toolbar = function(page, start, end){if (!this.aToolBar)this.aToolBar=this._pgn_createToolBar();var totalPages=Math.ceil(this.rowsBuffer.length/this.rowsBufferOutSize);if (this._WTDef[0]){this.aToolBar.enableItem("right");this.aToolBar.enableItem("rightabs");this.aToolBar.enableItem("left");this.aToolBar.enableItem("leftabs");if(this.currentPage==totalPages){this.aToolBar.disableItem("right");this.aToolBar.disableItem("rightabs")};if(this.currentPage==1){this.aToolBar.disableItem("left");this.aToolBar.disableItem("leftabs")}};if (this._WTDef[2]){var that=this;this.aToolBar.forEachListOption("pages", function(id){that.aToolBar.removeListOption("pages",id)});for(var i=0;i<totalPages;i++){this.aToolBar.addListOption('pages', 'pages_'+(i+1), NaN, "button", this.i18n.paging.page+(i+1))};this.aToolBar.setItemText("pages","<div style='width:100%;text-align:right'>"+this.i18n.paging.page+page+"</div>")};if (this._WTDef[1]){if (!this.getRowsNum())
 this.aToolBar.setItemText('results',this.i18n.paging.notfound);else
 this.aToolBar.setItemText('results',"<div style='width:100%;text-align:center'>"+this.i18n.paging.records+(start+1)+this.i18n.paging.to+end+"</div>")};if (this._WTDef[3])this.aToolBar.setItemText("perpagenum","<div style='width:100%;text-align:right'>"+this.rowsBufferOutSize.toString()+" "+this.i18n.paging.perpage+"</div>");this.callEvent("onPaging",[])};dhtmlXGridObject.prototype._pgn_createToolBar = function(){this.aToolBar = new dhtmlXToolbarObject(this._pgn_parentObj,(this._pgn_skin_tlb||"dhx_blue"));if (!this._WTDef)this.setPagingWTMode(true,true,true,true);var self=this;this.aToolBar.attachEvent("onClick",function(val){val=val.split("_")
 switch (val[0]){case "leftabs":
 self.changePage(1);break;case "left":
 self.changePage(self.currentPage-1);break;case "rightabs":
 self.changePage(99999);break;case "right":
 self.changePage(self.currentPage+1);break;case "perpagenum":
 if (val[1]===this.undefined)return;self.rowsBufferOutSize = parseInt(val[1]);self.changePage();self.aToolBar.setItemText("perpagenum","<div style='width:100%;text-align:right'>"+val[1]+" "+self.i18n.paging.perpage+"</div>");break;case "pages":
 if (val[1]===this.undefined)return;self.changePage(val[1]);self.aToolBar.setItemText("pages","<div style='width:100%;text-align:right'>"+self.i18n.paging.page+val[1]+"</div>");break}})
 
 if (this._WTDef[0]){this.aToolBar.addButton("leftabs", NaN, "", this.imgURL+'ar_left_abs.gif', this.imgURL+'ar_left_abs_dis.gif');this.aToolBar.setWidth("leftabs","20")
 this.aToolBar.addButton("left", NaN, "", this.imgURL+'ar_left.gif', this.imgURL+'ar_left_dis.gif');this.aToolBar.setWidth("left","20")
 };if (this._WTDef[1]){this.aToolBar.addText("results",NaN,this.i18n.paging.results)
 this.aToolBar.setWidth("results","150")
 };if (this._WTDef[0]){this.aToolBar.addButton("right", NaN, "", this.imgURL+'ar_right.gif', this.imgURL+'ar_right_dis.gif');this.aToolBar.setWidth("right","20")
 this.aToolBar.addButton("rightabs", NaN, "", this.imgURL+'ar_right_abs.gif', this.imgURL+'ar_right_abs_dis.gif');this.aToolBar.setWidth("rightabs","20")
 };if (this._WTDef[2]){this.aToolBar.addButtonSelect("pages", NaN, "select page",[]);this.aToolBar.setWidth("pages","75")
 };if (this._WTDef[3]){this.aToolBar.addButtonSelect("perpagenum", NaN, "select size",[]);for (var k=5;k<35;k+=5)this.aToolBar.addListOption('perpagenum', 'perpagenum_'+k, NaN, "button", k+" "+this.i18n.paging.perpage);this.aToolBar.setWidth("perpagenum","130")
 };this.aToolBar.disableItem("results");return this.aToolBar};dhtmlXGridObject.prototype.hidePivot=function(cont){if (this._pgridCont){if (this._pgrid)this._pgrid.destructor();var c=this._pgridCont.parentNode;c.innerHTML="";if (c.parentNode==this.entBox)this.entBox.removeChild(c);this._pgrid=this._pgridSelect=this._pUNI=this._pgridCont=null}};dhtmlXGridObject.prototype.makePivot=function(cont,details){details=details||{};this.hidePivot();if (!cont){var cont=document.createElement("DIV");cont.style.cssText="position:absolute;top:0px;left:0px;background-color:white;";cont.style.height=this.entBox.offsetHeight+"px";cont.style.width=this.entBox.offsetWidth+"px";if (this.entBox.style.position!="absolute")this.entBox.style.position="relative";this.entBox.appendChild(cont)};if (typeof(cont)!="object") cont=document.getElementById(cont)
 
 if (details.column_list)this._column_list=details.column_list;else{this._column_list=[];for (var i=0;i<this.hdr.rows[1].cells.length;i++)this._column_list.push(this.hdr.rows[1].cells[i][_isIE?"innerText":"textContent"])
 };var that = this;cont.innerHTML="<table cellspacing='0' cellpadding='0'><tr><td style='width:160px' align='center'></td><td>&nbsp;&nbsp;&nbsp;</td><td></td></tr></table><div></div>";var z1=this.makePivotSelect(this._column_list);z1.style.width="80px";z1.onchange=function(){if (this.value!=-1)that._pivotS.value=this.value;else that._pivotS.value="";that._reFillPivotLists();that._renderPivot2()};var z2=this.makePivotSelect(this._column_list);z2.onchange=function(){if (this.value!=-1)that._pivotS.x=this.value;else that._pivotS.x="";that._reFillPivotLists();that._renderPivot()
 };var z3=this.makePivotSelect(this._column_list);z3.onchange=function(){if (this.value!=-1)that._pivotS.y=this.value;else that._pivotS.y="";that._reFillPivotLists();that._renderPivot()
 };var z4=this.makePivotSelect(["Sum","Min","Max","Average","Count"],-1);z4.style.width="70px";z4.onchange=function(){if (this.value!=-1)that._pivotS.action=this.value;else that._pivotS.action=null;that._renderPivot2()};if (details.readonly)z1.disabled=z2.disabled=z3.disabled=z4.disabled=true;cont.firstChild.rows[0].cells[0].appendChild(z4);cont.firstChild.rows[0].cells[0].appendChild(z1);cont.firstChild.rows[0].cells[2].appendChild(z2);var gr=cont.childNodes[1];gr.style.width=cont.offsetWidth+"px";gr.style.height=cont.offsetHeight-20+"px";gr.style.overflow="hidden";this._pgridCont=gr;this._pgridSelect=[z1,z2,z3,z4];this._pData=this._fetchPivotData();this._pUNI=[];this._pivotS={action:(details.action||"0"), value:(typeof details.value != "undefined" ? (details.value||"0") : null), x:(typeof details.x != "undefined" ? (details.x||"0") : null), y:(typeof details.y != "undefined" ? (details.y||"0") : null) };z1.value=this._pivotS.value;z2.value=this._pivotS.x;z3.value=this._pivotS.y;z4.value=this._pivotS.action;that._reFillPivotLists();this._renderPivot()};dhtmlXGridObject.prototype._fetchPivotData=function(){var z=[];for (var i=0;i<this._cCount;i++){var d=[];for (var j=0;j<this.rowsCol.length;j++){if (this.rowsCol[j]._cntr)continue;d.push(this.cells2(j,i).getValue())};z.push(d)
 };return z};dhtmlXGridObject.prototype._renderPivot=function(){if (_isIE)this._pgridSelect[2].removeNode(true)
 if (this._pgrid)this._pgrid.destructor();this._pgrid=new dhtmlXGridObject(this._pgridCont);this._pgrid.attachEvent("onBeforeSelect",function(){return false});if (this._pivotS.x){var l=this._getUniList(this._pivotS.x);var s=[160];for (var i=0;i < l.length;i++)s.push(100);l=[""].concat(l)
 this._pgrid.setHeader(l);this._pgrid.setInitWidths(s.join(","))}else {this._pgrid.setHeader("");this._pgrid.setInitWidths("160")};this._pgrid.init();this._pgrid.setEditable(false);this._pgrid.setSkin(this.entBox.className.replace("gridbox gridbox_",""));var t=this._pgrid.hdr.rows[1].cells[0];if (t.firstChild && t.firstChild.tagName=="DIV")t=t.firstChild;t.appendChild(this._pgridSelect[2]);this._pgrid.setSizes();if (this._pivotS.y){var l=this._getUniList(this._pivotS.y);for (var i=0;i < l.length;i++){this._pgrid.addRow(this._pgrid.uid(),[l[i]],-1)}}else {this._pgrid.addRow(1,"not ready",1)};this._renderPivot2()};dhtmlXGridObject.prototype._pivot_action_0=function(a,b,c,av,bv,data){var ret=0;var resA=data[a];var resB=data[b];var resC=data[c];for (var i = resA.length - 1;i >= 0;i--)if (resA[i]==av && resB[i]==bv)ret+=parseFloat(resC[i]);return ret};dhtmlXGridObject.prototype._pivot_action_1=function(a,b,c,av,bv,data){ret=9999999999;var resA=data[a];var resB=data[b];var resC=data[c];for (var i = resA.length - 1;i >= 0;i--)if (resA[i]==av && resB[i]==bv)ret=Math.min(parseFloat(resC[i]),ret);if (ret==9999999999)ret="";return ret};dhtmlXGridObject.prototype._pivot_action_2=function(a,b,c,av,bv,data){ret=-9999999999;var resA=data[a];var resB=data[b];var resC=data[c];for (var i = resA.length - 1;i >= 0;i--)if (resA[i]==av && resB[i]==bv)ret=Math.max(parseFloat(resC[i]),ret);if (ret==-9999999999)ret="";return ret};dhtmlXGridObject.prototype._pivot_action_3=function(a,b,c,av,bv,data){var ret=0;var count=0;var resA=data[a];var resB=data[b];var resC=data[c];for (var i = resA.length - 1;i >= 0;i--)if (resA[i]==av && resB[i]==bv){ret+=parseFloat(resC[i]);count++};return count?ret/count:""};dhtmlXGridObject.prototype._pivot_action_4=function(a,b,c,av,bv,data){var ret=0;var count=0;var resA=data[a];var resB=data[b];var resC=data[c];for (var i = resA.length - 1;i >= 0;i--)if (resA[i]==av && resB[i]==bv){ret++};return ret};dhtmlXGridObject.prototype._renderPivot2=function(){if (!(this._pivotS.x && this._pivotS.y && this._pivotS.value && this._pivotS.action)) return;var action=this["_pivot_action_"+this._pivotS.action];var x=this._getUniList(this._pivotS.x);var y=this._getUniList(this._pivotS.y);for (var i=0;i < x.length;i++){for (var j=0;j < y.length;j++){this._pgrid.cells2(j,i+1).setValue(Math.round(action(this._pivotS.x,this._pivotS.y,this._pivotS.value,x[i],y[j],this._pData)*100)/100)}}};dhtmlXGridObject.prototype._getUniList=function(col){if (!this._pUNI[col]){var t={};var a=[];for (var i = this._pData[col].length - 1;i >= 0;i--){t[this._pData[col][i]]=true};for (var n in t)if (t[n]===true)a.push(n);this._pUNI[col]=a.sort()};return this._pUNI[col]};dhtmlXGridObject.prototype._fillPivotList=function(z,list,miss,v){if (!miss){miss={};v=-1};z.innerHTML="";z.options[z.options.length]=new Option("-select-",-1);for (var i=0;i<list.length;i++){if (miss[i] || list[i]===null)continue;z.options[z.options.length]=new Option(list[i],i)};z.value=parseInt(v)};dhtmlXGridObject.prototype._reFillPivotLists=function(){var s=[];var v=[];for (var i=0;i<3;i++){s.push(this._pgridSelect[i]);v.push(s[i].value)};var t=this._reFfillPivotLists;var m={};m[v[1]]=m[v[2]]=true;this._fillPivotList(s[0],this._column_list,m,v[0]);m={};m[v[0]]=m[v[2]]=true;this._fillPivotList(s[1],this._column_list,m,v[1]);m={};m[v[1]]=m[v[0]]=true;this._fillPivotList(s[2],this._column_list,m,v[2]);this._reFfillPivotLists=t};dhtmlXGridObject.prototype.makePivotSelect=function(list,miss){var z=document.createElement("SELECT");this._fillPivotList(z,list,miss);z.style.cssText="width:150px;height:20px;font-family:Tahoma;font-size:8pt;font-weight:normal;";return z};dhtmlXGridObject.prototype.setRowspan=function(rowID,colInd,length){var c=this[this._bfs_cells?"_bfs_cells":"cells"](rowID,colInd).cell;var r=this.rowsAr[rowID];if (c.rowSpan && c.rowSpan!=1){var ur=r.nextSibling;for (var i=1;i<c.rowSpan;i++){var tc=ur.childNodes[ur._childIndexes[c._cellIndex+1]]
 var ti=document.createElement("TD");ti.innerHTML="&nbsp;";ti._cellIndex=c._cellIndex;ti._clearCell=true;if (tc)tc.parentNode.insertBefore(ti,tc);else
 tc.parentNode.appendChild(ti);this._shiftIndexes(ur,c._cellIndex,-1);ur=ur.nextSibling}};c.rowSpan=length;if (!this._h2)r=r.nextSibling||this.rowsCol[this.rowsCol._dhx_find(r)+1];else
 r=this.rowsAr[ this._h2.get[r.idd].parent.childs[this._h2.get[r.idd].index+1].id ];var kids=[];for (var i=1;i<length;i++){var ct=null;if (this._fake && !this._realfake)ct=this._bfs_cells3(r,colInd).cell;else
 ct=this.cells3(r,colInd).cell;this._shiftIndexes(r,c._cellIndex,1);if (ct)ct.parentNode.removeChild(ct);kids.push(r);if (!this._h2)r=r.nextSibling||this.rowsCol[this.rowsCol._dhx_find(r)+1];else {var r=this._h2.get[r.idd].parent.childs[this._h2.get[r.idd].index+1];if (r)r=this.rowsAr[ r.id ]}};this.rowsAr[rowID]._rowSpan=this.rowsAr[rowID]._rowSpan||{};this.rowsAr[rowID]._rowSpan[colInd]=kids;if (this._fake && !this._realfake && colInd<this._fake._cCount)this._fake.setRowspan(rowID,colInd,length)
};dhtmlXGridObject.prototype._shiftIndexes=function(r,pos,ind){if (!r._childIndexes){r._childIndexes=new Array();for (var z=0;z<r.childNodes.length;z++)r._childIndexes[z]=z};for (var z=0;z<r._childIndexes.length;z++)if (z>pos)r._childIndexes[z]=r._childIndexes[z]-ind};dhtmlXGridObject.prototype.enableRowspan=function(){this._erspan=true;this.enableRowspan=function(){};this.attachEvent("onAfterSorting",function(){if (this._dload)return;for (var i=1;i<this.obj.rows.length;i++)if (this.obj.rows[i]._rowSpan){var master=this.obj.rows[i];for (var kname in master._rowSpan){var row=master;var kids=row._rowSpan[kname];for (var j=0;j < kids.length;j++){if(row.nextSibling)row.parentNode.insertBefore(kids[j],row.nextSibling);else 
 row.parentNode.appendChild(kids[j]);if (this._fake){var frow=this._fake.rowsAr[row.idd];var fkid=this._fake.rowsAr[kids[j].idd];if(frow.nextSibling)frow.parentNode.insertBefore(fkid,frow.nextSibling);else 
 frow.parentNode.appendChild(fkid);this._correctRowHeight(row.idd)};row=row.nextSibling}}};this.rowsCol=new dhtmlxArray();for (var i=1;i<this.obj.rows.length;i++)this.rowsCol.push(this.obj.rows[i])}) 
 
 this.attachEvent("onXLE",function(a,b,c,xml){var spans=this.xmlLoader.doXPath("//cell[@rowspan]",xml);for (var i=0;i<spans.length;i++){var p=spans[i].parentNode;var rid=p.getAttribute("id");var len=spans[i].getAttribute("rowspan");var ind=0;for (var j=0;j < p.childNodes.length;j++){if (p.childNodes[j].tagName=="cell"){if (p.childNodes[j] == spans[i])break;else
 ind++}};this.setRowspan(rid,ind,len) 
 }})
};dhtmlXGridObject.prototype._init_point_bspl=dhtmlXGridObject.prototype._init_point;dhtmlXGridObject.prototype._init_point = function(){if (this._split_later)this.splitAt(this._split_later);this._init_point=this._init_point_bspl;if (this._init_point)this._init_point()};dhtmlXGridObject.prototype.splitAt=function(ind){if (!this.obj.rows[0])return this._split_later=ind;ind=parseInt(ind);var leftBox=document.createElement("DIV");this.entBox.appendChild(leftBox);var rightBox=document.createElement("DIV");this.entBox.appendChild(rightBox);for (var i=this.entBox.childNodes.length-3;i>=0;i--)rightBox.insertBefore(this.entBox.childNodes[i],rightBox.firstChild);this.entBox.style.position="relative";this.globalBox=this.entBox;this.entBox=rightBox;rightBox.grid=this;leftBox.style.cssText+="border:0px solid red !important;";rightBox.style.cssText+="border:0px solid red !important;";rightBox.style.top="0px";rightBox.style.position="absolute";leftBox.style.position="absolute";leftBox.style.top="0px";leftBox.style.left="0px";leftBox.style.zIndex=11;rightBox.style.height=leftBox.style.height=this.globalBox.clientHeight;this._fake=new dhtmlXGridObject(leftBox);this._fake.setSkin("not_existing_skin");this.globalBox=this._fake.globalBox=this.globalBox;this._fake._fake=this;this._fake._realfake=true;this._treeC=this.cellType._dhx_find("tree");this._fake.delim=this.delim;this._fake.customGroupFormat=this.customGroupFormat;this._fake.imgURL=this.imgURL;this._fake._customSorts=this._customSorts;this._fake.noHeader=this.noHeader;this._fake._enbTts=this._enbTts;this._fake.clists = this.clists;this._fake.fldSort=new Array();this._fake.selMultiRows=this.selMultiRows;this._fake.multiLine=this.multiLine;if (this.multiLine || this._erspan){this.attachEvent("onCellChanged",this._correctRowHeight);var corrector=function(){this.forEachRow(function(id){this._correctRowHeight(id)})
 };this.attachEvent("onPageChanged",corrector);this.attachEvent("onXLE",corrector);this.attachEvent("onResizeEnd",corrector);if (!this._ads_count)this.attachEvent("onAfterSorting",corrector);this.attachEvent("onDistributedEnd",corrector)};this.attachEvent("onGridReconstructed",function(){this._fake.objBox.scrollTop = this.objBox.scrollTop})
 
 this._fake.loadedKidsHash=this.loadedKidsHash;if (this._h2)this._fake._h2=this._h2;this._fake._dInc=this._dInc;var b_ha=[[],[],[],[],[],[],[]];var b_ar=["hdrLabels","initCellWidth","cellType","cellAlign","cellVAlign","fldSort","columnColor"];var b_fu=["setHeader","setInitWidths","setColTypes","setColAlign","setColVAlign","setColSorting","setColumnColor"];this._fake.callEvent=function(){this._fake._split_event=true;if (arguments[0]=="onGridReconstructed")this._fake.callEvent.apply(this,arguments);return this._fake.callEvent.apply(this._fake,arguments);this._fake._split_event=false};if (this._elmn)this._fake.enableLightMouseNavigation(true);if (this.__cssEven||this._cssUnEven)this._fake.attachEvent("onGridReconstructed",function(){this._fixAlterCss()});this._fake._cssEven=this._cssEven;this._fake._cssUnEven=this._cssUnEven;this._fake._cssSP=this._cssSP;this._fake.isEditable=this.isEditable;this._fake._edtc=this._edtc;if (this._sst)this._fake.enableStableSorting(true);this._fake._sclE=this._sclE;this._fake._dclE=this._dclE;this._fake._f2kE=this._f2kE;this._fake._maskArr=this._maskArr;this._fake._dtmask=this._dtmask;this._fake.combos=this.combos;var width=0;var m_w=this.globalBox.offsetWidth;for (var i=0;i<ind;i++){for (var j=0;j<b_ar.length;j++){if (this[b_ar[j]])b_ha[j][i]=this[b_ar[j]][i];if (typeof b_ha[j][i] == "string")b_ha[j][i]=b_ha[j][i].replace(new RegExp("\\"+this.delim,"g"),"\\"+this.delim)};if (_isFF)b_ha[1][i]=b_ha[1][i]*1+2;if ( this.cellWidthType == "%"){b_ha[1][i]=Math.round(parseInt(this[b_ar[1]][i])*m_w/100);width+=b_ha[1][i]}else
 width+=parseInt(this[b_ar[1]][i]);this.setColumnHidden(i,true)};for (var j=0;j<b_ar.length;j++){var str=b_ha[j].join(this.delim);if (b_fu[j]!="setHeader"){if (str!="")this._fake[b_fu[j]](str)}else
 this._fake[b_fu[j]](str,null,this._hstyles)};this._fake._strangeParams=this._strangeParams;this._fake._drsclmn=this._drsclmn;rightBox.style.left=width+"px";leftBox.style.width=width+"px";rightBox.style.width=Math.max(this.globalBox.offsetWidth-width,0);if (this._ecspn)this._fake._ecspn=true;this._fake.init();if (this.dragAndDropOff)this.dragger.addDragLanding(this._fake.entBox, this);this._fake.objBox.style.overflow="hidden";this._fake.objBox.style.overflowX="scroll";this._fake._srdh=this._srdh||20;this._fake._srnd=this._srnd;function change_td(a,b){b.style.whiteSpace="";var c=b.nextSibling;var cp=b.parentNode;a.parentNode.insertBefore(b,a);if (!c)cp.appendChild(a);else
 cp.insertBefore(a,c);var z=a.style.display;a.style.display=b.style.display;b.style.display=z};function proc_hf(i,rows,mode,frows){var temp_header=(new Array(ind)).join(this.delim);var temp_rspan=[];if (i==2)for (var k=0;k<ind;k++){var r=rows[i-1].cells[rows[i-1]._childIndexes?rows[i-1]._childIndexes[k]:k];if (r.rowSpan && r.rowSpan>1){temp_rspan[r._cellIndex]=r.rowSpan-1;frows[i-1].cells[frows[i-1]._childIndexes?frows[i-1]._childIndexes[k]:k].rowSpan=r.rowSpan;r.rowSpan=1}};for (i;i<rows.length;i++){this._fake.attachHeader(temp_header,null,mode);frows=frows||this._fake.ftr.childNodes[0].rows;var max_ind=ind;var r_cor=0;for (var j=0;j<max_ind;j++){if (temp_rspan[j]){temp_rspan[j]=temp_rspan[j]-1;if (_isIE || (_isFF && _FFrv >= 1.9 )|| _isOpera) {var td=document.createElement("TD");if (_isFF)td.style.display="none";rows[i].insertBefore(td,rows[i].cells[0])
 };r_cor++;continue};var a=frows[i].cells[j-r_cor];var b=rows[i].cells[j-(_isIE?0:r_cor)];var t=b.rowSpan;change_td(a,b);if (t>1){temp_rspan[j]=t-1;b.rowSpan=t};if (frows[i].cells[j].colSpan>1){rows[i].cells[j].colSpan=frows[i].cells[j].colSpan;max_ind-=frows[i].cells[j].colSpan-1;for (var k=1;k < frows[i].cells[j].colSpan;k++)frows[i].removeChild(frows[i].cells[j+1])}}}};if (this.hdr.rows.length>2)proc_hf.call(this,2,this.hdr.rows,"_aHead",this._fake.hdr.rows);if (this.ftr){proc_hf.call(this,1,this.ftr.childNodes[0].rows,"_aFoot");this._fake.ftr.parentNode.style.bottom=(_isFF?2:1)+"px"};if (this.saveSizeToCookie){this.saveSizeToCookie=function(name,cookie_param){if (this._realfake)return this._fake.saveSizeToCookie.apply(this._fake,arguments);if (!name)name=this.entBox.id;var z=new Array();var n="cellWidthPX";for (var i=0;i<this[n].length;i++)if (i<ind)z[i]=this._fake[n][i];else
 z[i]=this[n][i];z=z.join(",")
 this.setCookie(name,cookie_param,0,z);var z=(this.initCellWidth||(new Array)).join(",");this.setCookie(name,cookie_param,1,z);return true};this.loadSizeFromCookie=function(name){if (!name)name=this.entBox.id;var z=this._getCookie(name,1);if (!z)return
 this.initCellWidth=z.split(",");var z=this._getCookie(name,0);var n="cellWidthPX";this.cellWidthType="px";var summ2=0;if ((z)&&(z.length)){z=z.split(",");for (var i=0;i<z.length;i++)if (i<ind){this._fake[n][i]=z[i];summ2+=z[i]*1}else
 this[n][i]=z[i]};this._fake.entBox.style.width=summ2+"px";this._fake.objBox.style.width=summ2+"px";var pa=this.globalBox.childNodes[1];pa.style.left=summ2-(_isFF?0:0)+"px";if (this.ftr)this.ftr.style.left=summ2-(_isFF?0:0)+"px";pa.style.width=this.globalBox.offsetWidth-summ2+"px";this.setSizes();return true};this._fake.onRSE=this.onRSE};this.setCellTextStyleA=this.setCellTextStyle;this.setCellTextStyle=function(row_id,i,styleString){if (i<ind)this._fake.setCellTextStyle(row_id,i,styleString);this.setCellTextStyleA(row_id,i,styleString)};this.setRowTextBoldA=this.setRowTextBold;this.setRowTextBold = function(row_id){this.setRowTextBoldA(row_id);this._fake.setRowTextBold(row_id)};this.setRowColorA=this.setRowColor;this.setRowColor = function(row_id,color){this.setRowColorA(row_id,color);this._fake.setRowColor(row_id,color)};this.setRowHiddenA=this.setRowHidden;this.setRowHidden = function(id,state){this.setRowHiddenA(id,state);this._fake.setRowHidden(id,state)};this.setRowTextNormalA=this.setRowTextNormal;this.setRowTextNormal = function(row_id){this.setRowTextNormalA(row_id);this._fake.setRowTextNormal(row_id)};this.getChangedRows = function(and_added){var res = new Array();function test(row){for (var j = 0;j < row.childNodes.length;j++)if (row.childNodes[j].wasChanged)return res[res.length]=row.idd};this.forEachRow(function(id){var row = this.rowsAr[id];var frow = this._fake.rowsAr[id];if (row.tagName!="TR" || frow.tagName!="TR")return;if (and_added && row._added)res[res.length]=row.idd;else{if (!test(row)) test(frow)}});return res.join(this.delim)};this.setRowTextStyleA=this.setRowTextStyle;this.setRowTextStyle = function(row_id,styleString){this.setRowTextStyleA(row_id,styleString);if (this._fake.rowsAr[row_id])this._fake.setRowTextStyle(row_id,styleString)};this.lockRowA = this.lockRow;this.lockRow = function(id,mode){this.lockRowA(id,mode);this._fake.lockRow(id,mode)};this.getColWidth = function(i){if (i<ind)return parseInt(this._fake.cellWidthPX[i])+((_isFF)?2:0);else return parseInt(this.cellWidthPX[i])+((_isFF)?2:0)};this.setColWidthA=this._fake.setColWidthA=this.setColWidth;this.setColWidth = function(i,value){i=i*1;if (i<ind)this._fake.setColWidthA(i,value-((_isFF) ? 2 : 0));else this.setColWidthA(i,value-((_isFF) ? 2 : 0));if ((i+1)<=ind) this._fake._correctSplit(Math.min(this._fake.objBox.offsetWidth,this._fake.obj.offsetWidth))};this.adjustColumnSizeA=this.adjustColumnSize;this.setColumnLabelA=this.setColumnLabel;this.setColumnLabel=function(a,b,c,d){var that = this;if (a<ind)that = this._fake;return this.setColumnLabelA.apply(that,[a,b,c,d])};this.adjustColumnSize=function(aind,c){if (aind<ind){if (_isIE)this._fake.obj.style.tableLayout="";this._fake.adjustColumnSize(aind,c);if (_isIE)this._fake.obj.style.tableLayout="fixed";this._fake._correctSplit()}else return this.adjustColumnSizeA(aind,c)};var zname="cells";this._bfs_cells=this[zname];this[zname]=function(){if (arguments[1]<ind){return this._fake.cells.apply(this._fake,arguments)}else
 return this._bfs_cells.apply(this,arguments)};this._bfs_setColumnHidden=this.setColumnHidden;this.setColumnHidden=function(){if (parseInt(arguments[0])<ind){this._fake.setColumnHidden.apply(this._fake,arguments);return this._fake._correctSplit()}else
 return this._bfs_setColumnHidden.apply(this,arguments)};var zname="cells2";this._bfs_cells2=this[zname];this[zname]=function(){if (arguments[1]<ind)return this._fake.cells2.apply(this._fake,arguments);else
 return this._bfs_cells2.apply(this,arguments)};var zname="cells3";this._bfs_cells3=this[zname];this[zname]=function(a,b){if (arguments[1]<ind && this._fake.rowsAr[arguments[0].idd]){if (this._fake.rowsAr[a.idd] && this._fake.rowsAr[a.idd].childNodes.length==0)return this._bfs_cells3.apply(this,arguments);arguments[0]=arguments[0].idd;return this._fake.cells.apply(this._fake,arguments)}else
 return this._bfs_cells3.apply(this,arguments)};var zname="changeRowId";this._bfs_changeRowId=this[zname];this[zname]=function(){this._bfs_changeRowId.apply(this,arguments);if (this._fake.rowsAr[arguments[0]])this._fake.changeRowId.apply(this._fake,arguments)};this._fake.getRowById=function(id){var row = this.rowsAr[id];if (!row && this._fake.rowsAr[id])row=this._fake.getRowById(id);if (row){if (row.tagName != "TR"){for (var i = 0;i < this.rowsBuffer.length;i++)if (this.rowsBuffer[i] && this.rowsBuffer[i].idd == id)return this.render_row(i);if (this._h2)return this.render_row(null,row.idd)};return row};return null};if (this.collapseKids){this._fake["_bfs_collapseKids"]=this.collapseKids;this._fake["collapseKids"]=function(){return this._fake["collapseKids"].apply(this._fake,[this._fake.rowsAr[arguments[0].idd]])};this["_bfs_collapseKids"]=this.collapseKids;this["collapseKids"]=function(){var z=this["_bfs_collapseKids"].apply(this,arguments);this._fake._h2syncModel();if (!this._cssSP)this._fake._fixAlterCss()};this._fake["_bfs_expandKids"]=this.expandKids;this._fake["expandKids"]=function(){this._fake["expandKids"].apply(this._fake,[this._fake.rowsAr[arguments[0].idd]]);if (!this._cssSP)this._fake._fixAlterCss()};this["_bfs_expandAll"]=this.expandAll;this["expandAll"]=function(){this._bfs_expandAll();this._fake._h2syncModel();if (!this._cssSP)this._fake._fixAlterCss()};this["_bfs_collapseAll"]=this.collapseAll;this["collapseAll"]=function(){this._bfs_collapseAll();this._fake._h2syncModel();if (!this._cssSP)this._fake._fixAlterCss()};this["_bfs_expandKids"]=this.expandKids;this["expandKids"]=function(){var z=this["_bfs_expandKids"].apply(this,arguments);this._fake._h2syncModel();if (!this._cssSP)this._fake._fixAlterCss()};this._fake._h2syncModel=function(){if (this._fake.pagingOn)this._fake._renderSort();else this._renderSort()};this._updateTGRState=function(a){return this._fake._updateTGRState(a)}};if (this._elmnh){this._setRowHoverA=this._fake._setRowHoverA=this._setRowHover;this._unsetRowHoverA=this._fake._unsetRowHoverA=this._unsetRowHover;this._setRowHover=this._fake._setRowHover=function(){var that=this.grid;that._setRowHoverA.apply(this,arguments);var z=(_isIE?event.srcElement:arguments[0].target);z=that._fake.rowsAr[that.getFirstParentOfType(z,'TD').parentNode.idd];if (z){that._fake._setRowHoverA.apply(that._fake.obj,[{target:z.childNodes[0]},arguments[1]])}};this._unsetRowHover=this._fake._unsetRowHover=function(){if (arguments[1])var that=this;else var that=this.grid;that._unsetRowHoverA.apply(this,arguments);that._fake._unsetRowHoverA.apply(that._fake.obj,arguments)};this._fake.enableRowsHover(true,this._hvrCss);this.enableRowsHover(false);this.enableRowsHover(true,this._fake._hvrCss)};this._updateTGRState=function(z){if (!z.update || z.id==0)return;if (this.rowsAr[z.id].imgTag)this.rowsAr[z.id].imgTag.src=this.imgURL+z.state+".gif";if (this._fake.rowsAr[z.id] && this._fake.rowsAr[z.id].imgTag)this._fake.rowsAr[z.id].imgTag.src=this.imgURL+z.state+".gif";z.update=false};this.copy_row=function(row){var x=row.cloneNode(true);x._skipInsert=row._skipInsert;var r_ind=ind;x._attrs={};if (this._ecspn){r_ind=0;for (var i=0;(i<x.childNodes.length && i<ind);i+=(x.childNodes[i].colSpan||1))
 r_ind++};while (x.childNodes.length>r_ind)x.removeChild(x.childNodes[x.childNodes.length-1]);var zm=r_ind;for (var i=0;i<zm;i++){if (this.dragAndDropOff)this.dragger.addDraggableItem(x.childNodes[i], this);x.childNodes[i].style.display=(this._fake._hrrar?(this._fake._hrrar[i]?"none":""):"");x.childNodes[i]._cellIndex=i;x.childNodes[i].combo_value=arguments[0].childNodes[i].combo_value;x.childNodes[i]._clearCell=arguments[0].childNodes[i]._clearCell;x.childNodes[i]._cellType=arguments[0].childNodes[i]._cellType;x.childNodes[i]._brval=arguments[0].childNodes[i]._brval;x.childNodes[i]._attrs=arguments[0].childNodes[i]._attrs;x.childNodes[i].chstate=arguments[0].childNodes[i].chstate;if (row._attrs['style'])x.childNodes[i].style.cssText+=";"+row._attrs['style'];if(x.childNodes[i].colSpan>1)this._childIndexes=this._fake._childIndexes};if (this._h2 && this._treeC < ind){var trow=this._h2.get[arguments[0].idd];x.imgTag=x.childNodes[this._treeC].childNodes[0].childNodes[trow.level];x.valTag=x.childNodes[this._treeC].childNodes[0].childNodes[trow.level+2]};x.idd=row.idd;x.grid=this._fake;return x};var zname="_insertRowAt";this._bfs_insertRowAt=this[zname];this[zname]=function(){var r=this["_bfs_insertRowAt"].apply(this,arguments);arguments[0]=this.copy_row(arguments[0]);var r2=this._fake["_insertRowAt"].apply(this._fake,arguments);if (r._fhd){r2.parentNode.removeChild(r2);this._fake.rowsCol._dhx_removeAt(this._fake.rowsCol._dhx_find(r2));r._fhd=false};return r};this._bfs_setSizes=this.setSizes;this.setSizes=function(){if (this._notresize)return;this._bfs_setSizes(this,arguments);this.sync_headers()
 if (this.sync_scroll()&& this._ahgr) this.setSizes();this._fake.entBox.style.height=this.entBox.style.height;this._fake.objBox.style.height=this.objBox.style.height;this._fake.hdrBox.style.height=this.hdrBox.style.height;this._fake.objBox.scrollTop=this.objBox.scrollTop;this._fake.setColumnSizes(this._fake.entBox.clientWidth);this.globalBox.style.width=parseInt(this.entBox.style.width)+parseInt(this._fake.entBox.style.width);this.globalBox.style.height=this.entBox.style.height};this.sync_scroll=this._fake.sync_scroll=function(end){var old=this.objBox.style.overflowX;if (this.obj.offsetWidth<=this.objBox.offsetWidth){if (!end)return this._fake.sync_scroll(true);this.objBox.style.overflowX="hidden";this._fake.objBox.style.overflowX="hidden"}else{this.objBox.style.overflowX="scroll";this._fake.objBox.style.overflowX="scroll"};return old!=this.objBox.style.overflowX};this.sync_headers=this._fake.sync_headers=function(){if (this.noHeader || (this._fake.hdr.scrollHeight==this.hdr.offsetHeight)) return;for (var i=1;i<this.hdr.rows.length;i++){var ha=this.hdr.rows[i].scrollHeight;var hb=this._fake.hdr.rows[i].scrollHeight;if (ha!=hb)this._fake.hdr.rows[i].style.height=this.hdr.rows[i].style.height=Math.max(ha,hb)+"px";if (window._KHTMLrv)this._fake.hdr.rows[i].childNodes[0].style.height=this.hdr.rows[i].childNodes[ind].style.height=Math.max(ha,hb)+"px"};this._fake.sync_headers};this._fake._bfs_setSizes=this._fake.setSizes;this._fake.setSizes=function(){if (this._fake._notresize)return;this._fake.setSizes()};var zname="_doOnScroll";this._bfs__doOnScroll=this[zname];this[zname]=function(){this._bfs__doOnScroll.apply(this,arguments);this._fake.objBox.scrollTop=this.objBox.scrollTop;this._fake["_doOnScroll"].apply(this._fake,arguments)};var zname="doClick";this._bfs_doClick=this[zname];this[zname]=function(){this["_bfs_doClick"].apply(this,arguments);if (arguments[0].tagName=="TD"){var fl=(arguments[0]._cellIndex>=ind);if (!arguments[0].parentNode.idd)return;if (!fl)arguments[0].className=arguments[0].className.replace(/cellselected/g,"");if (!this._fake.rowsAr[arguments[0].parentNode.idd])this._fake.render_row(this.getRowIndex(arguments[0].parentNode.idd));arguments[0]=this._fake.cells(arguments[0].parentNode.idd,(fl?0:arguments[0]._cellIndex)).cell;if (fl)this._fake.cell=null;this._fake["_bfs_doClick"].apply(this._fake,arguments);if (fl)this._fake.cell=this.cell;else this.cell=this._fake.cell;if (this._fake.onRowSelectTime)clearTimeout(this._fake.onRowSelectTime)
 if (fl){arguments[0].className=arguments[0].className.replace(/cellselected/g,"");globalActiveDHTMLGridObject=this;this._fake.cell=this.cell}else{this.objBox.scrollTop=this._fake.objBox.scrollTop}}};this._fake._bfs_doClick=this._fake[zname];this._fake[zname]=function(){this["_bfs_doClick"].apply(this,arguments);if (arguments[0].tagName=="TD"){var fl=(arguments[0]._cellIndex<ind);if (!arguments[0].parentNode.idd)return;arguments[0]=this._fake._bfs_cells(arguments[0].parentNode.idd,(fl?ind:arguments[0]._cellIndex)).cell;this._fake.cell=null;this._fake["_bfs_doClick"].apply(this._fake,arguments);this._fake.cell=this.cell;if (this._fake.onRowSelectTime)clearTimeout(this._fake.onRowSelectTime)
 if (fl){arguments[0].className=arguments[0].className.replace(/cellselected/g,"");globalActiveDHTMLGridObject=this;this._fake.cell=this.cell;this._fake.objBox.scrollTop=this.objBox.scrollTop}}};this.clearSelectionA = this.clearSelection;this.clearSelection = function(mode){if (mode)this._fake.clearSelection();this.clearSelectionA()};this.moveRowUpA = this.moveRowUp;this.moveRowUp = function(row_id){if (!this._h2)this._fake.moveRowUp(row_id);this.moveRowUpA(row_id);if (this._h2)this._fake._h2syncModel()};this.moveRowDownA = this.moveRowDown;this.moveRowDown = function(row_id){if (!this._h2)this._fake.moveRowDown(row_id);this.moveRowDownA(row_id);if (this._h2)this._fake._h2syncModel()};this._fake.getUserData=function(){return this._fake.getUserData.apply(this._fake,arguments)};this._fake.setUserData=function(){return this._fake.setUserData.apply(this._fake,arguments)};this.getSortingStateA=this.getSortingState;this.getSortingState = function(){var z=this.getSortingStateA();if (z.length!=0)return z;return this._fake.getSortingState()};this.setSortImgStateA=this._fake.setSortImgStateA=this.setSortImgState;this.setSortImgState = function(a,b,c,d){this.setSortImgStateA(a,b,c,d);if (b*1<ind){this._fake.setSortImgStateA(a,b,c,d);this.setSortImgStateA(false)}else 
 this._fake.setSortImgStateA(false)};this._fake.doColResizeA = this._fake.doColResize;this._fake.doColResize = function(ev,el,startW,x,tabW){a=-1;var z=0;if (arguments[1]._cellIndex==(ind-1)){a = this._initalSplR + (ev.clientX-x);if (!this._initalSplF)this._initalSplF=arguments[3]+this.objBox.scrollWidth-this.objBox.offsetWidth;if (this.objBox.scrollWidth==this.objBox.offsetWidth && (this._fake.alter_split_resize || (ev.clientX-x)>0 )){arguments[3]=(this._initalSplF||arguments[3]);z=this.doColResizeA.apply(this,arguments)}else
 z=this.doColResizeA.apply(this,arguments)}else{if (this.obj.offsetWidth<this.entBox.offsetWidth)a=this.obj.offsetWidth;z=this.doColResizeA.apply(this,arguments)};this._correctSplit(a);this.resized=this._fake.resized=1;return z};this._fake.changeCursorState = function(ev){var el = ev.target||ev.srcElement;if(el.tagName!="TD")el = this.getFirstParentOfType(el,"TD")
 if ((el.tagName=="TD")&&(this._drsclmn)&&(!this._drsclmn[el._cellIndex])) return;var check = (ev.layerX||0)+(((!_isIE)&&(ev.target.tagName=="DIV"))?el.offsetLeft:0);var pos = parseInt(this.getPosition(el,this.hdrBox));if(((el.offsetWidth - (ev.offsetX||(pos-check)*-1))<(_isOpera?20:10))||((this.entBox.offsetWidth - (ev.offsetX?(ev.offsetX+el.offsetLeft):check) + this.objBox.scrollLeft - 0)<(_isOpera?20:10))){el.style.cursor = "E-resize"}else
 el.style.cursor = "default";if (_isOpera)this.hdrBox.scrollLeft = this.objBox.scrollLeft};this._fake.startColResizeA = this._fake.startColResize;this._fake.startColResize = function(ev){var z=this.startColResizeA(ev);this._initalSplR=this.entBox.offsetWidth;this._initalSplF=null;if (this.entBox.onmousemove){var m=this.entBox.parentNode;if (m._aggrid)return z;m._aggrid=m.grid;m.grid=this;this.entBox.parentNode.onmousemove=this.entBox.onmousemove;this.entBox.onmousemove=null};return z};this._fake.stopColResizeA = this._fake.stopColResize;this._fake.stopColResize = function(ev){if (this.entBox.parentNode.onmousemove){var m=this.entBox.parentNode;m.grid=m._aggrid;m._aggrid=null;this.entBox.onmousemove=this.entBox.parentNode.onmousemove;this.entBox.parentNode.onmousemove=null;if (this.obj.offsetWidth<this.entBox.offsetWidth)this._correctSplit(this.obj.offsetWidth)};return this.stopColResizeA(ev)};this.doKeyA = this.doKey;this._fake.doKeyA = this._fake.doKey;this._fake.doKey=this.doKey=function(ev){if (!ev)return true;if (this._htkebl)return true;if ((ev.target||ev.srcElement).value !== window.undefined){var zx = (ev.target||ev.srcElement);if ((!zx.parentNode)||(zx.parentNode.className.indexOf("editable") == -1))
 return true};switch (ev.keyCode){case 9:
 if (!ev.shiftKey){if (this._realfake){if ((this.cell)&&(this.cell._cellIndex==(ind-1))){if (ev.preventDefault)ev.preventDefault();var ind_t=ind;while (this._fake._hrrar && this._fake._hrrar[ind_t])ind_t++;this._fake.selectCell(this.getRowIndex(this.cell.parentNode.idd),ind_t,false,false,true);return false}else
 var z=this.doKeyA(ev);globalActiveDHTMLGridObject=this;return z}else{if (this.cell){var ind_t=this.cell._cellIndex+1;while (this.rowsCol[0].childNodes[ind_t] && this.rowsCol[0].childNodes[ind_t].style.display=="none")ind_t++;if (ind_t == this.rowsCol[0].childNodes.length){if (ev.preventDefault)ev.preventDefault();var z=this.rowsBuffer[this.getRowIndex(this.cell.parentNode.idd)+1];if (z){this.showRow(z.idd);this._fake.selectCell(this._fake.getRowIndex(z.idd),0,false,false,true)};return false}};return this.doKeyA(ev)}}else{if (this._realfake){if ((this.cell)&&(this.cell._cellIndex==0)){if (ev.preventDefault)ev.preventDefault();var z=this.rowsBuffer[this.getRowIndex(this.cell.parentNode.idd)-1];if (z){this._fake.showRow(z.idd);this._fake.selectCell(this._fake.getRowIndex(z.idd),this._fake._cCount-1,false,false,true)};return false}else
 return this.doKeyA(ev)}else{if ((this.cell)&&(this.cell._cellIndex==ind)){if (ev.preventDefault)ev.preventDefault();this._fake.selectCell(this.getRowIndex(this.cell.parentNode.idd),ind-1,false,false,true);return false}else
 return this.doKeyA(ev)}};break};return this.doKeyA(ev)};this.editCellA=this.editCell;this.editCell=function(){if (!this.cell && this._fake.cell)return this._fake.editCell();return this.editCellA()};this.deleteRowA = this.deleteRow;this.deleteRow=function(row_id,node){if (this.deleteRowA(row_id,node)===false) return false;if (this._fake.rowsAr[row_id])this._fake.deleteRow(row_id)};this.clearAllA = this.clearAll;this.clearAll=function(){this.clearAllA();this._fake.clearAll()};this.attachEvent("onAfterSorting",function(i,b,c){if (i>=ind)this._fake.setSortImgState(false)
}) 



this._fake.sortField = function(a,b,c){this._fake.sortField.call(this._fake,a,b,this._fake.hdr.rows[0].cells[a]);if (this.fldSort[a]!="na"){var mem = this._fake.getSortingState()[1];this._fake.setSortImgState(false);this.setSortImgState(true,arguments[0],mem)
 }};this.sortTreeRowsA = this.sortTreeRows;this._fake.sortTreeRowsA = this._fake.sortTreeRows;this.sortTreeRows=this._fake.sortTreeRows=function(col,type,order,ar){if (this._realfake)return this._fake.sortTreeRows(col,type,order,ar)

 this.sortTreeRowsA(col,type,order,ar);this._fake._h2syncModel();this._fake.setSortImgStateA(false);this._fake.fldSorted=null};this._fake._fillers=[];this._fake.rowsBuffer=this.rowsBuffer;this.attachEvent("onClearAll",function(){this._fake.rowsBuffer=this.rowsBuffer})
this._add_filler_s=this._add_filler;this._add_filler=function(a,b,c,e){if (!e){if (!this._fake._fillers)this._fake._fillers=[];var d;if (c){if (c.idd)d=this._fake.rowsAr[c.idd];else if (c.nextSibling){d = {};d.nextSibling=this._fake.rowsAr[c.nextSibling.idd];d.parentNode=d.nextSibling.parentNode}};this._fake._fillers.push(this._fake._add_filler(a,b,d))};return this._add_filler_s.apply(this,arguments)};this._add_from_buffer_s=this._add_from_buffer;this._add_from_buffer=function() {var res=this._add_from_buffer_s.apply(this,arguments);if (res!=-1){this._fake._add_from_buffer.apply(this._fake,arguments);if (this.multiLine)this._correctRowHeight(this.rowsBuffer[arguments[0]].idd)};return res};this._fake.render_row=function(ind){var row=this._fake.render_row(ind);if (row == -1)return -1;if (row){return this.rowsAr[row.idd]=this.rowsAr[row.idd]||this._fake.copy_row(row)};return null};this._reset_view_s=this._reset_view;this._reset_view=function(){this._fake._reset_view(true);this._fake._fillers=[];this._reset_view_s()};this.moveColumn_s=this.moveColumn;this.moveColumn=function(a,b){if (b>=ind)return this.moveColumn_s(a,b)};this.attachEvent("onCellChanged",function(id,i,val){if (this._split_event && i<ind && this.rowsAr[id]){var cell=this._fake.rowsAr[id];if (!cell)return;if (cell._childIndexes)cell=cell.childNodes[cell._childIndexes[i]];else
 cell=cell.childNodes[i];this.rowsAr[id].childNodes[i].innerHTML=cell.innerHTML;this.rowsAr[id].childNodes[i]._clearCell=false;this.rowsAr[id].childNodes[i].chstate=cell.chstate}})





 this._fake.combos=this.combos;this.setSizes();if (this.rowsBuffer[0])this._reset_view();this.attachEvent("onXLE",function(){this._fake._correctSplit()})
 this._fake._correctSplit()};dhtmlXGridObject.prototype._correctSplit=function(a){a=a||(this.obj.scrollWidth-this.objBox.scrollLeft);if (a>-1){this.entBox.style.width=a+"px";this.objBox.style.width=a+"px";var outerBorder=(this.globalBox.offsetWidth-this.globalBox.clientWidth)/2;this._fake.entBox.style.left=a+"px";this._fake.entBox.style.width=Math.max(0,this.globalBox.offsetWidth-a-(this.quirks?0:2)*outerBorder)+"px";if (_isIE){var quirks=_isIE && !window.xmlHttpRequest;var outerBorder=(this.globalBox.offsetWidth-this.globalBox.clientWidth);this._fake.hdrBox.style.width=this._fake.objBox.style.width=Math.max(0,this.globalBox.offsetWidth-(quirks?outerBorder:0)-a)+"px"}}};dhtmlXGridObject.prototype._correctRowHeight=function(id,ind){if (!this.rowsAr[id] || !this._fake.rowsAr[id])return;var h=this.rowsAr[id].offsetHeight;var h2=this._fake.rowsAr[id].offsetHeight;var max = Math.max(h,h2);if (!max)return;this.rowsAr[id].style.height=this._fake.rowsAr[id].style.height=max+"px";if (window._KHTMLrv)this.rowsAr[id].childNodes[this._fake._cCount].style.height=this._fake.rowsAr[id].firstChild.style.height=max+"px"};dhtmlXGridObject.prototype.enableSmartRendering=function(mode,buffer,reserved){if (arguments.length>2){if (buffer && !this.rowsBuffer[buffer-1])this.rowsBuffer[buffer-1]=0;buffer=reserved};this._srnd=convertStringToBoolean(mode);this._srdh=this._srdh||20;this._dpref=buffer||0};dhtmlXGridObject.prototype.enablePreRendering=function(buffer){this._srnd_pr=parseInt(buffer||50)};dhtmlXGridObject.prototype.forceFullLoading=function(buffer){buffer=buffer||50;for (var i=0;i<this.rowsBuffer.length;i++)if (!this.rowsBuffer[i]){if (this.callEvent("onDynXLS",[i,buffer])){var self=this;this.load(this.xmlFileUrl+getUrlSymbol(this.xmlFileUrl)+"posStart="+i+"&count="+buffer, function(){window.setTimeout(function(){self.forceFullLoading()},100)}, this._data_type)};return}};dhtmlXGridObject.prototype.setAwaitedRowHeight = function(height) {this._srdh=parseInt(height)};dhtmlXGridObject.prototype._get_view_size=function(){return Math.floor(parseInt(this.entBox.offsetHeight)/this._srdh)+2};dhtmlXGridObject.prototype._add_filler=function(pos,len,fil){if (!len)return null;var id="__filler__";var row=this._prepareRow(id);row.firstChild.style.width="1px";for (var i=1;i<row.childNodes.length;i++)row.childNodes[i].style.display='none';row.firstChild.style.height=len*this._srdh+"px";fil=fil||this.rowsCol[pos];if (fil && fil.nextSibling)fil.parentNode.insertBefore(row,fil.nextSibling);else
 if (_isKHTML)this.obj.appendChild(row);else
 this.obj.rows[0].parentNode.appendChild(row);return [pos,len,row]};dhtmlXGridObject.prototype._update_srnd_view=function(){var min=Math.floor(this.objBox.scrollTop/this._srdh);var max=min+this._get_view_size();if (this.multiLine){var pxHeight = this.objBox.scrollTop;min = 0;while(pxHeight > 0){pxHeight-=this.rowsCol[min]?this.rowsCol[min].offsetHeight:this._srdh;min++};max=min+this._get_view_size();if (min>0)min--};max+=(this._srnd_pr||0);if (max>this.rowsBuffer.length)max=this.rowsBuffer.length;for (var j=min;j<max;j++){if (!this.rowsCol[j]){var res=this._add_from_buffer(j);if (res==-1){if (this.xmlFileUrl){this._current_load=[j,(this._dpref?this._dpref:(max-j))];if (this.callEvent("onDynXLS",[j,this._current_load[1]]))
 this.load(this.xmlFileUrl+getUrlSymbol(this.xmlFileUrl)+"posStart="+j+"&count="+this._current_load[1], this._data_type)};return}else {if (this._tgle){this._updateLine(this._h2.get[this.rowsBuffer[j].idd],this.rowsBuffer[j]);this._updateParentLine(this._h2.get[this.rowsBuffer[j].idd],this.rowsBuffer[j])};if (j && j==(this._realfake?this._fake:this)["_r_select"]){this.selectCell(j, this.cell?this.cell._cellIndex:0, true)}}}};if (this._fake && !this._realfake && this.multiLine)this._fake.objBox.scrollTop = this.objBox.scrollTop};dhtmlXGridObject.prototype._add_from_buffer=function(ind){var row=this.render_row(ind);if (row==-1)return -1;if (row._attrs["selected"] || row._attrs["select"]){this.selectRow(row,false,true);row._attrs["selected"]=row._attrs["select"]=null};if (!this._cssSP){if (this._cssEven && ind%2 == 0 )row.className=this._cssEven+((row.className.indexOf("rowselected") != -1)?" rowselected ":" ")+(row._css||"");else if (this._cssUnEven && ind%2 == 1 )row.className=this._cssUnEven+((row.className.indexOf("rowselected") != -1)?" rowselected ":" ")+(row._css||"")}else if (this._h2){var x=this._h2.get[row.idd];row.className+=" "+((x.level%2)?(this._cssUnEven+" "+this._cssUnEven):(this._cssEven+" "+this._cssEven))+"_"+x.level+(this.rowsAr[x.id]._css||"")};for (var i=0;i<this._fillers.length;i++){var f=this._fillers[i];if (f && f[0]<=ind && (f[0]+f[1])>ind ){var pos=ind-f[0];if (pos==0){this._insert_before(ind,row,f[2]);this._update_fillers(i,-1,1)}else if (pos == f[1]-1){this._insert_after(ind,row,f[2]);this._update_fillers(i,-1,0)}else {this._fillers.push(this._add_filler(ind+1,f[1]-pos-1,f[2],1));this._insert_after(ind,row,f[2]);this._update_fillers(i,-f[1]+pos,0)};return}}};dhtmlXGridObject.prototype._update_fillers=function(ind,right,left){var f=this._fillers[ind];f[1]=f[1]+right;f[0]=f[0]+left;if (!f[1]){f[2].parentNode.removeChild(f[2]);this._fillers.splice(ind,1)}else 
 f[2].firstChild.style.height=parseFloat(f[2].firstChild.style.height)+right*this._srdh+"px"};dhtmlXGridObject.prototype._insert_before=function(ind,row,fil){fil.parentNode.insertBefore(row,fil);this.rowsCol[ind]=row};dhtmlXGridObject.prototype._insert_after=function(ind,row,fil){if (fil.nextSibling)fil.parentNode.insertBefore(row,fil.nextSibling);else
 fil.parentNode.appendChild(row);this.rowsCol[ind]=row};dhtmlXGridObject.prototype.enableAutoSizeSaving = function(name,cookie_param){this.attachEvent("onResizeEnd",function(){this.saveSizeToCookie(name,cookie_param) })};dhtmlXGridObject.prototype.saveOpenStates = function(name,cookie_param){if (!name)name=this.entBox.id;var t=[];this._h2.forEachChild(0,function(el){if (el.state=="minus")t.push(el.id)});var str = "gridOpen"+(name||"") + "=" + t.join("|") + (cookie_param?(";"+cookie_param):"");document.cookie = str};dhtmlXGridObject.prototype.loadOpenStates = function(name,cookie_param){var val=this.getCookie(name,"gridOpen");if (!val)return;val=val.split("|");for (var i=0;i < val.length;i++)this.openItem(val[i])};dhtmlXGridObject.prototype.enableAutoHiddenColumnsSaving = function(name,cookie_param){this.attachEvent("onColumnHidden",function(){this.saveHiddenColumnsToCookie(name,cookie_param)})};dhtmlXGridObject.prototype.enableSortingSaving = function(name,cookie_param){this.attachEvent("onBeforeSorting",function(){var that=this;window.setTimeout(function(){that.saveSortingToCookie(name,cookie_param)},1);return true})};dhtmlXGridObject.prototype.enableOrderSaving = function(name,cookie_param){this.attachEvent("onAfterCMove",function(){this.saveOrderToCookie(name,cookie_param);this.saveSizeToCookie(name,cookie_param)})};dhtmlXGridObject.prototype.enableAutoSaving = function(name,cookie_param){this.enableOrderSaving(name,cookie_param);this.enableAutoSizeSaving(name,cookie_param);this.enableSortingSaving(name,cookie_param)};dhtmlXGridObject.prototype.saveSizeToCookie=function(name,cookie_param){if (this.cellWidthType=='px')var z=this.cellWidthPX.join(",");else
 var z=this.cellWidthPC.join(",");var z2=(this.initCellWidth||(new Array)).join(",");this.setCookie(name,cookie_param,0,z);this.setCookie(name,cookie_param,1,z2)};dhtmlXGridObject.prototype.saveHiddenColumnsToCookie=function(name,cookie_param){var hs=[].concat(this._hrrar||[]);if (this._fake && this._fake._hrrar)for (var i=0;i < this._fake._cCount;i++)hs[i]=this._fake._hrrar[i]?"1":"";this.setCookie(name,cookie_param,4,hs.join(",").replace(/display:none;/g,"1"))};dhtmlXGridObject.prototype.loadHiddenColumnsFromCookie=function(name){var z=this._getCookie(name,4);var ar=(z||"").split(",");if (ar.length>this._cCount || !z)return;for (var i=0;i < ar.length;i++)this.setColumnHidden(i,(ar[i]?true:false))};dhtmlXGridObject.prototype.saveSortingToCookie=function(name,cookie_param){this.setCookie(name,cookie_param,2,(this.getSortingState()||[]).join(","))};dhtmlXGridObject.prototype.loadSortingFromCookie=function(name){var z=this._getCookie(name,2);z=(z||"").split(",");if (z.length>1 && z[0]<this._cCount){this.sortRows(z[0],null,z[1]);this.setSortImgState(true,z[0],z[1])}};dhtmlXGridObject.prototype.saveOrderToCookie=function(name,cookie_param){if (!this._c_order){this._c_order=[];var l=this._cCount;for (var i=0;i<l;i++)this._c_order[i]=i};this.setCookie(name,cookie_param,3,((this._c_order||[]).slice(0,this._cCount)).join(","))};dhtmlXGridObject.prototype.loadOrderFromCookie=function(name){var z=this._getCookie(name,3);z=(z||"").split(",");if (z.length>1 && z.length<=this._cCount){for (var i=0;i<z.length;i++)if ((!this._c_order && z[i]!=i)||(this._c_order && z[i]!=this._c_order[i])){var t=z[i];if (this._c_order)for (var j=0;j<this._c_order.length;j++){if (this._c_order[j]==z[i]){t=j;break}};this.moveColumn(t*1,i)}}};dhtmlXGridObject.prototype.loadSizeFromCookie=function(name){var z=this._getCookie(name,1);if (z)this.initCellWidth=z.split(",");var z=this._getCookie(name,0);if ((z)&&(z.length)){if (!this._fake && this._hrrar)for (var i=0;i<z.length;i++)if ( this._hrrar[i])z[i]=0;if (this.cellWidthType=='px')this.cellWidthPX=z.split(",");else
 this.cellWidthPC=z.split(",")};this.setSizes();return true};dhtmlXGridObject.prototype.clearConfigCookie=function(name){if (!name)name=this.entBox.id;var str = "gridSettings"+name + "=||||";document.cookie = str};dhtmlXGridObject.prototype.clearSizeCookie=dhtmlXGridObject.prototype.clearConfigCookie;dhtmlXGridObject.prototype.setCookie=function(name,cookie_param,pos,value) {if (!name)name=this.entBox.id;var t=this.getCookie(name);t=(t||"||||").split("|");t[pos]=value;var str = "gridSettings"+name + "=" + t.join("|") + (cookie_param?(";"+cookie_param):"");document.cookie = str};dhtmlXGridObject.prototype.getCookie=function(name,surname) {if (!name)name=this.entBox.id;name=(surname||"gridSettings")+name;var search = name + "=";if (document.cookie.length > 0){var offset = document.cookie.indexOf(search);if (offset != -1){offset += search.length;var end = document.cookie.indexOf(";", offset);if (end == -1)end = document.cookie.length;return document.cookie.substring(offset, end)}}};dhtmlXGridObject.prototype._getCookie=function(name,pos) {return ((this.getCookie(name)||"||||").split("|"))[pos]};function dhtmlXGridFromTable(obj,init){if(typeof(obj)!='object')
 obj = document.getElementById(obj);obj.className="";var w=document.createElement("DIV");w.setAttribute("width",obj.getAttribute("gridWidth")||(obj.offsetWidth?(obj.offsetWidth+"px"):0)||(window.getComputedStyle?window.getComputedStyle(obj,null)["width"]:(obj.currentStyle?obj.currentStyle["width"]:0)));w.setAttribute("height",obj.getAttribute("gridHeight")||(obj.offsetHeight?(obj.offsetHeight+"px"):0)||(window.getComputedStyle?window.getComputedStyle(obj,null)["height"]:(obj.currentStyle?obj.currentStyle["height"]:0)));var mr=obj;var drag=obj.getAttribute("dragAndDrop");mr.parentNode.insertBefore(w,mr);var f=mr.getAttribute("name")||("name_"+(new Date()).valueOf());var windowf=new dhtmlXGridObject(w);window[f]=windowf;var acs=mr.getAttribute("onbeforeinit");var acs2=mr.getAttribute("oninit");if (acs)eval(acs);windowf.setImagePath(mr.getAttribute("imgpath")||"");if (init)init(windowf);var hrow=mr.rows[0];var za="";var zb="";var zc="";var zd="";var ze="";for (var i=0;i<hrow.cells.length;i++){za+=(za?",":"")+hrow.cells[i].innerHTML;var width=hrow.cells[i].getAttribute("width")||hrow.cells[i].offsetWidth||(window.getComputedStyle?window.getComputedStyle(hrow.cells[i],null)["width"]:(hrow.cells[i].currentStyle?hrow.cells[i].currentStyle["width"]:0));zb+=(zb?",":"")+(width=="*"?width:parseInt(width));zc+=(zc?",":"")+(hrow.cells[i].getAttribute("align")||"left");zd+=(zd?",":"")+(hrow.cells[i].getAttribute("type")||"ed");ze+=(ze?",":"")+(hrow.cells[i].getAttribute("sort")||"str");var f_a=hrow.cells[i].getAttribute("format");if (f_a)if(hrow.cells[i].getAttribute("type").toLowerCase().indexOf("calendar")!=-1) 
 windowf._dtmask=f_a;else
 windowf.setNumberFormat(f_a,i)};windowf.setHeader(za);windowf.setInitWidths(zb)
 windowf.setColAlign(zc)
 windowf.setColTypes(zd);windowf.setColSorting(ze);if (obj.getAttribute("gridHeight")=="auto")
 windowf.enableAutoHeigth(true);if (obj.getAttribute("multiline")) windowf.enableMultiline(true);var lmn=mr.getAttribute("lightnavigation");if (lmn)windowf.enableLightMouseNavigation(lmn);var evr=mr.getAttribute("evenrow");var uevr=mr.getAttribute("unevenrow");if (evr||uevr)windowf.enableAlterCss(evr,uevr);if (drag)windowf.enableDragAndDrop(true);windowf.init();if (obj.getAttribute("split")) windowf.splitAt(obj.getAttribute("split"));windowf._process_inner_html(mr,1);if (acs2)eval(acs2);if (obj.parentNode && obj.parentNode.removeChild)obj.parentNode.removeChild(obj);return windowf};dhtmlXGridObject.prototype._process_html=function(xml){if (xml.tagName && xml.tagName == "TABLE")return this._process_inner_html(xml,0);var temp=document.createElement("DIV");temp.innerHTML=xml.xmlDoc.responseText;var mr = temp.getElementsByTagName("TABLE")[0];this._process_inner_html(mr,0)};dhtmlXGridObject.prototype._process_inner_html=function(mr,start){var n_l=mr.rows.length;for (var j=start;j<n_l;j++){var id=mr.rows[j].getAttribute("id")||j;this.rowsBuffer.push({idd:id, data:mr.rows[j], _parser: this._process_html_row, _locator:this._get_html_data })};this.render_dataset();this.setSizes()};dhtmlXGridObject.prototype._process_html_row=function(r,xml){var cellsCol = xml.getElementsByTagName('TD');var strAr = [];r._attrs=this._xml_attrs(xml);for(var j=0;j<cellsCol.length;j++){var cellVal=cellsCol[j];var exc=cellVal.getAttribute("type");if (r.childNodes[j]){if (exc)r.childNodes[j]._cellType=exc;r.childNodes[j]._attrs=this._xml_attrs(cellsCol[j])};if (cellVal.firstChild)strAr.push(cellVal.innerHTML);else strAr.push("");if (cellVal.colSpan>1){r.childNodes[j]._attrs["colspan"]=cellVal.colSpan;for (var k=1;k<cellVal.colSpan;k++){strAr.push("")
 }}};for(j<cellsCol.length;j<r.childNodes.length;j++)r.childNodes[j]._attrs={};this._fillRow(r,(this._c_order?this._swapColumns(strAr):strAr));return r};dhtmlXGridObject.prototype._get_html_data=function(data,ind){data=data.firstChild;while (true){if (!data)return "";if (data.tagName=="TD")ind--;if (ind<0)break;data=data.nextSibling};return (data.firstChild?data.firstChild.data:"")};dhtmlxEvent(window,"load",function(){var z=document.getElementsByTagName("table");for (var a=0;a<z.length;a++)if (z[a].className=="dhtmlxGrid"){dhtmlXGridFromTable(z[a])}});dhtmlXGridObject.prototype.enableUndoRedo = function()
{var self = this;var func = function() {return self._onEditUndoRedo.apply(self,arguments)};this.attachEvent("onEditCell", func);var func2 = function(a,b,c) {return self._onEditUndoRedo.apply(self,[2,a,b,(c?1:0),(c?0:1)])};this.attachEvent("onCheckbox", func2);this._IsUndoRedoEnabled = true;this._UndoRedoData = [];this._UndoRedoPos = -1};dhtmlXGridObject.prototype.disableUndoRedo = function()
{this._IsUndoRedoEnabled = false;this._UndoRedoData = [];this._UndoRedoPos = -1};dhtmlXGridObject.prototype._onEditUndoRedo = function(stage, row_id, cell_index, new_value, old_value)
{if (this._IsUndoRedoEnabled && stage == 2 && old_value != new_value){if (this._UndoRedoPos !== -1 && this._UndoRedoPos != ( this._UndoRedoData.length-1 )) {this._UndoRedoData = this._UndoRedoData.slice(0, this._UndoRedoPos+1)}else if (this._UndoRedoPos === -1 && this._UndoRedoData.length > 0){this._UndoRedoData = []};var obj = {old_value:old_value,
 new_value:new_value,
 row_id:row_id,
 cell_index:cell_index
 };this._UndoRedoData.push(obj);this._UndoRedoPos++};return true};dhtmlXGridObject.prototype.doUndo = function()
{if (this._UndoRedoPos === -1)return false;var obj = this._UndoRedoData[this._UndoRedoPos--];var c=this.cells(obj.row_id, obj.cell_index);if (this.getColType(obj.cell_index)=="tree")
 c.setLabel(obj.old_value);else
 c.setValue(obj.old_value)};dhtmlXGridObject.prototype.doRedo = function()
{if (this._UndoRedoPos == this._UndoRedoData.length-1)return false;var obj = this._UndoRedoData[++this._UndoRedoPos];this.cells(obj.row_id, obj.cell_index).setValue(obj.new_value)};dhtmlXGridObject.prototype.getRedo = function()
{if (this._UndoRedoPos == this._UndoRedoData.length-1)return [];return this._UndoRedoData.slice(this._UndoRedoPos+1)};dhtmlXGridObject.prototype.getUndo = function()
{if (this._UndoRedoPos == -1)return [];return this._UndoRedoData.slice(0, this._UndoRedoPos+1)};function eXcell_sub_row(cell){if (cell){this.cell = cell;this.grid = this.cell.parentNode.grid};this.getValue = function(){return this.grid.getUserData(this.cell.parentNode.idd,"__sub_row")};this._setState = function(m,v){(v||this.cell).innerHTML="<img src='"+this.grid.imgURL+m+"' width='18' height='18' />";(v||this.cell).firstChild.onclick=this.grid._expandMonolite};this.open = function (){this.cell.firstChild.onclick(null,true)
 };this.close = function (){this.cell.firstChild.onclick(null,false,true)
 };this.setValue = function(val){if (val)this.grid.setUserData(this.cell.parentNode.idd,"__sub_row",val);this._setState(val?"plus.gif":"blanc.gif")};this.setContent = function(val){if (this.cell.parentNode._expanded){this.cell.parentNode._expanded.innerHTML=val;this.grid._detectHeight(this.cell.parentNode._expanded,this.cell,this.cell.parentNode._expanded.scrollHeight)
 }else{this.cell._previous_content=null;this.setValue(val);this.cell._sub_row_type=null
 }};this.isDisabled = function(){return true};this.getTitle = function(){return this.grid.getUserData(this.cell.parentNode.idd,"__sub_row")?"click to expand|collapse":""}};eXcell_sub_row.prototype = new eXcell;function eXcell_sub_row_ajax(cell){this.base=eXcell_sub_row;this.base(cell);this.setValue = function(val){if (val)this.grid.setUserData(this.cell.parentNode.idd,"__sub_row",val);this.cell._sub_row_type="ajax";this._setState(val?"plus.gif":"blanc.gif")}};eXcell_sub_row_ajax.prototype = new eXcell_sub_row;function eXcell_sub_row_grid(cell){this.base=eXcell_sub_row;this.base(cell);this.setValue = function(val){if (val)this.grid.setUserData(this.cell.parentNode.idd,"__sub_row",val);this.cell._sub_row_type="grid";this._setState(val?"plus.gif":"blanc.gif")};this.getSubGrid = function(){if (!cell._sub_grid)return null;return cell._sub_grid}};eXcell_sub_row_grid.prototype = new eXcell_sub_row;dhtmlXGridObject.prototype._expandMonolite=function(n,show,hide){var td=this.parentNode;var row=td.parentNode;var that=row.grid;var c=that.getUserData(row.idd,"__sub_row");if (!that._sub_row_editor)that._sub_row_editor=new eXcell_sub_row(td);if (!c)return;if (row._expanded && !show){that._sub_row_editor._setState("plus.gif",td);td._previous_content=row._expanded;that.objBox.removeChild(row._expanded);row._expanded=false;row.style.height=(row.oldHeight||20)+"px";td.style.height=(row.oldHeight||20)+"px";if (that._fake)that._fake.rowsAr[row.idd].style.height=(row.oldHeight||20)+"px";for (var i=0;i<row.cells.length;i++){row.cells[i].style.verticalAlign="middle";row.cells[i].style.paddingTop="0px"};delete that._flow[row.idd];that._correctMonolite();row._expanded.ctrl=null}else if (!row._expanded && !hide){that._sub_row_editor._setState("minus.gif",td);if (td._previous_content){var d=td._previous_content;d.ctrl=td;that.objBox.appendChild(d);that._detectHeight(d,td,parseInt(d.style.height)) 
 }else {var d=document.createElement("DIV");row.oldHeight=td.offsetHeight;d.ctrl=td;if (td._sub_row_type)that._sub_row_render[td._sub_row_type](that,d,td,c);else
 d.innerHTML=c;d.style.cssText="position:absolute;left:0px;top:0px;overflow:auto;font-family:Tahoma;font-size:8pt;margin-top:2px;margin-left:4px;";d.className="dhx_sub_row";that.objBox.appendChild(d);that._detectHeight(d,td) 
 };if (!that._flow){that.attachEvent("onGridReconstructed",function(){if (this.pagingOn || this._srnd)this._collapsMonolite();else this._correctMonolite()});that.attachEvent("onResizeEnd",function(){this._correctMonolite(true)});that.attachEvent("onAfterCMove",function(){this._correctMonolite(true)});that.attachEvent("onDrop",function(){this._correctMonolite(true)});that.attachEvent("onBeforePageChanged",function(){this._collapsMonolite();return true});that.attachEvent("onGroupStateChanged",function(){this._correctMonolite();return true});that.attachEvent("onFilterEnd",function(){this._collapsMonolite()});that.attachEvent("onUnGroup",function(){this._collapsMonolite()});that.attachEvent("onPageChanged",function(){this._collapsMonolite()});that.attachEvent("onXLE",function(){this._collapsMonolite()});that.attachEvent("onClearAll",function(){for (var i in this._flow){if (this._flow[i] && this._flow[i].parentNode)this._flow[i].parentNode.removeChild(this._flow[i])};this._flow=[]});that.attachEvent("onEditCell",function(a,b,c){if ((a!==2)&& this._flow[b] && this.cellType[c]!="ch" && this.cellType[c]!="ra") this._expandMonolite.apply(this._flow[b].ctrl.firstChild,[0,false,true]);return true});that.attachEvent("onCellChanged",function(id,ind){if (!this._flow[id])return;var c=this.cells(id,ind).cell;c.style.verticalAlign="top";c.style.paddingTop="3px"});that._flow=[]};that._flow[row.idd]=d;that._correctMonolite();for (var i=0;i<row.cells.length;i++){row.cells[i].style.verticalAlign="top";row.cells[i].style.paddingTop="3px"};if (that._fake){var frow=that._fake.rowsAr[row.idd];for (var i=0;i<frow.cells.length;i++){frow.cells[i].style.verticalAlign="top";frow.cells[i].style.paddingTop="3px"}};td.style.paddingTop="1px";row._expanded=d};if (that._ahgr)that.setSizes()
 if (that.parentGrid)that.callEvent("onGridReconstructed",[]);that.callEvent("onSubRowOpen",[row.idd,(!!row._expanded)])};dhtmlXGridObject.prototype._sub_row_render={"ajax":function(that,d,td,c){d.innerHTML="Loading...";var xml=new dtmlXMLLoaderObject(function(){d.innerHTML=xml.xmlDoc.responseText;var z=xml.xmlDoc.responseText.match(/<script[^>]*>([^<]+)<\/script>/g);if (z)for (var i=0;i<z.length;i++)eval(z[i].replace(/<([\/]{0,1})s[^>]*>/g,""));that._detectHeight(d,td)
 that._correctMonolite();that.setUserData(td.parentNode.idd,"__sub_row",xml.xmlDoc.responseText);td._sub_row_type=null;if (that._ahgr)that.setSizes()
 that.callEvent("onSubAjaxLoad",[td.parentNode.idd,xml.xmlDoc.responseText])}, this,true,true);xml.loadXML(c)},
 "grid":function(that,d,td,c){td._sub_grid= new dhtmlXGridObject(d);if (that.skin_name)td._sub_grid.setSkin(that.skin_name);td._sub_grid.parentGrid=that;td._sub_grid.setImagePath(that.imgURL);td._sub_grid.enableAutoHeight(true);td._sub_grid.attachEvent("onGridReconstructed",function(){that._detectHeight(d,td,td._sub_grid.objBox.scrollHeight+td._sub_grid.hdr.offsetHeight+(this.ftr?this.ftr.offsetHeight:0));that._correctMonolite();this.setSizes();if (that.parentGrid)that.callEvent("onGridReconstructed",[])})
 if (!that.callEvent("onSubGridCreated",[td._sub_grid,td.parentNode.idd,td._cellIndex,c])) return;td._sub_grid.loadXML(c,function(){that._detectHeight(d,td,td._sub_grid.objBox.scrollHeight+td._sub_grid.hdr.offsetHeight+(td._sub_grid.ftr?td._sub_grid.ftr.offsetHeight:0));td._sub_grid.objBox.style.overflow="hidden";that._correctMonolite();td._sub_row_type=null;if (!that.callEvent("onSubGridLoaded",[td._sub_grid,td.parentNode.idd,td._cellIndex,c])) return;if (that._ahgr)that.setSizes()})}};dhtmlXGridObject.prototype._detectHeight=function(d,td,h){var l=td.offsetLeft+td.offsetWidth;d.style.left=l+"px";d.style.width=Math.max(0,td.parentNode.offsetWidth-l-4)+"px"
 var h=h||d.scrollHeight;d.style.overflow="hidden";d.style.height=h+"px";var row=td.parentNode;td.parentNode.style.height=(row.oldHeight||20)+3+h*1+"px";td.style.height=(row.oldHeight||20)+3+h*1+"px";if (this._fake){var tr=this._fake.rowsAr[td.parentNode.idd];tr.style.height=(row.oldHeight||20)+3+h*1+"px"}};dhtmlXGridObject.prototype._correctMonolite=function(mode){if (this._in_correction)return;this._in_correction=true;for (var a in this._flow)if (this._flow[a] && this._flow[a].tagName=="DIV")if (this.rowsAr[a]){if (this.rowsAr[a].style.display=="none"){this.cells4(this._flow[a].ctrl).close();continue};this._flow[a].style.top=this.rowsAr[a].offsetTop+(this.rowsAr[a].oldHeight||20)+"px";if (mode){var l=this._flow[a].ctrl.offsetLeft+this._flow[a].ctrl.offsetWidth;this._flow[a].style.left=l+"px";this._flow[a].style.width=this.rowsAr[a].offsetWidth-l-4+"px"
 }}else{this._flow[a].ctrl=null;this.objBox.removeChild(this._flow[a]);delete this._flow[a]};this._in_correction=false};dhtmlXGridObject.prototype._collapsMonolite=function(){for (var a in this._flow)if (this._flow[a] && this._flow[a].tagName=="DIV")if (this.rowsAr[a])this.cells4(this._flow[a].ctrl).close()};function eXcell_dhxCalendar(cell){if (cell){this.cell = cell;this.grid = this.cell.parentNode.grid;if (!this.grid._grid_calendarA){var z=document.createElement("div");if (_isIE){z.style.position="absolute"
 z.style.top="0px"
 };document.body.insertBefore(z,document.body.firstChild);var cal=this.grid._grid_calendarA=new dhtmlxCalendarObject(z,false, {isYearEditable :true});cal.loadUserLanguage('en-us');if (cal.setYearsRange)cal.setYearsRange(1900, 2100);cal.draw();cal.hide();cal.setSkin("yahoolike");this.grid.callEvent("onDhxCalendarCreated",[cal]);var sgrid=this.grid;cal.attachEvent("onClick",function(){this._last_operation_calendar=true;window.setTimeout(function(){sgrid.editStop()},1);return true});var zFunc=function(e){(e||event).cancelBubble=true};dhtmlxEvent(cal.entObj,"click",zFunc);cal=null}}};eXcell_dhxCalendar.prototype = new eXcell;eXcell_dhxCalendar.prototype.edit = function(){var arPos = this.grid.getPosition(this.cell);this.grid._grid_calendarA.setPosition(arPos[1],arPos[0]);this.grid._grid_calendarA._last_operation_calendar=false;this.grid._grid_calendarA.show();this.grid.callEvent("onCalendarShow",[this.grid._grid_calendarA,this.cell.parentNode.idd,this.cell._cellIndex]);this.cell._cediton=true;this.val=this.cell.val;this._val=this.cell.innerHTML;var t=this.grid._grid_calendarA.draw;this.grid._grid_calendarA.draw=function(){};this.grid._grid_calendarA.setDateFormat((this.grid._dtmask||"%d/%m/%Y"));this.grid._grid_calendarA.setDate(this.val||(new Date()));this.grid._grid_calendarA.draw=t;this.grid._grid_calendarA.draw()};eXcell_dhxCalendar.prototype.getDate = function(){if (this.cell.val)return this.cell.val;return null};eXcell_dhxCalendar.prototype.getValue = function(){if (this.cell._clearCell)return "";return this.cell.innerHTML.toString()._dhx_trim()
 };eXcell_dhxCalendar.prototype.detach = function(){if (!this.grid._grid_calendarA)return;this.grid._grid_calendarA.hide();if (this.cell._cediton)this.cell._cediton=false;else return;if (this.grid._grid_calendarA._last_operation_calendar){var z1=this.grid._grid_calendarA.getFormatedDate((this.grid._dtmask||"%d/%m/%Y"));var z2=this.grid._grid_calendarA.getDate();this.cell.val=new Date(z2);this.setCValue(z1,z2);this.cell._clearCell=!z1;var t=this.val;this.val=this._val;return (this.cell.val.valueOf()!=t)};return false};eXcell_dhxCalendar.prototype.setValue = function(val){if (typeof val == "object"){this.cell.val=val;this.cell._clearCell=false;this.setCValue(this.grid._grid_calendarA.getFormatedDate((this.grid._dtmask||"%d/%m/%Y"),val).toString(),this.cell.val);return};if(!val || val.toString()._dhx_trim()==""){val="&nbsp";this.cell._clearCell=true;this.cell.val=new Date((new Date()).valueOf()+1)}else{this.cell._clearCell=false;this.cell.val=new Date(this.grid._grid_calendarA.setFormatedDate((this.grid._dtmask_inc||this.grid._dtmask||"%d/%m/%Y"),val.toString(),null,true));if (this.grid._dtmask_inc)val = this.grid._grid_calendarA.getFormatedDate((this.grid._dtmask||"%d/%m/%Y"),this.cell.val)};if ((this.cell.val=="NaN")||(this.cell.val=="Invalid Date")){this.cell._clearCell=true;this.cell.val=new Date();this.setCValue("&nbsp;",0)}else
 this.setCValue((val||"").toString(),this.cell.val)};function eXcell_dhxCalendarA(cell){if (cell){this.cell = cell;this.grid = this.cell.parentNode.grid;if (!this.grid._grid_calendarA){var z=document.createElement("DIV");document.body.insertBefore(z,document.body.firstChild);this.grid._grid_calendarA=new dhtmlxCalendarObject(z,false, {isYearEditable :true});this.grid._grid_calendarA.loadUserLanguage('en-us');this.grid._grid_calendarA.setYearsRange(1900, 2100);this.grid._grid_calendarA.draw();this.grid._grid_calendarA.hide();this.grid._grid_calendarA.setSkin("yahoolike");var sgrid=this.grid;this.grid._grid_calendarA.attachEvent("onClick",function(){this._last_operation_calendar=true;window.setTimeout(function(){sgrid.editStop()},1);return true});var zFunc=function(e){(e||event).cancelBubble=true};dhtmlxEvent(this.grid._grid_calendarA.entObj,"click",zFunc)}}};eXcell_dhxCalendarA.prototype = new eXcell;eXcell_dhxCalendarA.prototype.edit = function(){var arPos = this.grid.getPosition(this.cell);this.grid._grid_calendarA.setPosition(arPos[1],arPos[0]*1+this.cell.offsetWidth);this.grid._grid_calendarA.show();this.grid.callEvent("onCalendarShow",[this.grid._grid_calendarA,this.cell.parentNode.idd,this.cell._cellIndex]);this.grid._grid_calendarA._last_operation_calendar=false;this.cell._cediton=true;this.val=this.cell.val;this._val=this.cell.innerHTML;var t=this.grid._grid_calendarA.draw;this.grid._grid_calendarA.draw=function(){};this.grid._grid_calendarA.setDateFormat((this.grid._dtmask||"%d/%m/%Y"));this.grid._grid_calendarA.setDate(this.val);this.grid._grid_calendarA.draw=t;this.grid._grid_calendarA.draw();this.cell.atag=((!this.grid.multiLine)&&(_isKHTML||_isMacOS||_isFF))?"INPUT":"TEXTAREA";this.obj = document.createElement(this.cell.atag);this.obj.style.height = (this.cell.offsetHeight-(_isIE?4:2))+"px";this.obj.className="dhx_combo_edit";this.obj.wrap = "soft";this.obj.style.textAlign = this.cell.align;this.obj.onclick = function(e){(e||event).cancelBubble = true};this.obj.onmousedown = function(e){(e||event).cancelBubble = true};this.obj.value = this.getValue();this.cell.innerHTML = "";this.cell.appendChild(this.obj);if (_isFF){this.obj.style.overflow="visible";if ((this.grid.multiLine)&&(this.obj.offsetHeight>=18)&&(this.obj.offsetHeight<40)){this.obj.style.height="36px";this.obj.style.overflow="scroll"}};this.obj.onselectstart=function(e){if (!e)e=event;e.cancelBubble=true;return true};this.obj.focus()
 this.obj.focus()
 
 };eXcell_dhxCalendarA.prototype.getDate = function(){if (this.cell.val)return this.cell.val;return null};eXcell_dhxCalendarA.prototype.getValue = function(){if (this.cell._clearCell)return "";return this.cell.innerHTML.toString()._dhx_trim()
 };eXcell_dhxCalendarA.prototype.detach = function(){if (!this.grid._grid_calendarA)return;this.grid._grid_calendarA.hide();if (this.cell._cediton)this.cell._cediton=false;else return;if (this.grid._grid_calendarA._last_operation_calendar){this.grid._grid_calendarA._last_operation_calendar=false;var z1=this.grid._grid_calendarA.getFormatedDate(this.grid._dtmask||"%d/%m/%Y");var z2=this.grid._grid_calendarA.getDate();this.cell.val=new Date(z2);this.setCValue(z1,z2);this.cell._clearCell = !z1;var t=this.val;this.val=this._val;return (this.cell.val.valueOf()!=(t|"").valueOf())};this.setValue(this.obj.value);var t=this.val;this.val=this._val;return (this.cell.val.valueOf()!=(t||"").valueOf())};eXcell_dhxCalendarA.prototype.setValue = function(val){if (typeof val == "object"){this.cell.val=val;this.cell._clearCell=false;this.setCValue(this.grid._grid_calendarA.getFormatedDate((this.grid._dtmask||"%d/%m/%Y"),val).toString(),this.cell.val);return};if(!val || val.toString()._dhx_trim()==""){val="&nbsp";this.cell._clearCell=true;this.cell.val=new Date((new Date()).valueOf()+1)}else{this.cell._clearCell=false;this.cell.val=new Date(this.grid._grid_calendarA.setFormatedDate((this.grid._dtmask_inc||this.grid._dtmask||"%d/%m/%Y"),val.toString(),null,true));if (this.grid._dtmask_inc)val = this.grid._grid_calendarA.getFormatedDate((this.grid._dtmask||"%d/%m/%Y"),this.cell.val)};if ((this.cell.val=="NaN")||(this.cell.val=="Invalid Date")){this.cell.val=new Date();this.cell._clearCell=true;this.setCValue("&nbsp;",0)}else
 this.setCValue((val||"").toString(),this.cell.val)};function eXcell_cntr(cell){this.cell = cell;this.grid = this.cell.parentNode.grid;if (!this.grid._ex_cntr_ready && !this._realfake){this.grid._ex_cntr_ready=true;if (this.grid._h2)this.grid.attachEvent("onOpenEn",function(id){this.resetCounter(cell._cellIndex)});this.grid.attachEvent("onBeforeSorting",function(){var that=this;window.setTimeout(function(){if (that._fake && !that._realfake && cell._cellIndex<that._fake._cCount)that._fake.resetCounter(cell._cellIndex);else
 that.resetCounter(cell._cellIndex)},1)
 return true})};this.edit = function(){};this.getValue = function(){return this.cell.innerHTML};this.setValue = function(val){this.cell.style.paddingRight = "2px";var cell=this.cell;window.setTimeout(function(){if (!cell.parentNode)return;var val=cell.parentNode.rowIndex;if (cell.parentNode.grid.currentPage || val<0 || cell.parentNode.grid._srnd)val=cell.parentNode.grid.rowsBuffer._dhx_find(cell.parentNode)+1;cell.innerHTML = val;if (cell.parentNode.grid._fake && cell._cellIndex<cell.parentNode.grid._fake._cCount && cell.parentNode.grid._fake.rowsAr[cell.parentNode.idd])cell.parentNode.grid._fake.cells(cell.parentNode.idd,cell._cellIndex).setCValue(val);cell=null},100)}};dhtmlXGridObject.prototype.resetCounter=function(ind){if (this._fake && !this._realfake && ind < this._fake._cCount)this._fake.resetCounter(ind,this.currentPage);var i=arguments[0]||0;if (this.currentPage)i=(this.currentPage-1)*this.rowsBufferOutSize;for (i=0;i<this.rowsBuffer.length;i++)if (this.rowsBuffer[i].tagName == "TR")this.rowsAr[this.rowsBuffer[i].idd].childNodes[ind].innerHTML=i+1};eXcell_cntr.prototype = new eXcell;function eXcell_link(cell){this.cell = cell;this.grid = this.cell.parentNode.grid;this.isDisabled=function(){return true};this.edit = function(){};this.getValue = function(){if(this.cell.firstChild.getAttribute)return this.cell.firstChild.innerHTML+"^"+this.cell.firstChild.getAttribute("href")
 else
 return ""};this.setValue = function(val){if((typeof(val)!="number") && (!val || val.toString()._dhx_trim()=="")){this.setCValue("&nbsp;",valsAr);return (this.cell._clearCell=true)};var valsAr = val.split("^");if(valsAr.length==1)valsAr[1] = "";else{if(valsAr.length>1){valsAr[1] = "href='"+valsAr[1]+"'";if(valsAr.length==3)valsAr[1]+= " target='"+valsAr[2]+"'";else
 valsAr[1]+= " target='_blank'"}};this.setCValue("<a "+valsAr[1]+" onclick='(_isIE?event:arguments[0]).cancelBubble = true;'>"+valsAr[0]+"</a>",valsAr)}};eXcell_link.prototype = new eXcell;eXcell_link.prototype.getTitle=function(){var z=this.cell.firstChild;return ((z&&z.tagName)?z.getAttribute("href"):"")};eXcell_link.prototype.getContent=function(){var z=this.cell.firstChild;return ((z&&z.tagName)?z.innerHTML:"")};function eXcell_clist(cell){try{this.cell = cell;this.grid = this.cell.parentNode.grid}catch(er){};this.edit = function(){this.val = this.getValue();var a=(this.cell._combo||this.grid.clists[this.cell._cellIndex]);if (!a)return;this.obj = document.createElement("DIV");var b=this.val.split(",");var text="";for (var i=0;i<a.length;i++){var fl=false;for (var j=0;j<b.length;j++)if (a[i]==b[j])fl=true;if (fl)text+="<div><input type='checkbox' checked='true' /><label>"+a[i]+"</label></div>";else
 text+="<div><input type='checkbox' id='ch_lst_"+i+"'/><label>"+a[i]+"</label></div>"};text+="<div><input type='button' value='Apply' style='width:100px;font-size:8pt;' onclick='this.parentNode.parentNode.editor.grid.editStop();'/></div>"

 this.obj.editor=this;this.obj.innerHTML=text;document.body.appendChild(this.obj);this.obj.style.position="absolute";this.obj.className="dhx_clist";this.obj.onclick=function(e){(e||event).cancelBubble=true;return true};var arPos = this.grid.getPosition(this.cell);this.obj.style.left=arPos[0]+"px";this.obj.style.top=arPos[1]+this.cell.offsetHeight+"px";this.obj.getValue=function(){var text="";for (var i=0;i<this.childNodes.length-1;i++)if (this.childNodes[i].childNodes[0].checked){if (text)text+=",";text+=this.childNodes[i].childNodes[1].innerHTML};return text}};this.getValue = function(){if (this.cell._clearCell)return "";return this.cell.innerHTML.toString()._dhx_trim()
 };this.detach = function(val){if (this.obj){this.setValue(this.obj.getValue());this.obj.editor=null;this.obj.parentNode.removeChild(this.obj);this.obj=null};return this.val!=this.getValue()}};eXcell_clist.prototype = new eXcell;eXcell_clist.prototype.setValue = function(val){if (typeof(val)=="object"){var optCol=this.grid.xmlLoader.doXPath("./option",val);if (optCol.length)this.cell._combo=[];for (var j=0;j<optCol.length;j++)this.cell._combo.push(optCol[j].firstChild?optCol[j].firstChild.data:"");val=val.firstChild.data};if (val==="" || val === this.undefined){this.setCTxtValue(" ",val);this.cell._clearCell=true}else{this.setCValue(val);this.cell._clearCell=false}};dhtmlXGridObject.prototype.registerCList=function(col,list){if (!this.clists)this.clists=new Array();if (typeof(list)!="object") list=list.split(",");this.clists[col]=list};function dhtmlxDblCalendarObject(contId, isAutoDraw, options){this.scriptName = 'dhtmlxcalendar.js';this.entObj = document.createElement("DIV");this.winHeader = null
 this.style = "dhtmlxdblcalendar";this.uid = 'sc&dblCal'+Math.round(1000000*Math.random());this.numLoaded = 2;this.options = {isWinHeader: false,
 headerText: 'dhtmlxDblCalendarObject',
 headerButtons: '', 
 
 
 
 isWinDrag: false,
 msgClose: "Close",
 msgMinimize: "Minimize",
 msgToday: "Today",
 msgClear: "Clear"
 };if (options)for (x in options)this.options[x] = options[x];this.entBox = document.createElement("TABLE");this.entBox.cellPadding = "0px";this.entBox.cellSpacing = "0px";this.entBox.className = this.style;this.entObj.appendChild(this.entBox);var entRow = this.entBox.insertRow(0);var calLeft = entRow.insertCell(0);calLeft.style.paddingRight = '2px';var calRight = entRow.insertCell(1);this.leftCalendar = new dhtmlxCalendarObject(calLeft, false, this.options);this.leftCalendar._dblC = this;this.leftCalendar.setOnClickHandler(this.doOnCLeftClick);this.rightCalendar = new dhtmlxCalendarObject(calRight, false, this.options);this.rightCalendar._dblC = this;this.rightCalendar.setOnClickHandler(this.doOnCRightClick);this.doOnClick = null;this.onLanguageLoaded = null;this.getPosition = this.leftCalendar.getPosition;this.startDrag = this.leftCalendar.startDrag;this.stopDrag = this.leftCalendar.stopDrag;this.onDrag = this.leftCalendar.onDrag;this.drawHeader = this.leftCalendar.drawHeader;dhtmlxEventable(this);var self = this;if (typeof(contId)!= 'string') this.con = contId;else this.con = document.getElementById(contId);if (isAutoDraw)this.draw ()};dhtmlXDblCalendarObject = dhtmlxDblCalendarObject;dhtmlxDblCalendarObject.prototype.setHeader = function(isVisible, isDrag, btnsOpt){this.leftCalendar.options.isWinHeader = this.options.isWinHeader = isVisible;this.leftCalendar.options.isWinDrag = this.options.isWinDrag = isDrag;if (btnsOpt)this.options.headerButtons = this.leftCalendar.options.headerButtons = btnsOpt;if (this.isAutoDraw)this.drawHeader()};dhtmlxDblCalendarObject.prototype.setYearsRange = function(minYear, maxYear){var cs = [this.leftCalendar, this.rightCalendar];for (var ind=0;ind < cs.length;ind++){cs[ind].options.yearsRange = [parseInt(minYear), parseInt(maxYear)];cs[ind].allYears = [];for (var i=minYear;i <= maxYear;i++)cs[ind].allYears.push(i)}};dhtmlxDblCalendarObject.prototype.show = function(){this.parent.style.display = 'block'};dhtmlxDblCalendarObject.prototype.hide = function(){this.parent.style.display = 'none'};dhtmlxDblCalendarObject.prototype.createStructure = function(){if (this.options.isWinHeader){var headerRow = this.entBox.insertRow(0).insertCell(0);headerRow.colSpan = 2;headerRow.align = 'right';this.winHeader = document.createElement('DIV');headerRow.appendChild(this.winHeader)};this.setParent(this.con)};dhtmlxDblCalendarObject.prototype.draw = function(){if (!this.parent)this.createStructure();this.drawHeader();this.leftCalendar.draw();this.rightCalendar.draw();this.isAutoDraw = true};dhtmlxDblCalendarObject.prototype.loadUserLanguage = function(lang, userCBfunction){this.numLoaded = 0;if (userCBfunction)this.onLanguageLoaded = userCBfunction;this.leftCalendar.loadUserLanguage(lang, this.languageLoaded);this.rightCalendar.loadUserLanguage(lang, this.languageLoaded)};dhtmlxDblCalendarObject.prototype.languageLoaded = function(status){var self = this._dblC;self.numLoaded ++;if (self.numLoaded == 2){for (param in this.options)self.options[param] = this.options[param];if (this.isAutoDraw)self.drawHeader();if (self.onLanguageLoaded)self.onLanguageLoaded(status)}};dhtmlxDblCalendarObject.prototype.setParent = function(newParent){if (newParent){this.parent = newParent;this.parent.style.display = 'block';this.parent.appendChild(this.entObj)}};dhtmlxDblCalendarObject.prototype.setOnClickHandler = function(func){this.doOnClick = func};dhtmlxDblCalendarObject.prototype.doOnCLeftClick = function(date){date = new Date (date)
 this._dblC.rightCalendar.setSensitive(date, null);if (this._dblC.doOnClick)this._dblC.doOnClick(date, this, "left");return true};dhtmlxDblCalendarObject.prototype.doOnCRightClick = function(date){this._dblC.leftCalendar.setSensitive(null, date);if (this._dblC.doOnClick)this._dblC.doOnClick(date, this, "right");return true};dhtmlxDblCalendarObject.prototype.setSensitive = function(){this.rightCalendar.setSensitive(null, this.leftCalendar.date[0]);this.leftCalendar.setSensitive(this.rightCalendar.date[0], null)};dhtmlxDblCalendarObject.prototype.minimize = function(){if (!this.winHeader)return;var tr = this.winHeader.parentNode.parentNode.nextSibling;tr.parentNode.parentNode.style.width = parseInt(tr.parentNode.parentNode.offsetWidth) + 'px';if (tr)tr.style.display = (tr.style.display == 'none')? 'block': 'none'};dhtmlxDblCalendarObject.prototype.setDate = function(dateFrom,dateTo){this.leftCalendar.setDate(dateFrom);this.rightCalendar.setDate(dateTo);this.leftCalendar.setSensitive(null, this.rightCalendar.date[0]);this.rightCalendar.setSensitive(this.leftCalendar.date[0], null)};dhtmlxDblCalendarObject.prototype.setDateFormat = function(format){this.leftCalendar.setDateFormat(format);this.rightCalendar.setDateFormat(format)};dhtmlxDblCalendarObject.prototype.isVisible = function(){return (this.parent.style.display == 'block'?true:false)};dhtmlxDblCalendarObject.prototype.setHolidays = function(dates){this.leftCalendar.setHolidays(dates);this.rightCalendar.setHolidays(dates)};function dhtmlxCalendarObject (base, isAutoDraw, options){if (typeof(base)== "object" && base.parent)
 {options = {};for (i in base)options [i] = base [i]};this.isAutoDraw = base.autoDraw || isAutoDraw || false;this.contId = base.parent || base;this.scriptName = 'dhtmlxcalendar.js';this.date = [this.cutTime(new Date())];this.selDate = [this.cutTime(new Date())];this.curDate = this.cutTime(new Date());this.entObj = document.createElement("DIV");this.monthPan = document.createElement("TABLE");this.dlabelPan = document.createElement("TABLE");this.daysPan = document.createElement("TABLE");this.parent = null;this.style = "dhtmlxcalendar";this.skinName = dhtmlx.skin || "";this.doOnClick = null;this.sensitiveFrom = null;this.sensitiveTo = null;this.insensitiveDates = null;this.activeCell = null;this.hotCell = null;this.winHeader = null
 this.onLanguageLoaded = null;this.dragging = false;this.minimized = false;this.uid = 'sc&Cal'+Math.round(1000000*Math.random());this.holidays = null;this.time = false;this.daysCells = {};this.weekCells = {};this.con = [];this.conInd = [];this.activeCon = null;this.activeConInd = 0;this.userPosition = false;this.useIframe = true;this._c = this;dhtmlxEventable(this);this.options = {btnPrev: "&laquo;",
 btnBgPrev: null,
 btnNext: "&raquo;",
 btnBgNext: null,
 yearsRange: [1900, 2100],
 
 isMonthEditable: false,
 isYearEditable: false,
 
 isWinHeader: false,
 headerText : 'Calendar header',
 headerButtons: 'TMX', 
 
 
 isWinDrag: true
 };defLeng = {langname: 'en-us',
 dateformat: '%Y-%m-%d',
 monthesFNames: ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"],
 monthesSNames: ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"],
 daysFNames: ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"],
 daysSNames: ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"],
 weekend: [0, 6],
 weekstart: 0,
 msgClose: "Close",
 msgMinimize: "Minimize",
 msgToday: "Today",
 msgClear: "Clear"
 };if (!window.dhtmlxCalendarLangModules)window.dhtmlxCalendarLangModules = {};window.dhtmlxCalendarLangModules['en-us'] = defLeng;if (window.dhtmlxCalendarObjects)window.dhtmlxCalendarObjects.push(this);else window.dhtmlxCalendarObjects = [this];dhtmlxEvent(document.body,"click",function(ev){for (cal in window.dhtmlxCalendarObjects){if (!isNaN(cal))
 {var wCal = window.dhtmlxCalendarObjects[cal];if (wCal.con[0].nodeName == 'INPUT')wCal.hide ()
 }}});for (lg in defLeng)this.options[lg] = defLeng[lg];if (options)for (param in options)this.options[param] = options[param];this.loadUserLanguage();if (options)for (param in options)this.options[param] = options[param];this.allYears = Array();with (this.options)
 for (var i=yearsRange[0];i <= yearsRange[1];i++)this.allYears.push(i);if(isAutoDraw !== false)this.draw(options);return this};dhtmlXCalendarObject = dhtmlxCalendarObject;dhtmlxCalendarObject.prototype={createStructure:function(){var self = this;if (!this.entObj.className)this.setSkin (this.skinName);this.entObj.style.position = "relative";if (this.options.isWinHeader){this.winHeader = document.createElement('DIV');this.entObj.appendChild(this.winHeader)};this.entBox = document.createElement("TABLE");this.entBox.className = "entbox";with (this.entBox) {cellPadding = "0px";cellSpacing = "0px";width = '100%'};this.entObj.appendChild(this.entBox);var monthBox = this.entBox.insertRow(0).insertCell(0);with (this.monthPan) {cellPadding = "0px";cellSpacing = "0px";width = '100%';align = 'center'};this.monthPan.className = "dxcalmonth";monthBox.appendChild(this.monthPan);var dlabelBox = this.entBox.insertRow(1).insertCell(0);dlabelBox.appendChild(this.dlabelPan);with (this.dlabelPan) {cellPadding = "0px";cellSpacing = "0px";width = '100%';align = 'center'};this.dlabelPan.className = "dxcaldlabel";var daysBox = this.entBox.insertRow(2).insertCell(0);daysBox.appendChild(this.daysPan);with (this.daysPan) {cellPadding = "1px";cellSpacing = "0px";width = '100%';align = 'center'};if(_isIE || _isKHTML)this.daysPan.className = "dxcaldays_ie";else
 this.daysPan.className = "dxcaldays";this.daysPan.onmousemove = function (e) {self.doHotKeys(e)};this.daysPan.onmouseout = function () {self.endHotKeys()};if (typeof(this.contId)!= 'string') {if (!this.contId.nodeName){for (var i=0;i < this.contId.length;i++){this.con[i] = document.getElementById(this.contId[i]);this.selDate[i] = this.cutTime(new Date());this.conInd[this.contId[i]] = i}}else {this.con [0] = this.contId;this.conInd [this.contId.id] = 0}}else 
 {this.con [0] = document.getElementById(this.contId);this.conInd [this.contId] = 0};this.activeCon = this.con[0];if (this.con[0].nodeName == 'INPUT'){var div = document.createElement('DIV');with (div.style) {position = 'absolute';display = 'none';zIndex = 101};this.setParent(div);document.body.appendChild(div);conOnclick = function (e) {if (self.isVisible())
 self.hide()
 else {self.activeCon = this;if (this.value){if (self.time){var val = this.value.split (" ");self.setFormatedTime(null, val [1]);self.setDate(self.getFormatedDate(val [0]))}else
 self.setDate(self.getFormatedDate(this.value))};self.show(this.id);self.draw()};if (this.id != self.activeCon.id){self.show(this.id);self.draw()};(e||event).cancelBubble=true};this.doOnClick = function (date) {self.hide();self.activeCon.focus();return true};conOnkeydown = function(e){if((e||window.event).keyCode==27)
 self.hide();else if((e||window.event).keyCode==13)
 self.show()};for (i in this.con){this.con[i].onclick = conOnclick;this.con[i].onkeydown = conOnkeydown}}else this.setParent(this.con [0]);if(_isIE && this.useIframe){if(this.parent.style.zIndex==0){this.parent.style.zIndex = 100};if(this.ifr == undefined && this._dblC == undefined){this.ifr = document.createElement("IFRAME");this.ifr.src="javascript:false;"
 this.ifr.style.position = "absolute";this.ifr.style.zIndex = 1;this.ifr.frameBorder = "no";this.ifr.style.top = getAbsoluteTop(this.entObj) + 'px';this.ifr.scrolling = 'no';this.ifr.style.display = this.parent.style.display;this.ifr.className = this.style + (this.skinName?'_':"") + this.skinName + "_ifr";this.parent.appendChild(this.ifr)}};this.entObj.onclick = function (e) {e = e||event;if (e.stopPropagation)e.stopPropagation();else e.cancelBubble = true};if (!this.entObj.className)this.setSkin (this.skinName)},

 
 drawHeader:function(){if (this._dblC 
 || !this.options.isWinHeader 
 || !this.winHeader)return
 var self = this;while (this.winHeader.hasChildNodes())
 this.winHeader.removeChild(this.winHeader.firstChild);this.winHeader.className = 'winHeader';this.winHeader.onselectstart=function(){return false};this.headerLabel = document.createElement('div');this.headerLabel.className = 'winTitle';this.headerLabel.appendChild(document.createTextNode(this.options.headerText));this.headerLabel.setAttribute('title', this.options.headerText);this.winHeader.appendChild(this.headerLabel);if (this.options.isWinDrag){this.winHeader.onmousedown = function(e) {self.startDrag(e)}};if (this.options.headerButtons.indexOf('X')>=0) {var btnClose = document.createElement('DIV');btnClose.className = 'btn_close';btnClose.setAttribute('title', this.options.msgClose);btnClose.onmousedown =function (e) {(e||event).cancelBubble=true};btnClose.onclick = function (e) {(e||event).cancelBubble=true;self.hide()};this.winHeader.appendChild(btnClose)};if (this.options.headerButtons.indexOf('M')>=0) {var btnMin = document.createElement('DIV');btnMin.className = 'btn_mini';btnMin.setAttribute('title', this.options.msgMinimize);btnMin.onmousedown =function (e) {(e||event).cancelBubble=true};btnMin.onclick = function(e) {this.className = this.className == 'btn_mini' ? 'btn_maxi' : 'btn_mini';(e||event).cancelBubble=true;self.minimize()};this.winHeader.appendChild(btnMin)};if (this.options.headerButtons.indexOf('C')>=0) {var btnClear = document.createElement('DIV');btnClear.className = 'btn_clear';btnClear.setAttribute('title', this.options.msgClear);btnClear.onmousedown =function (e) {(e||event).cancelBubble=true};btnClear.onclick = function(e) {(e||event).cancelBubble=true;self.activeCon.value = "";self.hide()};this.winHeader.appendChild(btnClear)};if (this.options.headerButtons.indexOf('T')>=0) {var btnToday = document.createElement('DIV');btnToday.className = 'btn_today';btnToday.setAttribute('title', this.options.msgToday);btnToday.onmousedown =function (e) {(e||event).cancelBubble=true};btnToday.onclick = function(e) {(e||event).cancelBubble=true;self.setDate(new Date())};this.winHeader.appendChild(btnToday)}},
 
 
 drawMonth:function(){var self = this;if (this.monthPan.hasChildNodes()) 
 this.monthPan.removeChild(this.monthPan.firstChild);var row = this.monthPan.insertRow(0);var cArLeft = row.insertCell(0);var cContent = row.insertCell(1);var cArRight = row.insertCell(2);cArLeft.align = "left";cArLeft.className = 'month_btn_left';var btnLabel = document.createElement("div");btnLabel.innerHTML = " ";cArLeft.appendChild(btnLabel);cArLeft.onclick = function(){self.prevMonth() };cArLeft.onselectstart = function () {return false};cArRight.align = "right";cArRight.className = 'month_btn_right';var btnLabel = document.createElement("div");btnLabel.innerHTML = " ";cArRight.appendChild(btnLabel);cArRight.onclick = function(){self.nextMonth() };cArRight.onselectstart = function () {return false};cContent.align = 'center';var mHeader = document.createElement("TABLE");with (mHeader) {cellPadding = "0px";cellSpacing = "0px";align = "center"};var mRow = mHeader.insertRow(0);var cMonth = mRow.insertCell(0);var cComma = mRow.insertCell(1);var cYear = mRow.insertCell(2);cContent.appendChild(mHeader);var date = this.date[0];this.planeMonth = document.createElement('DIV');this.planeMonth._c = this;this.planeMonth.appendChild(document.createTextNode(this.options.monthesFNames[date.getMonth()]));this.planeMonth.className = 'planeMonth';cMonth.appendChild(this.planeMonth);if (this.options.isMonthEditable){this.planeMonth.style.cursor = 'pointer';this.editorMonth = new dhtmlxRichSelector({nodeBefore: this.planeMonth,
 valueList: [0,1,2,3,4,5,6,7,8,9,10,11],
 titleList: this.options.monthesFNames,
 activeValue: this.options.monthesFNames[date.getMonth()],
 onSelect: this.onMonthSelect,
 isAllowUserValue: false
 });this.editorMonth._c = this};cComma.appendChild(document.createTextNode(","));cComma.className = 'comma';this.planeYear = document.createElement('DIV');this.planeYear._c = this;this.planeYear.appendChild(document.createTextNode(date.getFullYear()));this.planeYear.className = 'planeYear';cYear.appendChild(this.planeYear);if (this.options.isYearEditable){this.planeYear.style.cursor = 'pointer';this.editorYear = new dhtmlxRichSelector({nodeBefore: this.planeYear,
 valueList: this.allYears,
 titleList: this.allYears,
 activeValue: date.getFullYear(),
 onSelect: this.onYearSelect,
 isOrderedList: true,
 isNumbersList: true,
 isAllowUserValue: true
 });this.editorYear._c = this}},

 
 drawDayLabels:function() {var self = this;if(!this.dlabelPan.hasChildNodes()) 
 {var row = this.dlabelPan.insertRow(-1);row.className = "daynames";for(var i=0;i<7;i++){(this.weekCells [i] = row.insertCell(i)).appendChild(document.createTextNode(this.getDayName(i)))
 }}else 
 {for(var i=0;i<7;i++)this.weekCells[i].childNodes [0].nodeValue = this.getDayName(i)}},

 
 drawDays:function() {var self = this;var row = {}, cell;if(!this.daysPan.hasChildNodes()) 
 {for (var weekNumber=0;weekNumber<6;weekNumber++){row = this.daysPan.insertRow(-1);this.daysCells [weekNumber] = {};for (var i=0;i<7;i++){(this.daysCells [weekNumber] [i] = row.insertCell(-1)).appendChild(document.createTextNode(""))}}};var date = this.date[0], tempDate = new Date(date);var selectedDate = this.selDate[this.activeConInd].toDateString();tempDate.setDate(1);var day1 = (tempDate.getDay() - this.options.weekstart) % 7;if (day1 <= 0)day1 += 7;tempDate.setDate(- day1);tempDate.setDate(tempDate.getDate() + 1);if (tempDate.getDate()< tempDate.getDay()) 
 tempDate.setMonth(tempDate.getMonth() - 1);var curDay = null;for (var weekNumber=0;weekNumber<6;weekNumber++){for (var i=0;i<7;i++){if (curDay == tempDate.getDate())
 tempDate.setDate(tempDate.getDate() + 1);curDay = tempDate.getDate();cell = this.daysCells [weekNumber] [i];cell.setAttribute('id', this.uid+tempDate.getFullYear()+tempDate.getMonth()+tempDate.getDate());cell.childNodes [0].nodeValue = tempDate.getDate();cell.thisdate = tempDate.toString();cell.className = "thismonth";cell.onclick = null;if(tempDate.getMonth()!=date.getMonth())
 cell.className = "othermonth";if (this.insensitiveDates){var c = false;for (var j=0;j<this.insensitiveDates.length;j++){var s = /\.|\-/.exec(this.insensitiveDates[j])
 if (s)var f = (this.insensitiveDates[j].split (s).length == 2 ? '%m'+s+'%d' : '%Y'+s+'%m'+s+'%d');if (s && this.getFormatedDate(f, tempDate)== this.insensitiveDates[j] || tempDate.getDay () == this.insensitiveDates[j]) {this.addClass(cell, "insensitive");tempDate.setDate(tempDate.getDate() + 1);c = true;break}};if (c)continue};if (this.sensitiveFrom && this.sensitiveFrom instanceof Array){var c = true;for (var j=0;j<this.sensitiveFrom.length;j++){var s = /\.|\-/.exec(this.sensitiveFrom[j]);var f = (this.sensitiveFrom[j].split (s).length == 2 ? '%m'+s+'%d' : '%Y'+s+'%m'+s+'%d');if (this.getFormatedDate(f, tempDate)== this.sensitiveFrom[j])
 c = false};if (c){this.addClass(cell, "insensitive");tempDate.setDate(tempDate.getDate() + 1);continue}};if ((this.sensitiveFrom && (tempDate.valueOf()< this.sensitiveFrom.valueOf()))
 || (this.sensitiveTo && (tempDate.valueOf() > this.sensitiveTo.valueOf()))) {this.addClass(cell, "insensitive");tempDate.setDate(tempDate.getDate() + 1);continue};if (this.isWeekend(i)&& tempDate.getMonth()==date.getMonth()) 
 cell.className = "weekend";if (tempDate.toDateString()== this.curDate.toDateString())
 this.addClass(cell, "current");if (tempDate.toDateString()== selectedDate) {this.activeCell = cell;this.addClass(cell, "selected")};if (this.holidays)for (var j=0;j<this.holidays.length;j++){var s = /\.|\-/.exec(this.holidays[j]);var f = (this.holidays[j].split (s).length == 2 ? '%m'+s+'%d' : '%Y'+s+'%m'+s+'%d');if (this.getFormatedDate(f, tempDate)== this.holidays[j])
 this.addClass(cell, "holiday")};cell.onclick = function(){var date = this.thisdate;self.setDate (date);if(!self.doOnClick || self.doOnClick(date)){self.callEvent("onClick", [date])}};tempDate.setDate(tempDate.getDate() + 1)}}},

 
 draw:function(){if (!this.parent)this.createStructure();var self = this;if (this.loadingLanguage){setTimeout(function() {self.draw();return}, 20);return};if (this.winHeader && !this.winHeader.hasChildNodes())
 this.drawHeader();this.drawMonth();this.drawDayLabels();this.drawDays();this.isAutoDraw = true},

 
 loadUserLanguage:function(language, userCBfunction){if (userCBfunction)this.onLanguageLoaded = userCBfunction;if (!language){language="en-us"};this.loadingLanguage = language;if (!language){this.loadUserLanguageCallback(false);return};if (language == this.options.langname){this.loadUserLanguageCallback(true);return};var __lm = window.dhtmlxCalendarLangModules;if (__lm[language]){for (lg in __lm[language])this.options[lg] = __lm[language][lg];this.loadUserLanguageCallback(true);return};var src, path = null;var scripts = document.getElementsByTagName('SCRIPT');for (var i=0;i<scripts.length;i++)if(src = scripts[i].getAttribute('src'))
 if (src.indexOf(this.scriptName)>= 0) {path = src.substr(0, src.indexOf(this.scriptName));break};if (path === null){this.loadUserLanguageCallback(false);return};this.options.langname = language;var langPath = path + 'lang/' + language + '.js';for (var i=0;i<scripts.length;i++)if(src = scripts[i].getAttribute('src'))
 if (src == langPath)return;var script = document.createElement('SCRIPT');script.setAttribute('language', "Java-Script");script.setAttribute('type', "text/javascript");script.setAttribute('src', langPath);document.body.appendChild(script)},

 loadUserLanguageCallback:function(status) {this.loadingLanguage = null;if (this.isAutoDraw)this.draw();if (this.onLanguageLoaded && (typeof(this.onLanguageLoaded)== 'function'))
 this.onLanguageLoaded(status)},

 loadLanguageModule:function(langModule) {var __c = window.dhtmlxCalendarObjects;for (var i=0;i<__c.length;i++){if (__c[i].loadingLanguage == langModule.langname){for (lg in langModule)__c[i].options[lg] = langModule[lg];__c[i].loadUserLanguageCallback(true)}};window.dhtmlxCalendarLangModules[langModule.langname] = langModule},

 

 show:function(conId){this.activeCon = this.con[this._activeConInd(conId)];this.parent.style.display = '';this.parent.style.visibility = 'hidden';if (this.activeCon.nodeName == 'INPUT' && !this.userPosition){if( typeof window.innerWidth == 'number' ){docWidth = window.innerWidth;docHeight = window.innerHeight}else {docWidth = document.body.offsetWidth;docHeight = document.body.offsetHeight};var aLeft = getAbsoluteLeft( this.activeCon);var aTop = getAbsoluteTop( this.activeCon);if (aTop + this.parent.offsetHeight > docHeight && this.parent.offsetHeight < aTop)this.parent.style.top = aTop - this.parent.offsetHeight + this.activeCon.offsetHeight + 'px';else
 this.parent.style.top = aTop + 'px';if (aLeft + this.parent.offsetWidth + this.activeCon.offsetWidth > docWidth)this.parent.style.left = aLeft + 'px';else
 this.parent.style.left = aLeft + this.activeCon.offsetWidth + 'px'};if (this.ifr != undefined){this.ifr.style.top = this.entObj.offsetTop + 'px';this.ifr.style.left = this.entObj.offsetLeft + 'px';this.ifr.style.display = 'block'};if (this.time && !this.minimized){this.tp.setPosition (getAbsoluteLeft (this.parent) + 30, getAbsoluteTop (this.parent) + 147);this.tp.show ()};this.parent.style.visibility = 'visible';return this},

 
 hide:function(){this.parent.style.display = 'none';if(this.ifr!=undefined)this.ifr.style.display = 'none';if (this.time)this.tp.hide();return this},

 
 setDateFormat:function(format){this.options.dateformat = format},



 
 cutTime:function(date) {date = new Date(date);var ndate = new Date(date.getFullYear(), date.getMonth(), date.getDate(), 1, 1);return ndate},


 
 setParent:function(newParent){if (newParent){this.parent = newParent;this.parent.appendChild(this.entObj)}},
 
 setDate:function(date, conId){tmpDate = date;conId = this._activeConInd (conId);this.activeCon = this.con [conId];if (typeof date != "Object")date = this.setFormatedDate(null ,tmpDate);if (isNaN(date)|| date == null)
 date = new Date (tmpDate);if (!isNaN(date)) {this.date[conId] = new Date(this.cutTime(date));this.selDate[conId] = new Date(this.cutTime(date))};if (this.isAutoDraw){this.draw()};if (this.activeCon.nodeName == 'INPUT')this.activeCon.value = this.getFormatedDate(this.options.dateformat, date) + (this.time ? " " + this.getFormatedTime () : "")},
 
 addClass:function(obj, styleName) {obj.className += ' ' + styleName},

 
 resetClass:function(obj) {obj.className = obj.className.toString().split(' ')[0]},

 resetHotClass:function(obj) {obj.className = obj.className.toString().replace(/hover/, '')},

 
 setSkin:function(newSkin) {this.skinName = newSkin;var mode = "";mode = (this.minimized
 ? "_mini" 
 : (this.time 
 ? "_long"
 : (this.options.isWinHeader
 ? "_maxi"
 : ""
 )
 )
 );this.entObj.className = this.style + (newSkin ? '_' + newSkin : '');if (mode)this.entObj.className += " " + this.entObj.className + mode;if(this.ifr!=undefined){this.ifr.className = this.style + (newSkin ? '_' + newSkin : '') + mode + "_ifr"};if (this.time)(this.isVisible () && !this.minimized) ? this.tp.show () : this.tp.hide ()},
 
 
 getDate:function(conId)
 {return this.selDate[this._activeConInd(conId)].toString()},
 
 

 nextMonth:function(){var date = this.date[0], month;date.setDate(1);date.setMonth(month = date.getMonth() + 1);this.callEvent ("onChangeMonth",[(month+1 > 12 ? 1 : month+1), month || 12]);if (this.isAutoDraw)this.draw()},
 
 
 prevMonth:function(){var date = this.date[0], month;date.setDate(1);date.setMonth(month = date.getMonth()-1);this.callEvent ("onChangeMonth",[month+1 || 12,month+2 > 12 ? 1 : (month+2 || 12)]);if (this.isAutoDraw)this.draw()},
 
 setOnClickHandler:function(func){this.attachEvent("onClick",func)},

 

 getFormatedDate:function (dateformat, date, conInd) {if(!dateformat)dateformat = this.options.dateformat
 if(!date)date = this.selDate[this._activeConInd(conInd)];date = new Date(date);var out = '';var plain = true;for (var i=0;i<dateformat.length;i++){var replStr = dateformat.substr(i, 1);if (plain){if (replStr == '%'){plain = false;continue};out += replStr}else {switch (replStr) {case 'e':
 replStr = date.getDate();break;case 'd':
 replStr = date.getDate();if (replStr.toString().length == 1)
 replStr='0'+replStr;break;case 'j':
 var x = new Date(date.getFullYear(), 0, 0, 0, 0, 0, 0);replStr = Math.ceil((date.valueOf() - x.valueOf())/1000/60/60/24 - 1);while (replStr.toString().length < 3)
 replStr = '0' + replStr;break;case 'a':
 replStr = this.options.daysSNames[date.getDay()];break;case 'W':
 replStr = this.options.daysFNames[date.getDay()];break;case 'c':
 replStr = 1 + date.getMonth();break;case 'm':
 replStr = 1 + date.getMonth();if (replStr.toString().length == 1)
 replStr = '0' + replStr;break;case 'b':
 replStr = this.options.monthesSNames[date.getMonth()];break;case 'M':
 replStr = this.options.monthesFNames[date.getMonth()];break;case 'y':
 replStr = date.getFullYear();replStr = replStr.toString().substr(2);break;case 'Y':
 replStr = date.getFullYear()};out += replStr;plain = true}};return out},

 


 setFormatedDate: function(dateformatarg, date, conInd, skip){if (!date || !(typeof date == 'string')) return date;if (self.time){self.time.setFormatedTIme(null, date.split(" ")[1]);date = date.split(" ")[0]};if(!dateformatarg)dateformatarg = this.options.dateformat;function parseMonth(val){var tmpAr = new Array(this.options.monthesSNames,this.options.monthesFNames);for(var j=0;j<tmpAr.length;j++){for (var i=0;i<tmpAr[j].length;i++)if (tmpAr[j][i].indexOf(val)== 0)
 return i};return -1};var outputDate = new Date(2008, 0, 1);var j=0;for(var i=0;i<dateformatarg.length;i++){var _char = dateformatarg.charAt(i);if(_char=="%"){var _cd = dateformatarg.charAt(i+1);var _nextpc = dateformatarg.indexOf("%",i+1);var _nextDelim = dateformatarg.substr(i+2,_nextpc-i-1-1);var _nDelimInDatePos = date.indexOf(_nextDelim,j);if(_nextDelim=="")_nDelimInDatePos = date.length
 if(_nDelimInDatePos==-1)return null;var value = date.substr(j, _nDelimInDatePos-j);if (_cd != 'M' && _cd != 'b')value = parseFloat(value);j=_nDelimInDatePos+_nextDelim.length
 switch (_cd) {case 'd':
 case 'e':
 outputDate.setDate(parseFloat(value));break;case "c":
 case "m":
 outputDate.setMonth(parseFloat(value) - 1);break;case "M":
 var val = parseMonth.call(this,value);if(val!=-1)outputDate.setMonth(parseFloat(val));else 
 return null;break;case "b":
 var val = parseMonth.call(this,value);if(val!=-1)outputDate.setMonth(parseFloat(val));else 
 return null;break;case 'Y':
 outputDate.setFullYear(parseFloat(value));break;case 'y':
 var year=parseFloat(value);outputDate.setFullYear(((year>20)?1900:2000) + year);break}}};if (isNaN(outputDate))
 outputDate = new Date(this.selDate[this._activeConInd]);if (skip)return outputDate;this.setDate (outputDate, conInd);return this.selDate[this. activeConInd]},

 
 isWeekend:function(k){var q = k + this.options.weekstart;if (q > 6)q -= 7;for (var i=0;i<this.options.weekend.length;i++)if (this.options.weekend[i] == q)return true;return false},

 
 getDayName:function(k){var q = k + this.options.weekstart;if (q > 6)q = q - 7;return this.options.daysSNames[q]},

 
 isVisible: function(){return this.parent.style.display != 'none'},
 doHotKeys:function(e){e = e||event;var cell = e.target || e.srcElement;if (cell.className.toString().indexOf('insensitive') >=0 ) {this.endHotKeys()}else {if (this.hotCell)this.resetHotClass(this.hotCell);this.addClass(cell, 'hover');this.hotCell = cell}},

 endHotKeys:function(){if (this.hotCell){this.resetHotClass(this.hotCell);this.hotCell = null}},
 _activeConInd:function(ind){if (!this.parent)this.createStructure();return (this.activeConInd = (this.conInd[ind]==0?'0':this.conInd[ind]) || (ind==0?'0':ind) || this.conInd[this.activeCon.id] || 0)}};function dhtmlxRichSelector(parametres) {for (x in parametres)this[x] = parametres[x];this.initValue = this.activeValue;if (!this.selectorSize)this.selectorSize = 7;var self = this;this.blurTimer = null;this.nodeBefore.onclick = function() {self.show()};this.editor = document.createElement('TEXTAREA');this.editor.value = this.activeValue;this.editor._s = this;this.editor.className = 'dhtmlxRichSelector';this.editor.onfocus = this.onFocus;this.editor.onblur = this.onBlur;this.selector = document.createElement('SELECT');this.selector.size = this.selectorSize;this.selector.className = 'dhtmlxRichSelector';if (this.valueList)for (var i = 0;i < this.valueList.length;i++)this.selector.options[i] = new Option(this.titleList[i], this.valueList[i], false, false);this.selector._s = this;this.selector.onfocus = this.onFocus;this.selector.onblur = this.onBlur;this.selector.onclick = function () {window.t = self;self.onSelect(self.selector.value);clearTimeout(self.blurTimer)};this.selector.getIndexByValue = function (Value, isFull) {var Select = this;Value = Value.toString().toUpperCase();if (!isFull)isFull=false;for (var i=0;i<Select.length;i++){var i_value = Select[i].text.toUpperCase();if (isFull){if(i_value == Value)return i}else {if (i_value.indexOf(Value)== 0) return i}};if (Select._s.isOrderedList){if (Select._s.isNumbersList)if (isNaN(Value)) return -1;i_value = Select[0].text.substring(0, Value.length).toUpperCase();if (i_value > Value)return 0;i_value = Select[Select.length-1].text.substring(0, Value.length);if (i_value < Value)return Select.length-1};return -1};this.con = document.createElement('DIV')
 this.con.className = 'dhtmlxRichSelector';with (this.con.style) {width = 'auto';display = 'none'};this.con.appendChild(this.editor);this.con.appendChild(this.selector);this.nodeBefore.parentNode.insertBefore(this.con, this.nodeBefore);return this};dhtmlxRichSelector.prototype.show = function() {this.con.style.display = 'block';with (this.selector.style) {marginTop = parseInt(this.nodeBefore.offsetHeight)+'px';width = 'auto'};with (this.editor.style) {width = parseInt(this.nodeBefore.offsetWidth)+15+'px';height = parseInt(this.nodeBefore.offsetHeight)+'px'};this.selector.selectedIndex = this.selector.getIndexByValue(this.activeValue);this.editor.focus()};dhtmlxRichSelector.prototype.hide = function() {this.con.style.display = 'none'};dhtmlxRichSelector.prototype.onBlur = function() {var self = this._s;self.blurTimer = setTimeout(function(){if (self.isAllowUserValue){if (self.onSelect(self.editor.value))
 self.activeValue = self.editor.value}else {if (self.onSelect(self.selector.value))
 self.activeValue = self.selector.value}}, 10)};dhtmlxRichSelector.prototype.onFocus = function() {var self = this._s;if(self.blurTimer){clearTimeout(self.blurTimer);self.blurTimer = null};if (this === this._s.selector)self.editor.focus()};dhtmlxCalendarObject.prototype.setHeader = function(isVisible, isDrag, btnsOpt){with (this.options) {isWinHeader = isVisible;isWinDrag = isDrag;if (btnsOpt)headerButtons = btnsOpt};this.setSkin (this.skinName)};dhtmlxCalendarObject.prototype.setYearsRange = function(minYear, maxYear){this.options.yearsRange = [parseInt(minYear), parseInt(maxYear)];this.allYears = [];for (var i=minYear;i <= maxYear;i++)this.allYears.push(i)};dhtmlxCalendarObject.prototype.startDrag = function(e) {e = e||event;if ((e.button === 0)|| (e.button === 1)) {if (this.dragging){this.stopDrag(e)};this.drag_mx = e.clientX;this.drag_my = e.clientY;this.drag_spos = this.getPosition(this.parent);document.body.appendChild(this.parent);with (this.parent.style) {left = this.drag_spos[0] + 'px';top = this.drag_spos[1] + 'px';margin = '0px';position = 'absolute'};if (this.ifr){this.ifr.style.top = '0px';this.ifr.style.left = '0px'};this.bu_onmousemove = document.body.onmousemove;var self = this;document.body.onmousemove = function (e) {self.onDrag(e)};this.bu_onmouseup = document.body.onmouseup;document.body.onmouseup = function (e) {self.stopDrag(e)};this.dragging = true}};dhtmlxCalendarObject.prototype.onDrag = function(e) {e = e||event;if ((e.button === 0)|| (e.button === 1)) {var delta_x = this.drag_mx - e.clientX;var delta_y = this.drag_my - e.clientY;this.parent.style.left = this.drag_spos[0] - delta_x + 'px';this.parent.style.top = this.drag_spos[1] - delta_y + 'px';if (this.time){this.tp.setPosition (getAbsoluteLeft (this.parent) + 30, getAbsoluteTop (this.parent) + 160)};if(this.ifr != undefined){this.ifr.style.left = 0;this.ifr.style.top = 0}}else {this.stopDrag(e)}};dhtmlxCalendarObject.prototype.stopDrag = function(e) {e = e||event;document.body.onmouseup = (this.bu_onmouseup === window.undefined)? null: this.bu_onmouseup;document.body.onmousemove = (this.bu_onmousemove === window.undefined)? null: this.bu_onmousemove;this.dragging = false};dhtmlxCalendarObject.prototype.minimize = function(){if (!this.winHeader)return;this.minimized = !this.minimized;this.entBox.style.display = (!this.minimized) ? '' : 'none';this.setSkin (this.skinName)};dhtmlxCalendarObject.prototype.onYearSelect = function(value) {if (!isNaN(value))
 {this._c.date[this._c._activeConInd()].setFullYear(
 Math.min 
 (
 Math.max 
 (
 value, 
 this._c.allYears[0]
 ), 
 this._c.allYears.slice(-1)
 )
 )};this._c.draw();return (!isNaN(value))};dhtmlxCalendarObject.prototype.onMonthSelect = function(value) {this._c.date[this._c._activeConInd()].setMonth(value);this._c.draw();return true};dhtmlxCalendarObject.prototype.setPosition = function(argA,argB,argC){if(typeof(argA)=='object'){var posAr = this.getPosition(argA)
 var left = posAr[0]+argA.offsetWidth+(argC||0);var top = posAr[1]+(argB||0)};this.parent.style.position = "absolute";this.parent.style.top = (top||argA)+"px";this.parent.style.left = (left||argB)+"px";if (this.ifr != undefined){this.ifr.style.left = '0px';this.ifr.style.top = '0px'};if (this.time)this.tp.setPosition (getAbsoluteLeft (this.parent) + 30, getAbsoluteTop (this.parent) + 160)};dhtmlxCalendarObject.prototype.close = function(func){this.hide ()};dhtmlxCalendarObject.prototype.getPosition = function(oNode,pNode) {if(!pNode)var pNode = document.body
 var oCurrentNode=oNode;var iLeft=0;var iTop=0;while ((oCurrentNode)&&(oCurrentNode!=pNode)){iLeft+=oCurrentNode.offsetLeft-oCurrentNode.scrollLeft;iTop+=oCurrentNode.offsetTop-oCurrentNode.scrollTop;oCurrentNode=oCurrentNode.offsetParent};if (pNode == document.body ){if (_isIE){if (document.documentElement.scrollTop)iTop+=document.documentElement.scrollTop;if (document.documentElement.scrollLeft)iLeft+=document.documentElement.scrollLeft}else
 if (!_isFF){iLeft+=document.body.offsetLeft;iTop+=document.body.offsetTop}};return new Array(iLeft,iTop)};dhtmlxCalendarObject.prototype.setSensitive = function(fromDate,toDate){if (fromDate)if (fromDate instanceof Date){this.sensitiveFrom = this.cutTime(fromDate)}else {this.sensitiveFrom = fromDate.toString ().split (',')};if (toDate)this.sensitiveTo = this.cutTime(toDate);if (this.isAutoDraw)this.draw()};dhtmlxCalendarObject.prototype.setHolidays = function(dates){this.holidays = dates.toString().split(",");if (this.isAutoDraw)this.draw()};dhtmlxCalendarObject.prototype.onChangeMonth = function (func) {this.attachEvent ("onChangeMonth",func)};dhtmlxCalendarObject.prototype.setInsensitiveDates = function (dates) {this.insensitiveDates = dates.toString().split(",");if (this.isAutoDraw)this.draw()};dhtmlxCalendarObject.prototype.enableTime = function (mode) {if (this.time = mode){this.tp = new dhtmlXTimePicker ();this.tp.setPosition (getAbsoluteLeft (this.parent) + 30, getAbsoluteTop (this.parent) + 160);for (m in dhtmlXTimePicker.prototype)(function (m) {if (!dhtmlxCalendarObject.prototype [m])dhtmlxCalendarObject.prototype [m] = function (){return this.tp[m].apply(this.tp, arguments)}})(m)}else {this.tp.entBox.parentNode.removeChild (this.tp.entBox);this.tp = null};this.setSkin(this.skinName)};dhtmlxCalendarObject.prototype.setHeaderText = function (text) {this.options.headerText = text;if (this.headerLabel){this.headerLabel.childNodes[0].nodeValue = text;this.headerLabel.setAttribute('title', text)}};dhtmlxCalendarObject.prototype.disableIESelectFix = function (mode) {this.useIframe = !mode;if (this.ifr != undefined){this.ifr.parentNode.removeChild(this.ifr);this.ifr = null}};(function(){dhtmlx.extend_api("dhtmlxCalendarObject",{_init:function(obj){return [obj.parent, obj.draw ]}},{});dhtmlx.extend_api("dhtmlxDblCalendarObject",{_init:function(obj){return [obj.parent, obj.draw ]}},{})})();dhtmlXGridObject.prototype._updateTGRState=function(z){if (!z.update || z.id==0)return;if (this.rowsAr[z.id].imgTag)this.rowsAr[z.id].imgTag.src=this.imgURL+z.state+".gif";z.update=false};dhtmlXGridObject.prototype.doExpand=function(obj){this.editStop();var row = obj.parentNode.parentNode.parentNode;var r=this._h2.get[row.idd];if (!this.callEvent("onOpen",[row.idd,(r.state=="plus"?-1:1)])) return;if(r.state=="plus")this.expandKids(row)
 else
 if((r.state=="minus")&&(!r._closeable))
 this.collapseKids(row)
};function dhtmlxHierarchy(){var z={id:0, childs:[], level:-1, parent:null, index:0, state:dhtmlXGridObject._emptyLineImg};this.order=[z];this.get={"0":z};this.swap=function(a,b){var p=a.parent;var z=a.index;p.childs[z]=b;p.childs[b.index]=a;a.index=b.index;b.index=z};this.forEachChildF=function(id,funct,that,funct2){var z=this.get[id];for (var i=0;i<z.childs.length;i++){if (!funct.apply((that||this),[z.childs[i]])) continue;if (z.childs[i].childs.length)this.forEachChildF(z.childs[i].id,funct,that,funct2);if (funct2)funct2.call((that||this),z.childs[i])}};this.forEachChild=function(id,funct,that){var z=this.get[id];for (var i=0;i<z.childs.length;i++){funct.apply((that||this),[z.childs[i]]);if (z.childs[i].childs.length)this.forEachChild(z.childs[i].id,funct,that)}};this.change=function(id,name,val){var z=this.get[id];if (z[name]==val)return;z[name]=val;z.update=true};this.add=function(id,parentId){return this.addAfter(id,parentId)};this.addAfter=function(id,parentId,afterId,fix){var z=this.get[parentId||0];if (afterId)var ind=this.get[afterId].index+(fix?0:1);else var ind=z.childs.length;var x={id:id, childs:[], level:z.level+1, parent:z, index:ind, state:dhtmlXGridObject._emptyLineImg};if (z.state==dhtmlXGridObject._emptyLineImg)this.change(parentId,"state",(parentId==0?"minus":"plus"));if (afterId){for (var i=ind;i<z.childs.length;i++)z.childs[i].index++;z.childs=z.childs.slice(0,ind).concat([x]).concat(z.childs.slice(ind,z.childs.length))}else
 z.childs.push(x);this.get[id]=x;return x};this.addBefore=function(id,parentId,beforeId){return this.addAfter(id,parentId,beforeId,true)
 };this.remove=function(id){var z=this.get[id||0];for (var i=0;i<z.childs.length;i++)this.deleteAll(z.childs[i].id)
 z.childs=[];z.parent.childs=z.parent.childs.slice(0,z.index).concat(z.parent.childs.slice(z.index+1));for (var i=z.index;i<z.parent.childs.length;i++)z.parent.childs[i].index--;delete this.get[id]};this.deleteAll=function(id){var z=this.get[id||0];for (var i=0;i<z.childs.length;i++)this.deleteAll(z.childs[i].id)
 
 z.childs=[];delete this.get[id]};return this};dhtmlXGridObject.prototype._getOpenLenght=function(id,start){var z=this._h2.get[id].childs;start+=z.length;for (var i=0;i<z.length;i++)if (z[i].childs.length && z[i].state=='minus')start+=this._getOpenLenght(z[i].id,0);return start};dhtmlXGridObject.prototype.collapseKids=function(curRow){var r=this._h2.get[curRow.idd];if (r.state!="minus")return;if (!this.callEvent("onOpenStart",[curRow.idd,1])) return;var start = curRow.rowIndex;if (start<0)start=this.rowsCol._dhx_find(curRow)+1;this._h2.change(r.id,"state","plus");this._updateTGRState(r);if (this._srnd || this.pagingOn){this._h2_to_buff();this._renderSort()}else {var len=this._getOpenLenght(this.rowsCol[start-1].idd,0);for (var i=0;i<len;i++)this.rowsCol[start+i].parentNode.removeChild(this.rowsCol[start+i]);this.rowsCol.splice(start,len)};this.callEvent("onGridReconstructed",[]);this.setSizes();this._h2_to_buff();this.callEvent("onOpenEnd",[curRow.idd,-1])};dhtmlXGridObject.prototype._massInsert=function(r,start,ind,skip){var anew=[];var par=(_isKHTML?this.obj:this.obj.rows[0].parentNode)
 this._h2_to_buff();if (this._srnd || this.pagingOn)return this._renderSort();var len=this._getOpenLenght(r.id,0);for(var i=0;i<len;i++){var ra=this.render_row(ind+i);if (start)start.parentNode.insertBefore(ra,start);else
 par.appendChild(ra);anew.push(ra)
 };this.rowsCol=dhtmlxArray(this.rowsCol.slice(0,ind).concat(anew).concat(this.rowsCol.slice(ind)));return r.childs.length+anew.length};dhtmlXGridObject.prototype.expandKids=function(curRow,sEv){var r=this._h2.get[curRow.idd];if ((!r.childs.length)&&(!r._xml_await)) return;if (r.state!="plus")return;if (!r._loading && !sEv)if (!this.callEvent("onOpenStart",[r.id,-1])) return;var start = this.getRowIndex(r.id)+1;if(r.childs.length){r._loading=false;this._h2.change(r.id,"state","minus")
 this._updateTGRState(r);var len=this._massInsert(r,this.rowsCol[start],start);this.callEvent("onGridReconstructed",[])}else{if (r._xml_await){r._loading=true;if (this.callEvent("onDynXLS",[r.id]))
 this.loadXML(this.kidsXmlFile+""+(this.kidsXmlFile.indexOf("?")!=-1?"&":"?")+"id="+r.id)}};this.setSizes();if (!r._loading)this.callEvent("onOpenEnd",[r.id,1]);this._fixAlterCss()};dhtmlXGridObject.prototype.kidsXmlFile = "";dhtmlXGridObject.prototype.sortTreeRows = function(col,type,order){var amet="getValue";if (this.cells5({parentNode:{grid:this}},this.getColType(col)).getDate){amet="getDate";type="str"};this.forEachRow(function(id){var z=this._h2.get[id];if (!z)return;var label=this._get_cell_value(z.buff,col,amet);if(type=='int'){z._sort=parseFloat(label);z._sort=isNaN(z._sort)?-99999999999999:z._sort}else
 z._sort=label});var self=this;var pos=1;var neg=-1;if (order=="des"){pos=-1;neg=1};var funct=null;if(type=='cus')funct=function(a,b){return self._customSorts[col](a._sort,b._sort,order,a.id,b.id)};if(type=='str')funct=function(a,b){return (a._sort<b._sort?neg:(a._sort==b._sort?0:pos))};if(type=='int')funct=function(a,b){return (a._sort<b._sort?neg:(a._sort==b._sort?0:pos))};if(type=='date')funct=function(a,b){return (Date.parse(new Date(a._sort||"01/01/1900"))-Date.parse(new Date(b._sort||"01/01/1900")))*pos};this._sortTreeRows(funct,0);this._renderSort(0,true);this.callEvent("onGridReconstructed",[])};dhtmlXGridObject.prototype._sortTreeRows = function(funct,id){var ar=this._h2.get[id].childs;ar.sort(funct);for (var i=0;i<ar.length;i++){if (ar[i].childs.length)this._sortTreeRows(funct,ar[i].id);ar[i].index=i}};dhtmlXGridObject.prototype._renderSort = function(id,mode){this._h2_to_buff();var top=this.objBox.scrollTop;this._reset_view();this.objBox.scrollTop=top};dhtmlXGridObject.prototype._fixAlterCssTGR = function(){if (!this._realfake)this._h2.forEachChild(0,function(x){if (x.buff.tagName=="TR"){var cs=(this._cssSP?(x.level%2):(x.index%2))?this._cssUnEven:this._cssEven;this.rowsAr[x.id].className=(cs + (this._cssSU?(" "+cs+"_"+x.level):""))+" "+(this.rowsAr[x.id]._css||"")+((this.rowsAr[x.id].className.indexOf("rowselected") != -1)?" rowselected":"")}},this)};dhtmlXGridObject.prototype.moveRowUDTG = function(id,dir){var x=this._h2.get[id];var p=x.parent.childs[x.index+dir]
 if ((!p)|| (p.parent!=x.parent)) return;var state=[x.state,p.state];this.collapseKids(this.rowsAr[x.id]);this.collapseKids(this.rowsAr[p.id]);var ind = this.rowsCol._dhx_find(this.rowsAr[id]);var bInd = this.rowsBuffer._dhx_find(this.rowsAr[id]);var nod=this.obj.rows[0].parentNode.removeChild(this.rowsCol[ind]);var tar=this.rowsCol[ind+((dir==1)?2:dir)];if (tar)tar.parentNode.insertBefore(nod,tar);else
 this.obj.rows[0].parentNode.appendChild(nod);this.rowsCol._dhx_swapItems(ind,ind+dir)
 this.rowsBuffer._dhx_swapItems(bInd,bInd+dir);this._h2.swap(p,x);if (state[0]=="minus")this.expandKids(this.rowsAr[x.id]);if (state[1]=="minus")this.expandKids(this.rowsAr[p.id]);this._fixAlterCss(Math.min(ind,ind+dir))};function eXcell_tree(cell){if (cell){this.cell = cell;this.grid = this.cell.parentNode.grid};this.isDisabled = function(){return this.grid._edtc};this.edit = function(){if ((this.er)||(this.grid._edtc)) return;this.er=this.cell.parentNode.valTag;this.val=this.getLabel();this.cell.atag=((!this.grid.multiLine)&&(_isKHTML||_isMacOS||_isFF)) ? "INPUT" : "TEXTAREA";this.er.innerHTML="<"+this.cell.atag+" class='dhx_combo_edit' type='text' style='height:"+(this.cell.offsetHeight-6)+"px;width:100%;border:0px;margin:0px;padding:0px;padding-top:"+(_isFF?1:2)+"px;overflow:hidden;'></"+this.cell.atag+">";this.er.childNodes[0].onmousedown = function(e){(e||event).cancelBubble = true};this.er.childNodes[0].onselectstart=function(e){if (!e)e=event;e.cancelBubble=true;return true};if (_isFF)this.er.style.top="1px";this.er.className+=" editable";this.er.firstChild.onclick = function(e){(e||event).cancelBubble = true};this.er.firstChild.value=this.val;this.obj=this.er.firstChild;this.er.firstChild.style.width=Math.max(0,this.cell.offsetWidth-this.er.offsetLeft)+"px";this.er.firstChild.focus();if (_isIE)this.er.firstChild.focus()};this.detach = function(){if (!this.er)return;this.setLabel(this.er.firstChild.value);this.er.className=this.er.className.replace("editable","");var z=(this.val!=this.er.innerHTML);if (_isFF)this.er.style.top="2px";this.obj=this.er=null;return (z)};this.getValue = function(){return this.getLabel()};this.setImage = function(url){this.cell.parentNode.imgTag.nextSibling.src=this.grid.iconURL+url;this.grid._h2.get[this.cell.parentNode.idd].image=url};this.getImage = function(){this.grid._h2.get[this.cell.parentNode.idd].image};this.setLabel = function(val){this.setValueA(val)};this.getLabel = function(val){return this.cell.parentNode.valTag.innerHTML}};eXcell_tree.prototype = new eXcell;eXcell_tree.prototype.setValueA = function(content){this.cell.parentNode.valTag.innerHTML=content;this.grid.callEvent("onCellChanged",[this.cell.parentNode.idd,this.cell._cellIndex,content])
 };eXcell_tree.prototype.setValue = function(valAr){if (this.cell.parentNode.imgTag)return this.setLabel(valAr);if ((this.grid._tgc.imgURL==null)||(this.grid._tgc.imgURL!=this.grid.imgURL)){var _tgc={};_tgc.spacer="<img src='"+this.grid.imgURL+"blank.gif' align='absmiddle' class='space'>";_tgc.imst="<img src='"+this.grid.imgURL;_tgc.imsti="<img src='"+(this.grid.iconURL||this.grid.imgURL);_tgc.imact="' align='absmiddle' onclick='this."+(_isKHTML?"":"parentNode.")+"parentNode.parentNode.parentNode.parentNode.grid.doExpand(this);event.cancelBubble=true;'>"
 _tgc.plus=_tgc.imst+"plus.gif"+_tgc.imact;_tgc.minus=_tgc.imst+"minus.gif"+_tgc.imact;_tgc.blank=_tgc.imst+"blank.gif"+_tgc.imact;_tgc.start="<div class='treegrid_cell' style='overflow:hidden;white-space : nowrap;height:"+(_isIE?20:18)+"px;'>";_tgc.itemim="' align='absmiddle' "+(this.grid._img_height?(" height=\""+this.grid._img_height+"\""):"")+(this.grid._img_width?(" width=\""+this.grid._img_width+"\""):"")+" ><span "+((_isFF||_isOpera)?"style='position:relative;top:2px;'":"")+"id='nodeval'>";_tgc.close="</span></div>";this.grid._tgc=_tgc};var _h2=this.grid._h2;var _tgc=this.grid._tgc;var rid=this.cell.parentNode.idd;var row=this.grid._h2.get[rid];if (this.grid.kidsXmlFile || this.grid._slowParse){row.has_kids=(row.has_kids||(this.cell.parentNode._attrs["xmlkids"]&&(row.state!="minus")));row._xml_await=!!row.has_kids};row.image=row.image||(this.cell._attrs["image"]||"leaf.gif");row.label=valAr;var html=[_tgc.start];for(var i=0;i<row.level;i++)html.push(_tgc.spacer);if(row.has_kids){html.push(_tgc.plus);row.state="plus"
 }else
 html.push(_tgc.imst+row.state+".gif"+_tgc.imact);html.push(_tgc.imsti);html.push(row.image);html.push(_tgc.itemim);html.push(row.label);html.push(_tgc.close);this.cell.innerHTML=html.join("");this.cell.parentNode.imgTag=this.cell.childNodes[0].childNodes[row.level];this.cell.parentNode.valTag=this.cell.childNodes[0].childNodes[row.level+2];if (_isKHTML)this.cell.vAlign="top";if (row.parent.id!=0 && row.parent.state=="plus"){this.grid._updateTGRState(row.parent,false);this.cell.parentNode._skipInsert=true};this.grid.callEvent("onCellChanged",[rid,this.cell._cellIndex,valAr])};dhtmlXGridObject.prototype._process_tree_xml=function(xml,top,pid){this._parsing=true;var main=false;if (!top){this.render_row=this.render_row_tree;main=true;top=xml.getXMLTopNode(this.xml.top) 
 pid=top.getAttribute("parent")||0;if (pid=="0")pid=0;if (!this._h2)this._h2=new dhtmlxHierarchy();if (this._fake)this._fake._h2=this._h2};var rows=xml.doXPath(this.xml.row,top)
 this._open=this._open||[];for (var i=0;i < rows.length;i++){var id=rows[i].getAttribute("id");if (!id){id=this.uid();rows[i].setAttribute("id",id)};var row=this._h2.add(id,pid);row.buff={idd:id, data:rows[i], _parser: this._process_xml_row, _locator:this._get_xml_data };if (rows[i].getAttribute("open")){row.state="minus";this._open.push(id)};this.rowsAr[id]=row.buff;this._process_tree_xml(xml,rows[i],id)};if (main){if (!rows.length)this._h2.change(pid,"state",dhtmlXGridObject._emptyLineImg);else if (pid!=0 && !this._srnd){this._h2.change(pid,"state","minus");this.callEvent("onOpenEnd",[pid,1])};for (var i=0;i < this._open.length;i++){var r=this._h2.get[this._open[i]];if (!r.childs.length)r.state=dhtmlXGridObject._emptyLineImg};this._updateTGRState(this._h2.get[pid]);this._h2_to_buff();if (pid!=0 && this._srnd)this.openItem(pid);else {if (this.pagingOn)this._renderSort();else
 this.render_dataset()};if (this.kidsXmlFile){for (var i=0;i < this._open.length;i++){var r=this._h2.get[this._open[i]];if (r._xml_await)this.expandKids({idd:r.id})}};this._open=[];if (this._slowParse===false){this.forEachRow(function(id){this.render_row_tree(0,id)
 })
 };this._parsing=false}};dhtmlXGridObject.prototype._h2_to_buff=function(top){if (!top){top=this._h2.get[0];this.rowsBuffer = new dhtmlxArray()};for (var i=0;i < top.childs.length;i++){this.rowsBuffer.push(top.childs[i].buff);if (top.childs[i].state == "minus")this._h2_to_buff(top.childs[i])}};dhtmlXGridObject.prototype.render_row_tree=function(ind,id){if (id){var r=this._h2.get[id];r=r?r.buff:r}else
 var r=this.rowsBuffer[ind];if (!r)return -1;if (r._parser){if (this.rowsAr[r.idd] && this.rowsAr[r.idd].tagName=="TR")return this._h2.get[r.idd].buff=this.rowsBuffer[ind]=this.rowsAr[r.idd];var row=this._prepareRow(r.idd);this.rowsAr[r.idd]=row;if (!id)this.rowsBuffer[ind]=row;this._h2.get[r.idd].buff=row;r._parser.call(this,row,r.data);this._postRowProcessing(row);return row};return r};dhtmlXGridObject.prototype._removeTrGrRow=function(node,x){if(x){this._h2.forEachChild(x.id,function(x){this._removeTrGrRow(null,x);delete this.rowsAr[x.id]},this);return};var ind=this.getRowIndex(node.idd);var x=this._h2.get[node.idd];if (ind!=-1 && ind!==this.undefined){var len=1;if (x && x.state=="minus")len+=this._getOpenLenght(x.id,0)
 for (var i=0;i<len;i++)if (this.rowsCol[i+ind])this.rowsCol[i+ind].parentNode.removeChild(this.rowsCol[i+ind]);if (this._fake)for (var i=0;i<len;i++)this._fake.rowsCol[i+ind].parentNode.removeChild(this._fake.rowsCol[i+ind]);this.rowsCol.splice(ind,len);this.rowsBuffer.splice(ind,len)};if (!x)return;this._removeTrGrRow(null,x);delete this.rowsAr[x.id];if (x.parent.childs.length==1){this._h2.change(x.parent.id,"state",dhtmlXGridObject._emptyLineImg);this._updateTGRState(x.parent)};this._h2.remove(x.id)};dhtmlXGridObject.prototype.openItem=function(rowId){var y=this._h2.get[rowId||0];var x=this.getRowById(rowId||0);if (!x)return;if (y.parent && y.parent.id!=0)this.openItem(y.parent.id);this.expandKids(x)};dhtmlXGridObject.prototype._addRowClassic=dhtmlXGridObject.prototype.addRow;dhtmlXGridObject.prototype.addRow=function(new_id,text,ind,parent_id,img,child){if (!this._h2)return this._addRowClassic(new_id,text,ind);parent_id=parent_id||0;var trcol=this.cellType._dhx_find("tree");if (typeof(text)=="string") text=text.split(this.delim);var row=this._h2.get[new_id];if (!row){if (parent_id==0)ind=this.rowsBuffer.length;else{ind=this.getRowIndex(parent_id)+1;if (this._h2.get[parent_id].state=="minus")ind+=this._getOpenLenght(parent_id,0);else
 this._skipInsert=true}};row=row||this._h2.add(new_id,parent_id);row.image=img;row.has_kids=child;return row.buff=this._addRowClassic(new_id,text,ind)};dhtmlXGridObject.prototype.addRowBefore=function(new_id,text,sibl_id,img,child){var sb=this.rowsAr[sibl_id];if (!sb)return;if (!this._h2)return this.addRow(new_id,text,this.getRowIndex(sibl_id));var pid=this._h2.get[sibl_id].parent.id;var ind=this.getRowIndex(sibl_id);if (ind==-1)this._skipInsert=true;this._h2.addBefore(new_id,pid,sibl_id);return this.addRow(new_id,text,ind,this._h2.get[sibl_id].parent.id,img,child)};dhtmlXGridObject.prototype.addRowAfter=function(new_id,text,sibl_id,img,child){var sb=this.rowsAr[sibl_id];if (!sb)return;if (!this._h2)return this.addRow(new_id,text,this.getRowIndex(sibl_id)+1);var pid=this._h2.get[sibl_id].parent.id;var ind=this.getRowIndex(sibl_id);if (ind==-1)this._skipInsert=true;if (this._h2.get[sibl_id].state=="minus")ind+=this._getOpenLenght(sibl_id,0)+1;else ind++;this._h2.addAfter(new_id,pid,sibl_id);return this.addRow(new_id,text,ind,pid,img,child)};dhtmlXGridObject.prototype.enableSmartXMLParsing=function(mode) {this._slowParse=convertStringToBoolean(mode)};dhtmlXGridObject.prototype._copyTreeGridRowContent=function(frRow,from_row_id,to_row_id){var z=this.cellType._dhx_find("tree");for(i=0;i<frRow.cells.length;i++){if (i!=z)this.cells(to_row_id,i).setValue(this.cells(from_row_id,i).getValue())
 else
 this.cells(to_row_id,i).setValueA(this.cells(from_row_id,i).getValue())

 }};dhtmlXGridObject.prototype.closeItem=function(rowId){var x=this.getRowById(rowId);if (!x)return;this.collapseKids(x)};dhtmlXGridObject.prototype.deleteChildItems=function(rowId){var z=this._h2.get[rowId];if (!z)return;while (z.childs.length)this.deleteRow(z.childs[0].id)};dhtmlXGridObject.prototype.getAllSubItems=function(rowId){var str=[];var z=this._h2.get[rowId||0];if (z)for (var i=0;i<z.childs.length;i++){str.push(z.childs[i].id);if (z.childs[i].childs.length)str=str.concat(this.getAllSubItems(z.childs[i].id).split(this.delim))};return str.join(this.delim)};dhtmlXGridObject.prototype.getChildItemIdByIndex=function(rowId,ind){var z=this._h2.get[rowId||0];if (!z)return null;return (z.childs[ind]?z.childs[ind].id:null)};dhtmlXGridObject.prototype.getItemText=function(rowId){return this.cells(rowId,this.cellType._dhx_find("tree")).getLabel()};dhtmlXGridObject.prototype.getOpenState=function(rowId){var z=this._h2.get[rowId||0];if (!z)return;if (z.state=="minus")return true;return false};dhtmlXGridObject.prototype.getParentId=function(rowId){var z=this._h2.get[rowId||0];if ((!z)|| (!z.parent)) return null;return z.parent.id};dhtmlXGridObject.prototype.getSubItems=function(rowId){var str=[];var z=this._h2.get[rowId||0];if (z)for (var i=0;i<z.childs.length;i++)str.push(z.childs[i].id);return str.join(this.delim)};dhtmlXGridObject.prototype.expandAll=function(){this._renderAllExpand(0);this._h2_to_buff();this._reset_view();this.setSizes();this.callEvent("onGridReconstructed",[]);if (this._redrawLines)this._redrawLines()};dhtmlXGridObject.prototype._renderAllExpand=function(z){var x=this._h2.get[z].childs;for (var i=0;i<x.length;i++){if (x[i].childs.length){this._h2.change(x[i].id,"state","minus")
 this._updateTGRState(x[i]);this._renderAllExpand(x[i].id)
 }}};dhtmlXGridObject.prototype.collapseAll=function(rowId){this._h2.forEachChild(0,function(z){if (z && z.state=="minus"){z.state="plus";z.update=true;this._updateTGRState(z)}},this);this._h2_to_buff();this._reset_view();this.setSizes();this.callEvent("onGridReconstructed",[]);if (this._redrawLines)this._redrawLines()};dhtmlXGridObject.prototype.hasChildren=function(rowId){var x=this._h2.get[rowId];if (x && x.childs.length)return x.childs.length;if (x._xml_await)return -1;return 0};dhtmlXGridObject.prototype.setItemCloseable=function(rowId,status){var x=this._h2.get[rowId];if (!x)return;x._closeable=(!convertStringToBoolean(status))};dhtmlXGridObject.prototype.setItemText=function(rowId,newtext){return this.cells(rowId,this.cellType._dhx_find("tree")).setLabel(newtext)};dhtmlXGridObject.prototype.setItemImage=function(rowId,url){this._h2.get[rowId].image=url;this.rowsAr[rowId].imgTag.nextSibling.src=url};dhtmlXGridObject.prototype.getItemImage=function(rowId){this.getRowById(rowId);return this._h2.get[rowId].image};dhtmlXGridObject.prototype.setImageSize=function(width,height){this._img_width=width;this._img_height=height};dhtmlXGridObject.prototype._getRowImage=function(row){return this._h2.get[row.idd].image};dhtmlXGridObject.prototype.setOnOpenStartHandler=function(func){this.attachEvent("onOpenStart",func)};dhtmlXGridObject.prototype.setOnOpenEndHandler=function(func){this.attachEvent("onOpenEnd",func)};dhtmlXGridObject.prototype.enableTreeCellEdit=function(mode){this._edtc=!convertStringToBoolean(mode)};dhtmlXGridObject.prototype.getLevel=function(rowId){var z=this._h2.get[rowId||0];if (!z)return -1;return z.level};dhtmlXGridObject.prototype._fixHiddenRowsAllTG=function(ind,state){for (i in this.rowsAr){if ((this.rowsAr[i])&&(this.rowsAr[i].childNodes))
 this.rowsAr[i].childNodes[ind].style.display=state}};dhtmlXGridObject._emptyLineImg="blank";dhtmlXGridObject._emptyLineImg="line";dhtmlXGridObject.prototype._updateTGRState=function(z,force){if (force || !z.update || z.id==0)return;this._updateLine(z,this.rowsAr[z.id]);z.update=false};dhtmlXGridObject.prototype._updateLine=function(z,row){row=row||this.rowsAr[z.id];if (!row)return;var im=row.imgTag;if (!im)return;if (z.state=="blank")return im.src=this.imgURL+"blank.gif";var n=1;if (z.index==0){if (z.level==0){if ((z.parent.childs.length-1)>z.index)
 n=3;else n=1}else
 {if ((z.parent.childs.length-1)>z.index)
 n=3;else
 n=2}}else
 if ((z.parent.childs.length-1)>z.index)
 n=3;else
 n=2;im.src=this.imgURL+z.state+n+".gif"};dhtmlXGridObject.prototype._updateParentLine=function(z,row){row=row||this.rowsAr[z.id];if (!row)return;var im=row.imgTag;if (!im)return;for (var i=z.level;i>0;i--){if (z.id==0)break;im=im.previousSibling;z=z.parent;if ((z.parent.childs.length-1)>z.index)
 im.src=this.imgURL+"line1.gif";else
 im.src=this.imgURL+"blank.gif"}};dhtmlXGridObject.prototype._renderSortA=dhtmlXGridObject.prototype._renderSort;dhtmlXGridObject.prototype._renderSort=function(){this._renderSortA.apply(this,arguments);this._redrawLines(0) 
};dhtmlXGridObject.prototype._redrawLines=function(id){this._h2.forEachChild((id||0),function(z){this._updateLine(z);this._updateParentLine(z)},this)};dhtmlXGridObject.prototype.enableTreeGridLines=function(){this._tgle=true;this.attachEvent("onXLE",function(a,b,id){this._redrawLines(id)
 });this.attachEvent("onOpenEnd",function(id){this._redrawLines(id)
 });this.attachEvent("onRowAdded",function(id){var z=this._h2.get[id];this._updateLine(z);this._updateParentLine(z);if (z.index<(z.parent.childs.length-1)){z=z.parent.childs[z.index+1];this._updateLine(z);this._updateParentLine(z)}else if (z.index!=0){z=z.parent.childs[z.index-1];this._updateLine(z);this._updateParentLine(z);if (z.childs.length)this._h2.forEachChild(z.id,function(c_el){this._updateParentLine(c_el)
 },this)
 }});this.attachEvent("onOpen",function(id,state){if (state){var z=this._h2.get[id];for (var i=0;i < z.childs.length;i++)this._updateParentLine(z.childs[i])};return true});this.attachEvent("onBeforeRowDeleted",function(id){var self=this;var z=this._h2.get[id];var w=null;if (z.index!=0)w=z.parent.childs[z.index-1];z=z.parent;window.setTimeout(function(){z = self._h2.get[z.id];if (!z)return;self._updateLine(z);self._updateParentLine(z);if (w){self._updateLine(w);if (w.state=="minus")self._h2.forEachChild(w.id,function(z){self._updateParentLine(z)},self)}},1);return true})};dhtmlXGridObject.prototype.setFiltrationLevel=function(level,show_lower,show_upper){this._tr_strfltr=level;this._tr_fltr_c=show_lower;this._tr_fltr_d=show_upper;this.refreshFilters()};dhtmlXGridObject.prototype.filterTreeBy=function(column, value, preserve){var origin = this._h2;if (typeof this._tr_strfltr == "undefined")this._tr_strfltr=-1;if (this._f_rowsBuffer){if (!preserve){this._h2=this._f_rowsBuffer;if (this._fake)this._fake._h2=this._h2}}else
 this._f_rowsBuffer=this._h2;var d=true;this.dma(true)
 this._fbf={};if (typeof(column)=="object")
 for (var j=0;j<value.length;j++)this._filterTreeA(column[j],value[j]);else
 this._filterTreeA(column,value);this._fbf=null;this.dma(false)
 this._fix_filtered_images(this._h2,origin);this._renderSort()
 this.callEvent("onGridReconstructed",[])
};dhtmlXGridObject.prototype._filterTreeA=function(column,value){if (value=="")return;var d=true;if (typeof(value)=="function") d=false;else value=(value||"").toString().toLowerCase();var add_line=function(el,s,t){var z=t.get[el.parent.id];if (!z)z=add_line(el.parent,s,t)
 var t=temp.get[el.id];if (!t){t={id:el.id, childs:[], level:el.level, parent:z, index:z.childs.length, image:el.image, state:el.state, buff:el.buff, has_kids:el.has_kids};z.childs.push(t);temp.get[t.id]=t};return t};var fbf=this._fbf;var temp = new dhtmlxHierarchy();var check;var mode = this._tr_strfltr;var that=this;var temp_c=function(el){for (var i=0;i < el.childs.length;i++)that.temp(el.childs[i])};switch(mode.toString()){case "-2": check=function(el){if (fbf[el.id])return false;temp_c(el);return true};break;case "-1": check=function(el){return !el.childs.length};break;default: check=function(el){return mode==el.level};break};this.temp=function(el){if (el.id!=0 && check(el)){if (d?(this._get_cell_value(el.buff,column).toString().toLowerCase().indexOf(value)==-1):(!value(this._get_cell_value(el.buff,column),el.id))){fbf[el.id]=true;if (this._tr_fltr_c)add_line(el.parent,this._h2,temp);return false}else {add_line(el,this._h2,temp);if (el.childs && mode!=-2)this._h2.forEachChild(el.id,function(cel){add_line(cel,this._h2,temp)},this)
 return true}}else {if (this._tr_fltr_d && this._tr_strfltr > el.level && el.id!=0)add_line(el,this._h2,temp);temp_c(el)}};this.temp(this._h2.get[0]);this._h2=temp;if (this._fake)this._fake._h2=this._h2};dhtmlXGridObject.prototype._fix_filtered_images=function(temp,origin){temp.forEachChild(0,function(el){if (!el.childs.length && !el.has_kids){if (el.state!=dhtmlXGridObject._emptyLineImg){el.state=dhtmlXGridObject._emptyLineImg;el.update=true;this._updateTGRState(el)}}else {if (el.buff.tagName=="TR"){var prev=origin.get[el.id];if (prev && prev.state!="blank")el.state=prev.state;el.update=true;this._updateTGRState(el)}}},this)
};dhtmlXGridObject.prototype.collectTreeValues=function(column){if (typeof this._tr_strfltr == "undefined")this._tr_strfltr=-1;this.dma(true)
 this._build_m_order();column=this._m_order?this._m_order[column]:column;var c={};var f=[];var col=this._f_rowsBuffer||this._h2;col.forEachChild(0,function(el){if (this._tr_strfltr==-2 || (this._tr_strfltr==-1 && !el.childs.length)|| (this._tr_strfltr==el.level)){var val=this._get_cell_value(el.buff,column);if (val)c[val]=true}},this);this.dma(false)
 
 var vals=this.combos[column];for (d in c)if (c[d]===true)f.push(vals?(vals.get(d)||d):d);return f.sort()};dhtmlXGridObject.prototype._in_header_stat_tree_total=function(t,i,c){var calck=function(){var summ=0;this._h2.forEachChild(0,function(el){var v=parseFloat(this._get_cell_value((el.buff||this.rowsAr[el.id]),i));summ+=isNaN(v)?0:v},this)
 return this._maskArr[i]?this._aplNF(summ,i):(Math.round(summ*100)/100)};this._stat_in_header(t,calck,i,c,c)};dhtmlXGridObject.prototype._in_header_stat_tree_total_leaf=function(t,i,c){var calck=function(){var summ=0;this._h2.forEachChild(0,function(el){if (el.childs.length)return;var v=parseFloat(this._get_cell_value((el.buff||this.rowsAr[el.id]),i));summ+=isNaN(v)?0:v},this)
 return this._maskArr[i]?this._aplNF(summ,i):(Math.round(summ*100)/100)};this._stat_in_header(t,calck,i,c,c)};dhtmlXGridObject.prototype._in_header_stat_tree_multi_total=function(t,i,c){var cols=c[1].split(":");c[1]="";var calck=function(){var summ=0;this._h2.forEachChild(0,function(el){var v=parseFloat(this._get_cell_value((el.buff||this.rowsAr[el.id]),cols[0]))*parseFloat(this._get_cell_value((el.buff||this.rowsAr[el.id]),cols[1]));summ+=isNaN(v)?0:v},this)
 return this._maskArr[i]?this._aplNF(summ,i):(Math.round(summ*100)/100)};this._stat_in_header(t,calck,i,c,c)};dhtmlXGridObject.prototype._in_header_stat_tree_multi_total_leaf=function(t,i,c){var cols=c[1].split(":");c[1]="";var calck=function(){var summ=0;this._h2.forEachChild(0,function(el){if (el.childs.length)return;var v=parseFloat(this._get_cell_value((el.buff||this.rowsAr[el.id]),cols[0]))*parseFloat(this._get_cell_value((el.buff||this.rowsAr[el.id]),cols[1]));summ+=isNaN(v)?0:v},this)
 return this._maskArr[i]?this._aplNF(summ,i):(Math.round(summ*100)/100)};this._stat_in_header(t,calck,i,c,c)};dhtmlXGridObject.prototype._in_header_stat_tree_max=function(t,i,c){var calck=function(){var summ=-999999999;if (this.getRowsNum()==0) return "";this._h2.forEachChild(0,function(el){var d=parseFloat(this._get_cell_value((el.buff||this.rowsAr[el.id]),i));if (!isNaN(d))
 summ=Math.max(summ,d)},this)
 return this._maskArr[i]?this._aplNF(summ,i):summ};this._stat_in_header(t,calck,i,c)};dhtmlXGridObject.prototype._in_header_stat_tree_min=function(t,i,c){var calck=function(){var summ=999999999;if (this.getRowsNum()==0) return "";this._h2.forEachChild(0,function(el){var d=parseFloat(this._get_cell_value((el.buff||this.rowsAr[el.id]),i));if (!isNaN(d))
 summ=Math.min(summ,d)},this)
 return this._maskArr[i]?this._aplNF(summ,i):summ};this._stat_in_header(t,calck,i,c)};dhtmlXGridObject.prototype._in_header_stat_tree_average=function(t,i,c){var calck=function(){var summ=0;var count=0;this._h2.forEachChild(0,function(el){var v=parseFloat(this._get_cell_value((el.buff||this.rowsAr[el.id]),i));summ+=isNaN(v)?0:v;count++},this)
 return this._maskArr[i]?this._aplNF(summ,i):(Math.round(summ/count*100)/100)};this._stat_in_header(t,calck,i,c)};dhtmlXGridObject.prototype._in_header_stat_tree_max_leaf=function(t,i,c){var calck=function(){var summ=-999999999;if (this.getRowsNum()==0) return "";this._h2.forEachChild(0,function(el){if (el.childs.length)return;var d=parseFloat(this._get_cell_value((el.buff||this.rowsAr[el.id]),i));if (!isNaN(d))
 summ=Math.max(summ,d)},this)
 return this._maskArr[i]?this._aplNF(summ,i):summ};this._stat_in_header(t,calck,i,c)};dhtmlXGridObject.prototype._in_header_stat_tree_min_leaf=function(t,i,c){var calck=function(){var summ=999999999;if (this.getRowsNum()==0) return "";this._h2.forEachChild(0,function(el){if (el.childs.length)return;var d=parseFloat(this._get_cell_value((el.buff||this.rowsAr[el.id]),i));if (!isNaN(d))
 summ=Math.min(summ,d)},this)
 return this._maskArr[i]?this._aplNF(summ,i):summ};this._stat_in_header(t,calck,i,c)};dhtmlXGridObject.prototype._in_header_stat_tree_average_leaf=function(t,i,c){var calck=function(){var summ=0;var count=0;this._h2.forEachChild(0,function(el){if (el.childs.length)return;var v=parseFloat(this._get_cell_value((el.buff||this.rowsAr[el.id]),i));summ+=isNaN(v)?0:v;count++},this)
 return this._maskArr[i]?this._aplNF(summ,i):(Math.round(summ/count*100)/100)};this._stat_in_header(t,calck,i,c)};dhtmlXGridObject.prototype._in_header_stat_tree_count=function(t,i,c){var calck=function(){var count=0;this._h2.forEachChild(0,function(el){count++},this)
 return count};this._stat_in_header(t,calck,i,c)};dhtmlXGridObject.prototype._in_header_stat_tree_count_leaf=function(t,i,c){var calck=function(){var count=0;this._h2.forEachChild(0,function(el){if (!el.childs.length)count++},this)
 return count};this._stat_in_header(t,calck,i,c)};dhtmlXGridObject.prototype._stat_in_header=function(t,calck,i,c){var that=this;var f=function(){this.dma(true)
 t.innerHTML=(c[0]?c[0]:"")+calck.call(this)+(c[1]?c[1]:"");this.dma(false)
 this.callEvent("onStatReady",[])
 };if (!this._stat_events){this._stat_events=[];this.attachEvent("onClearAll",function(){if (!this.hdr.rows[1]){for (var i=0;i<this._stat_events.length;i++)for (var j=0;j < 4;j++)this.detachEvent(this._stat_events[i][j]);this._stat_events=[]}})
 };this._stat_events.push([
 this.attachEvent("onGridReconstructed",f),
 this.attachEvent("onXLE",f),
 this.attachEvent("onFilterEnd",f),
 this.attachEvent("onEditCell",function(stage,id,ind){if (stage==2 && ind==i)f.call(this);return true})]);t.innerHTML=""};dhtmlx.skin='dhx_skyblue';