////////////////////////////////////////////////////////////////////////////////
// BMC Software, Inc.
// Confidential and Proprietary
// Copyright (c) BMC Software, Inc. 2001-2012
// All Rights Reserved.
////////////////////////////////////////////////////////////////////////////////

$(function() {  
    $('a.delete').click(function() {
     if (confirm("Are you sure?"))
       $(this).prev('form').submit();

     return false;
   });
});
