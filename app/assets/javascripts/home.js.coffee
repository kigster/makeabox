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

  prevent_non_numeric: (e) ->
    char_code = e.which || e.key_code
    char_str = String.fromCharCode(char_code);
    if /[a-zA-Z]/.test(char_str)
      return false

jQuery ->
  $("input[name='config[units]'").on "click", (e) ->
    f = $(e.target).closest("form")
    f.submit()

  $(document).on 'ready', (e) ->
    window.handler = new MakeABox.FormHandler('pdf-generator')

  $('.numeric').on "keypress", (e)->
    return handler.prevent_non_numeric(e)

  $('#clear').on "click", (e) ->
    handler.clear()

  $('#clear-box').on "click", (e) ->
    handler.clear('.box-dimensions')

  $('#save').on "click", (e) ->
    handler.save()

  $('#restore').on "click", (e) ->
    handler.restore()

  $('#opener').on 'click', (e) ->
     panel = $('#slide-panel')
     if panel.hasClass("hidden")
         panel.removeClass('hidden')
     else
         panel.addClass('hidden')
     return false;
