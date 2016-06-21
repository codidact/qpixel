# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$(document).on('ready page:load', () ->

  $('a[data-remote].close-question').on('ajax:success', (ev, data, status, xhr) ->
    $('div.comments-container').before('<div class="alert alert-warning"><h4><strong>Question Closed</strong></h4><p>This
      question was closed by <strong>' + data['closed_by'] + '</strong>. New answers cannot be added.</p></div>')
    QPixel.createNotification('success', 'This question has been closed.', $(this))
  ).on('ajax:error', (ev, xhr, status, error) ->
    QPixel.createNotification('danger', '<strong>Failed:</strong> ' + JSON.parse(xhr.responseText)['message'], $(this))
  )

)
