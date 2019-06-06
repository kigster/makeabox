
$.when($.ready).then(function() {

  // Toggle between AdSense Ad and our own donation
  window.MakeABox.toggle = new window.MakeABox.Toggler(
    [
      '#ad-content-refine',
      '#ad-content-adsense',
      '#ad-content-donate'
    ], [ 5000, 5000, 3000 ]);

  // Initialize the Units Conversion Handler
  window.MakeABox.uh = new window.MakeABox.UnitsHandler('input[name="config[units]"]', '#units');

  if (window.MakeABox.uh.cookieUnits() !== undefined) {
    if (window.MakeABox.uh.fromCookie()) {
      window.MakeABox.uh.status('Welcome back! Form units have been restored from the browser cookie.');
    }
  }

  // Initialize the main Form Handler
  window.MakeABox.fh = new window.MakeABox.FormHandler('pdf-generator');

  let show_thickness_info = () => $('.thickness-info-modal').modal('show');
  let show_advanced_info  = () => $('.advanced-info-modal').modal('show');
  let show_introduction   = () => $('#introduction-modal').modal('show');

  $("#make-pdf").on("click", function(e) {
    window.MakeABox.fh.generatePDF(e);
    return false;
  });

  $('.dont-show-notice').on('click', function(e) {
    $.cookie("had-seen-the-notice", "yes", {expires: 21, path: '/'});
    $('#one-time-notice').fadeOut("slow");
    return $('.modal').fadeOut("slow");
  });

  $('.numeric').on("keypress", e => window.MakeABox.fh.preventNonNumeric(e));

  $('#config_page_size').on('change', e => window.MakeABox.fh.updatePageSettings());

  // Drop Down Options
  $('#clear').on("click", e => window.MakeABox.fh.reset(this));
  $('#save').on("click", e => window.MakeABox.fh.save(this, true));
  $('#save-units').on("click", e => window.MakeABox.uh.toCookie(this));
  $('#restore').on("click", e => window.MakeABox.fh.restore(this));
  $('#download').on("click", e => {
    window.MakeABox.fh.save(this, false);
    window.MakeABox.fh.generatePDF(e);
    return true;
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
