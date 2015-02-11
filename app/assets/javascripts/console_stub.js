// Hack for IE to make JS work if console was not initialized. IE is just so IE...
if (typeof console === "undefined" || typeof console.log === "undefined") {
    console = {};
    console.log = function() {};
}