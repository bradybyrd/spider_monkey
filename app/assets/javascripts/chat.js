////////////////////////////////////////////////////////////////////////////////
// BMC Software, Inc.
// Confidential and Proprietary
// Copyright (c) BMC Software, Inc. 2001-2012
// All Rights Reserved.
////////////////////////////////////////////////////////////////////////////////

function scroll_chat(chat_div, chat_input)
{
    var objDiv = document.getElementById(chat_div);
    objDiv.scrollTop = objDiv.scrollHeight;
}


function scroll_and_clear_chat(chat_div, chat_input)
{
    scroll_chat(chat_div, chat_input);
    document.getElementById(chat_input).value = "";
}
