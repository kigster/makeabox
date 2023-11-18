$.when($.ready).then(function () {

  window.hideAlert = function() {
    $('#alert-row').fadeOut("slow");
  };

  setTimeout(hideAlert, 5000);

  // Initialize the Units Conversion Handler
  window.Makeabox.uh = new window.Makeabox.UnitsHandler('input[name="config[units]"]', '#units');

  if (window.Makeabox.uh.cookieUnits() !== undefined) {
    if (window.Makeabox.uh.fromCookie()) {
      window.Makeabox.uh.status('Welcome back! Form units have been restored from the browser cookie.');
    }
  }

  // Initialize the main Form Handler
  window.Makeabox.fh = new window.Makeabox.FormHandler('pdf-generator');

  let show_thickness_info = () => $('.thickness-info-modal').modal('show');
  let show_advanced_info = () => $('.advanced-info-modal').modal('show');
  let show_introduction = () => $('#introduction-modal').modal('show');

  $("#make-pdf").on("click", function (e) {
    window.Makeabox.fh.generatePDF(e);
    return false;
  });

  $('.dont-show-notice').on('click', function (e) {
    $.cookie("had-seen-the-notice", "yes", {expires: 21, path: '/'});
    $('#one-time-notice').fadeOut("slow");
    return $('.modal').fadeOut("slow");
  });

  $('.numeric').on("keypress", e => window.Makeabox.fh.preventNonNumeric(e));

  $('#config_page_size').on('change', e => window.Makeabox.fh.updatePageSettings());

  // Drop Down Options
  $('#clear').on("click", e => window.Makeabox.fh.reset(this));
  $('#save').on("click", e => window.Makeabox.fh.save(this, true));
  $('#save-units').on("click", e => window.Makeabox.uh.toCookie(this));
  $('#restore').on("click", e => window.Makeabox.fh.restore(this));
  $('#download').on("click", e => {
    window.Makeabox.fh.save(this, false);
    window.Makeabox.fh.generatePDF(e);
    return true;
  });

  $('.logo-image, .logo-name').on('click', function (e) {
    document.location = '/';
    return false;
  });

  $('#thickness-info').on('click', function (e) {
    show_thickness_info();
    return false;
  });

  $('#introduction').on('click', function (e) {
    show_introduction();
    return false;
  });

  $('.advanced-info').on('click', function (e) {
    show_advanced_info();
    return false;
  });

  $('.notch-help').on('click', function (e) {
    show_advanced_info();
    return false;
  });

  window.captureOutboundLink = function (url) {
    ga('send', 'event', 'outbound', 'click', url, {
      'transport': 'beacon',
      'hitCallback': function () {
        window.open(url, '_blank');
      }
    })
  };

  $('.refine-link').on('click', function (e) {
    var link = $( this );
    window.captureOutboundLink(link.attr("href"));
    return true;
  })

});
