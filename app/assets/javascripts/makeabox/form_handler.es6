class FormHandler {
  constructor(formId) {
    this.form = $(`form#${formId}`)[0];
  }

  status(message, period = 4000) {
    $('#action-status').clearQueue().hide().html(message).fadeIn(500).delay(period).fadeOut(1000);
  }

  generatePDF() {
    this.status('PDF is now generating...');
    window.MakeABox.GA('Download PDF');
    $('input[name=commit]')[0].value = "true";
    $(this.form).submit();
    return true;
  }

  save(e, showNotice = true) {
    console.log("form serialized: " + $(this.form).serialize());
    $.cookie("makeabox-settings", $(this.form).serialize(), {expires: 365, path: '/'});
    if (showNotice === true) this.status('Current parameters have been saved');
    return true;
  }

  reset(e) {
    this.form.reset();
    return false;
  }

  restore(e) {
    let settings = $.cookie("makeabox-settings");
    if (settings) {
      this.deserialize(settings);
      this.status('Settings have been restored.');
    } else {
      this.status('No settings were found in your browser cookies, sorry.');
    }
    return true;
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
      this.delay(10000, () => alert.fadeOut(1000));
    }
    return this;
  }

  delay(ms, func) {
    return setTimeout(func, ms);
  }

  presentNotice() {
    let seenNotice = $.cookie("had-seen-the-notice");
    if (!seenNotice) {
      this.delay(200, function() {
        $('#one-time-notice').fadeIn(250);
        return $('#introduction-modal').modal('show').fadeIn("fast");
      });
      this.delay(10000, () => $('#one-time-notice').hide("slow"));
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

window.MakeABox.FormHandler = FormHandler;
