if (typeof MakeABox === 'undefined') { window.MakeABox = {}; }

let delay = (ms, func) => setTimeout(func, ms);

MakeABox.GA = function(label) {
  if (typeof(ga) !== 'undefined' && ga !== null) {
    return ga('send', {
                hitType      : 'event',
                eventCategory: 'PDF',
                eventAction  : 'download',
                eventLabel   : label
              }
    );
  }
};


class Toggle {
  constructor(array_of_divs, array_of_durations) {
    this.divs      = array_of_divs;
    this.durations = array_of_durations;
    this.effectDuration = 1500;
  }

  toggle(index) {
    //console.log(`entering toggle, index is ${index}, this.divs are ${this.divs}`);

    let previousDiv = $(this.divs[ index ]);
    //console.log(`previous div[${index}] is ${previousDiv.attr('id')}`);

    var nextIndex = this.nextIndex(index);

    var currentDiv = $(this.divs[ nextIndex ]);
    //console.log(`current div[${nextIndex}] is ${currentDiv.attr('id')}`);

    var adToggle = this;

    previousDiv.fadeOut(adToggle.effectDuration, function() {
      currentDiv.fadeIn(adToggle.effectDuration);
    });

    delay(adToggle.effectDuration + this.durations[nextIndex], function() {
      window.MakeABox.AdToggle.toggle(nextIndex);
    });

    return true;
  }

  nextIndex(index) {
    index++;
    return index % this.divs.length;
    ;
  }
}

window.MakeABox.AdToggle = new Toggle([ '#adsense-row', '#donate-row' ], [ 9000, 5000 ]);

$.when($.ready).then(function() {

  $('#donate-row').hide();

  delay(10, function() { window.MakeABox.AdToggle.toggle(1) });

  let show_thickness_info = () => $('.thickness-info-modal').modal('show');
  let show_advanced_info  = () => $('.advanced-info-modal').modal('show');
  let show_introduction   = () => $('#introduction-modal').modal('show');

  window.MakeABox.handler = new FormHandler('pdf-generator');
  const Handler           = window.MakeABox.handler;

  Handler.restoreUnits().presentNotice();

  $("#config_units_in").on("click", function(e) {
    $.cookie("makeabox-units", 'in', {expires: 365, path: '/'});
    Handler.switchUnits('in');
  });

  $("#config_units_mm").on("click", function(e) {
    $.cookie("makeabox-units", 'mm', {expires: 365, path: '/'});
    Handler.switchUnits('mm');
  });

  $("#make-pdf").on("click", function(e) {
    window.MakeABox.GA('Download PDF');
    Handler.generatePDF(e);
    return false;
  });

  $('.dont-show-notice').on('click', function(e) {
    $.cookie("had-seen-the-notice", "yes", {expires: 21, path: '/'});
    $('#one-time-notice').fadeOut("slow");
    return $('.modal').fadeOut("slow");
  });

  $('.numeric').on("keypress", e => Handler.preventNonNumeric(e));

  $('#config_page_size').on('change', e => Handler.updatePageSettings());

  // Drop Down Options
  $('#clear').on("click", e => Handler.reset(e));
  $('#save').on("click", e => Handler.save(true));
  $('#restore').on("click", e => Handler.restore(e));
  $('#download').on("click", e => {
    Handler.save(false);
    return Handler.generatePDF(e);
  });


  $('.logo-image, .logo-name').on('click', function(e) {
    document.location = '/';
    return false;
  });

  $('#thickness-info').on('click', function(e) {
    show_thickness_info();
    return false;
  });

  $('#introduction').on('click', function(e) {
    show_introduction();
    return false;
  });

  $('.advanced-info').on('click', function(e) {
    show_advanced_info();
    return false;
  });

  $('.notch-help').on('click', function(e) {
    show_advanced_info();
    return false;
  });

});
