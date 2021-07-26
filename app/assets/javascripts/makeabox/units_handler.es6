class UnitsHandler {
  constructor(radioButtons, hiddenField) {
    this.klass = radioButtons;
    this.hidden = hiddenField;
    this.cookieName = "makeabox-units";
    this.mapping = {'in': 0, 'mm': 1};

    this.conversions = {
      'in': (value) => {
        return Number((parseFloat(value) / 25.4).toFixed(6));
      }, 'mm': (value) => {
        return Number((parseFloat(value) * 25.4).toFixed(6));
      }
    };

    this.radios = $(radioButtons);

    const myself = this;

    $(this.radios).on('change', function() {
      myself.setUnitsTo($(this).val());
      myself.status(`Units have been changed to "${myself.currentUnits()}".`);
      return true;
    })
  }

  status(message, period = 4000) {
    $('#action-status').clearQueue().hide().html(message).fadeIn(500).delay(period).fadeOut(1000);
  }

  setUnitsTo(targetUnits) {
    let newUnits = targetUnits;
    this.selectRadioButton(newUnits);
    let conversion = this.conversions[newUnits];

    $('input[type="number"]').each(function() {
      let field = $(this);
      if (field.val()) {
        field.val(`${conversion(field.val())}`)
      }
    });

    return this;
  }

  currentUnits() {
    return $(`${this.klass}:checked`).val();
  }

  cookieUnits() {
    return $.cookie(this.cookieName);
  }

  fromCookie() {
    let _current = this.currentUnits();
    let _stored = this.cookieUnits();
    if (_stored &&
      this.mapping[_stored] !== undefined &&
      _stored !== _current) {
      this.setUnitsTo(_stored);
      return true;
    }
    return false;
  }

  toCookie() {
    let u = this.currentUnits();
    $.cookie(this.cookieName, u, {expires: 365, path: '/'});
    this.status("Saved the current units in your browser's cookie.");
    return this;
  }

  selectRadioButton(units) {
    let selectedIndex = this.mapping[units];
    $(this.radios[selectedIndex]).prop('checked', true);
    $(this.hidden).val(units);
    return false;
  }

}

window.Makeabox.UnitsHandler = UnitsHandler;


