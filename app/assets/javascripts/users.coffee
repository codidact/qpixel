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
    QPixel.createNotification('success', '<p>User was successfully removed. <a href="/users">Return to user index.</a></p>', $(this))
    $('div.delete-actions').remove()
  ).on('ajax:error', (ev, xhr, status, error) ->
    QPixel.createNotification('danger', '<p><strong>Failed:</strong> ' + JSON.parse(xhr.responseText)['message'] + '</p>', $(this))
  )

  $('a[data-remote].soft-delete').on('ajax:success', (ev, data, status, xhr) ->
    QPixel.createNotification('success', '<p><strong>Complete.</strong> ' + JSON.parse(data)['message'] + ' <a href="/users">Return to user index.</a></p>', $(this))
    $('div.delete-actions').remove()
  ).on('ajax:error', (rv, xhr, status, error) ->
    QPixel.createNotification('danger', '<p><strong>Failed:</strong> ' + JSON.parse(xhr.responseText)['message'] + '</p>', $(this))
  )

)
