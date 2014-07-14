// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
// WARNING: THE FIRST BLANK LINE MARKS THE END OF WHAT'S TO BE PROCESSED, ANY BLANK LINE SHOULD
// GO AFTER THE REQUIRES BELOW.
//
//= require jquery
//= require jquery_ujs
//= require_tree .
    cat = 'pills';

    function catSwitch(){
      var label = cat
      cat = cat == 'pills' ? 'tins' : 'pills'
      document.getElementById("cat").innerHTML = "Show " + label;
    }

    function loadValues(){
      
      catSwitch();
      var arr = document.getElementsByClassName("drug_value");

      for (var i = 0; i < arr.length; i ++){
        try{
          if (cat == "pills")
            arr[i].innerHTML = Math.round(arr[i].getAttribute("pills")).toFixed(0).replace(/./g, function(c, i, a) {
              return i && c !== "." && !((a.length - i) % 3) ? ',' + c : c;
            });
          else if (cat == "tins"){
            arr[i].innerHTML = (Math.round((arr[i].innerHTML.replace(/,/g, "")) / 60)).toFixed(0).replace(/./g, function(c, i, a) {
              return i && c !== "." && !((a.length - i) % 3) ? ',' + c : c;
            });
          }
        }catch(e){}
      }
    }


