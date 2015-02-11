////////////////////////////////////////////////////////////////////////////////
// BMC Software, Inc.
// Confidential and Proprietary
// Copyright (c) BMC Software, Inc. 2001-2012
// All Rights Reserved.
////////////////////////////////////////////////////////////////////////////////

$( document )
  .on('focusin', ":password", function(){ changeFieldValue($(this), false) })
  .on('focusout', ":password", function(){ changeFieldValue($(this), true) })
  .on('submit', "form", function(){ addBeforeSubmit() })
  .ready( function(){ checkPrivateFields();} )
  .ajaxComplete( function(){ checkPrivateFields();} );


function changeFieldValue(el, encrypted) {
  encrypt = el.attr("value").length > 0;
  if (encrypted & encrypt) {
    el.attr("value", encryptValue(el.attr("value")));
  }
  else {
    el.val(decryptValue(el.attr("value")));
  }
  encryption_field = checkEncryptionFiledExist(el);
  encryption_field.attr("value", encrypted);
}

function encryptValue(value) {
  return CryptoJS.AES.encrypt(value, "Secret key").toString();
}

function decryptValue(value) {
  return CryptoJS.AES.decrypt(value, "Secret key").toString(CryptoJS.enc.Utf8);
}

function checkEncryptionFiledExist(el){
  find_str = "#encrypted\\["+convertValue(el.attr("name"), true)+"\\]";
  encryption_field = $(find_str);
  if (encryption_field.length == 0){
    addEncryptionField(el);
    encryption_field = $(find_str);
  }
  return encryption_field;
}

function convertValue(data, parameter){
  if (parameter == true) {
    data = data.replace(/[[]/g,'\\\|')}
  else{
    data = data.replace(/[[]/g,'|');
  }
  return data.replace(/]/g,'');
}

function addBeforeSubmit(){
  passwords = $(":password");
  $.each(passwords, function(i,pass){
    encryption_field = checkEncryptionFiledExist($(pass));
    if ($.trim(encryption_field.attr("value")) == "false"){
      changeFieldValue($(pass), true);
    }
  });
  return true
}

function addEncryptionField(el) {
  form_elem = el.closest("form");
  current_name = convertValue(el.attr("name"),false);
  $('<input>').attr({
    type: 'hidden',
    id: 'encrypted['+current_name+']',
    name: 'encrypted['+current_name+']',
    value: 'true'
  }).appendTo(form_elem);
}

function checkPrivateFields() {
  passwords = $(":password");
  $.each(passwords, function(i,el) {
    cur_value = $(el).val().length == 44;
    checkEncryptionFiledExist($(el)).attr('value', cur_value);
  });
}