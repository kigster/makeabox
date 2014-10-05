# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/
class MakeABox.FormHandler
  constructor:(formId) ->
    @form = $('form#' + formId)

  restore: ->
    settings = $.cookie("makeabox-settings");
    if settings
      @form.deserialize(settings);

  save: ->
    $.cookie("makeabox-settings", @form.serialize(),  { expires: 365, path: '/' });

  clear:(extraClass) ->
    @form.clear(extraClass)

  preventNonNumeric: (e) ->
    char_code = e.which || e.key_code
    char_str = String.fromCharCode(char_code);
    if /[a-zA-Z]/.test(char_str)
      return false

  updatePageSettings: ->
    val = $('select#config_page_size option:selected' ).text();
    if /Auto/i.test(val)
      $('#page-settings').hide()
    else
      $('#page-settings').show()

jQuery ->
  $("input[name='config[units]'").on "click", (e) ->
    f = $(e.target).closest("form")
    f.submit()

  $(document).on 'ready', (e) ->
    window.handler = new MakeABox.FormHandler('pdf-generator')
    handler.updatePageSettings()

  $('.numeric').on "keypress", (e)->
    return handler.preventNonNumeric(e)

  $('#config_page_size').on 'change', (e) ->
    handler.updatePageSettings()

  $('#help').on 'click', (e) ->
    $('#introduction').fadeIn("fast")
    $('#introduction').removeClass("hidden")

  $('#opener').on 'click', (e) ->
     $('#introduction').fadeOut("fast")

  $('#clear').on "click", (e) ->
    handler.clear('.box-dimensions')

  $('#clear-box').on "click", (e) ->
    handler.clear('.box-dimensions')

  $('#save').on "click", (e) ->
    handler.save()

  $('#restore').on "click", (e) ->
    handler.restore()

