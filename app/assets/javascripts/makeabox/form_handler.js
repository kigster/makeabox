class FormHandler {
  constructor(formId) {
    this.form = $(`form#${formId}`)[0];
    this.status = $('#action-status');
  }

  showActionStatus(message, period = 3000) {
    this.status.clearQueue()
      .hide()
      .html(message + '...')
      .fadeIn(500)
      .delay(period)
      .fadeOut(1000);
  }

  restoreUnits() {
    let currentUnits = $('input[name="config[units]"]')[1].checked ? 'mm' : 'in';
    let storedUnits = $.cookie("makeabox-units");
    if (storedUnits) {
      if ((storedUnits === 'mm') && (currentUnits === 'in')) {
        $('input[name="config[units]"]')[0].checked = false;
        $('input[name="config[units]"]')[1].checked = true;
        this.switchUnits('mm');
      }
    }
    return this;
  }

  generatePDF() {
    this.showActionStatus('PDF is now generating...');
    $('input[name=commit]')[0].value = "true";
    return $(this.form).submit();
  }

  switchUnits(units) {
    let currentUnits = $('input[name="config[units]"]')[1].checked ? 'mm' : 'in';
    if (units === currentUnits) {
      return this;
    }

    let conversion = (units === 'in') ? (value) => {
      return parseFloat(value) / 25.4
    } : (value) => {
      return parseFloat(value) * 25.4
    }

    $('input[type="number"]').each(function() {
      let field = $(this);
      if (field.val()) {
        field.val(`${conversion(field.val()).toFixed(3)}`)
      }
    });

    this.showActionStatus(`Units are now set to ${units === 'in' ? "inches" : "millimeters"}.`);
    return this;
  }

  save(showNotice = true) {
    console.log("form serialized: " + $(this.form).serialize());
    $.cookie("makeabox-settings", $(this.form).serialize(), {expires: 365, path: '/'});
    if (showNotice === true) this.showActionStatus('Current parameters have been saved');
    return false;
  }

  reset(e) {
    this.form.reset();
    return false;
  }

  restore(e) {
    let settings = $.cookie("makeabox-settings");
    if (settings) {
      this.deserialize(settings);
      this.showActionStatus('Settings have been restored.');
    }
    return false;
  }

  preventNonNumeric(e) {
    let char_code = e.which || e.key_code;
    let char_str = String.fromCharCode(char_code);

    if (/[a-zA-Z]/.test(char_str)) {
      return false;
    }
  }

  updatePageSettings() {
    let val = $('select#config_page_size option:selected').text();
    if (/Auto/i.test(val)) {
      $('#page-settings').hide();
    }
    else {
      $('#page-settings').show();
    }

    let alert = $('.alert:first');
    if (alert) {
      delay(10000, () => alert.fadeOut(1000));
    }
    return this;
  }

  presentNotice() {
    let seenNotice = $.cookie("had-seen-the-notice");
    if (!seenNotice) {
      delay(200, function() {
        $('#one-time-notice').fadeIn(250);
        return $('#introduction-modal').modal('show').fadeIn("fast");
      });
      delay(10000, () => $('#one-time-notice').hide("slow"));
    }
    return this;
  }

  deserialize(serializedString) {
    var $form = this.form;
    $form.reset();
    serializedString = serializedString.replace(/\+/g, '%20');
    var formFieldArray = serializedString.split("&");
    $.each(formFieldArray, function(i, pair) {
      var nameValue = pair.split("=");
      var name = decodeURIComponent(nameValue[0]);
      var value = decodeURIComponent(nameValue[1]);
      var $field = $('[name="' + name + '"]');

      if ($field[0].type == "radio"
        || $field[0].type == "checkbox") {
        var $fieldWithValue = $field.filter('[value="' + value + '"]');
        var isFound = ($fieldWithValue.length > 0);
        if (!isFound && value == "on") {
          $field.first().prop("checked", true);
        }
        else {
          $fieldWithValue.prop("checked", isFound);
        }
      }
      else {
        $field.val(value);
      }
    });
  }
}

