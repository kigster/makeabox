$.when($.ready).then(function() {

  $('#donate-row').hide();

  // Toggle between AdSense Ad and our own donation
  window.MakeABox.toggle = new MakeABox.Toggler([ '#adsense-row', '#donate-row' ], [ 9000, 5000 ]);

  // Initialize the Units Conversion Handler
  window.MakeABox.uh = new MakeABox.UnitsHandler('input[name="config[units]"]', '#units');

  // Initialize the main Form Handler
  window.MakeABox.fh = new MakeABox.FormHandler('pdf-generator');

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
  $('#clear').on("click", e => window.MakeABox.fh.reset(e));
  $('#save').on("click", e => window.MakeABox.fh.save(true));
  $('#restore').on("click", e => window.MakeABox.fh.restore(e));
  $('#download').on("click", e => {
    window.MakeABox.fh.save(false);
    return window.MakeABox.fh.generatePDF(e);
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
