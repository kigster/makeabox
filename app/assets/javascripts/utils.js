
$.fn.clear = function (className) {
    var context = className ? $(this).find(className + " input") : $(this).find('input');
    context
        .filter(':text, :password, :file').val('')
        .end()
        .filter('.numeric').val('')
        .end()
        .find('textarea').val('')
        .end()
        .find('select').prop("selectedIndex", -1)
        .find('option:selected').removeAttr('selected')
    ;
    return this;
};

$.fn.deserialize = function (serializedString) {
    var $form = $(this);
    $form[0].reset();
    serializedString = serializedString.replace(/\+/g, '%20');
    var formFieldArray = serializedString.split("&");
    $.each(formFieldArray, function (i, pair) {
        var nameValue = pair.split("=");
        var name = decodeURIComponent(nameValue[0]);
        var value = decodeURIComponent(nameValue[1]);
        var $field = $form.find('[name="' + name + '"]');

        if ($field[0].type == "radio"
            || $field[0].type == "checkbox") {
            var $fieldWithValue = $field.filter('[value="' + value + '"]');
            var isFound = ($fieldWithValue.length > 0);
            if (!isFound && value == "on") {
                $field.first().prop("checked", true);
            } else {
                $fieldWithValue.prop("checked", isFound);
            }
        } else {
            $field.val(value);
        }
    });
}



