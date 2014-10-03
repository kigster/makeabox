# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

jQuery ->
  $("input[name='config[units]'").on "click", (e) ->
    f = $(e.target).closest("form")
    f.submit()

  $('.numeric').on "keypress", (e)->
    char_code = e.which || e.key_code
    char_str = String.fromCharCode(char_code);
    if /[a-zA-Z]/.test(char_str)
      return false

  $('#clear').on "click", (e) ->
    $('form').clear();

  $('#save').on "click", (e) ->
    $.cookie("makeabox-settings", $('form').serialize());

  $('#restore').on "click", (e) ->
    settings = $.cookie("makeabox-settings");
    if settings
      $('form').deserialize(settings);


