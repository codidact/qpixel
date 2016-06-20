# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$(document).on('ready page:load', () ->

  $('div.danger-zone').hide()

  $('a.show-danger-zone').on('click', (ev) ->
    $(this).remove()
    $('div.danger-zone').slideDown(200)
  )

  $('a[data-remote].destroy-user').on('ajax:success', (ev, data, status, xhr) ->
    $('div.delete-actions').after('<p class="text-success">User was successfully removed.</p> <a href="/users">Return to user index.</a>')
    $('div.delete-actions').remove()
  ).on('ajax:error', (ev, xhr, status, error) ->
    $(this).after('<p class="text-danger"><strong>Failed:</strong> ' + JSON.parse(xhr.responseText)['message'] + '</p>')
  )

  $('a[data-remote].soft-delete').on('ajax:success', (ev, data, status, xhr) ->
    $('div.delete-actions').after('<p class="text-success">User was successfully removed.</p> <a href="/users">Return to user index.</a>')
    $('div.delete-actions').remove()
  ).on('ajax:error', (rv, xhr, status, error) ->
    $(this).after('<p class="text-danger"><strong>Failed:</strong> ' + JSON.parse(xhr.responseText)['message'] + '</p>')
  )

)
