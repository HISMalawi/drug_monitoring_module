function getBrowserHeight() {
    var intH = 0;
    var intW = 0;

    if(typeof window.innerWidth  == 'number' ) {
        intH = window.outerHeight
        intW = window.outerWidth;
    }
    else if(document.documentElement && (document.documentElement.clientWidth || document.documentElement.clientHeight)) {
        intH = document.documentElement.clientHeight;
        intW = document.documentElement.clientWidth;
    }
    else if(document.body && (document.body.clientWidth || document.body.clientHeight)) {
        intH = document.body.clientHeight;
        intW = document.body.clientWidth;
    }

    return { width: parseInt(intW), height: parseInt(intH) };
}

function setLayerPosition() {
  var shadow = document.getElementById("shadow");
  var question = document.getElementById("question");

  var bws = getBrowserHeight();
  shadow.style.width = '100%';
  shadow.style.height = '100%';

  question.style.width = '50%';
  question.style.height = '50%';

  shadow = null;
  question = null;
}

function showLayer() {
  setLayerPosition();

  var shadow = document.getElementById("shadow");
  var question = document.getElementById("question");

  shadow.style.display = "block"; 
  question.style.display = "block";

  shadow = null;
  question = null;
}

function hideLayer() {
  var shadow = document.getElementById("shadow");
  var question = document.getElementById("question");

  shadow.style.display = "none"; 
  question.style.display = "none";

  shadow = null;
  question = null; 
}

window.onresize = setLayerPosition;
