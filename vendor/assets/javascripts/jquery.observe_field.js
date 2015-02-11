// jquery.observe_field.js
// |BMC TPS Info    |jquery.observe_fields.js   |TPSDR0034831     |DR4QT.0.6.00     |https://github.com/splendeo/jquery.observe_field  |Registered |

(function( $ ){

  jQuery.fn.observe_field = function(frequency, callback) {

    frequency = frequency * 1000; // translate to milliseconds

    return this.each(function(){
      var $this = $(this);
      var prev = $this.val();

      var check = function() {
        var val = $this.val();
        if(prev != val){
          prev = val;
          $this.map(callback); // invokes the callback on $this
        }
      };

      var reset = function() {
        if(ti){
          clearInterval(ti);
          ti = setInterval(check, frequency);
        }
      };

      check();
      var ti = setInterval(check, frequency); // invoke check periodically

      // reset counter after user interaction
      $this.bind('keyup click mousemove', reset); //mousemove is for selects
    });

  };

})( jQuery );

