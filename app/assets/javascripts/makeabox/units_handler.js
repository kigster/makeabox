class UnitsHandler {
  constructor(radioButtons, hiddenField) {
    this.klass = radioButtons;
    this.hidden = hiddenField;

    this.mapping = {'in': 0, 'mm': 1};

    this.conversions = {
      'in'   : (value) => {
        return parseFloat(value) / 25.4
      }, 'mm': (value) => {
        return parseFloat(value) * 25.4
      }
    };

    this.radios = $(radioButtons);

    const myself = this;

    $(myself.radios).on('change', function() {
      myself.setUnitsTo($(this).val());
      return true;
    })
  }

  setUnitsTo(targetUnits) {
    let newUnits = targetUnits;
    this.selectRadioButton(newUnits);
    let conversion = this.conversions[ newUnits ];

    $('input[type="number"]').each(function() {
      let field = $(this);
      if (field.val()) {
        field.val(`${conversion(field.val()).toFixed(3)}`)
      }
    });

    return this;
  }

  currentUnits() {
    return $(`${this.klass}:checked`).val();
  }

  cookieUnits() {
    return $.cookie("makeabox-units");
  }

  restoreUnits() {
    let _current = this.currentUnits();
    let _stored  = this.cookieUnits();
    if (_stored &&
        this.mapping[ _stored ] !== undefined &&
        _stored !== _current) {
      this.setUnitsTo(_stored);
    }
    return this;
  }

  selectRadioButton(units) {
    let selectedIndex = this.mapping[units];
    $(this.radios[selectedIndex]).prop('checked', true);
    $(this.hidden).val(units);
    return false;
  }

}

MakeABox.UnitsHandler = UnitsHandler;


