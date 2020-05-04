$(() => {
  $('.js-comment-form').hide();

  $('.js-add-comment').on('click', async evt => {
    evt.preventDefault();

    $(evt.target).parent().find('.js-comment-form').show();
  });

  $('.js-more-comments').on('click', async evt => {
    evt.preventDefault();
    const $tgt = $(evt.target);
    const $anchor = $tgt.is('a') ? $tgt : $tgt.parents('a');
    const postId = $anchor.attr('data-post-id');

    const resp = await fetch(`/comments/post/${postId}`, {
      headers: { 'Accept': 'text/html' }
    });
    const data = await resp.text();
    $tgt.parents('.post--comments').find('.post--comments-container').html(data);
    $anchor.remove();
  });

  $('.comment-form').on('ajax:success', async (evt, data) => {
    const $tgt = $(evt.target);
    if (data.status === 'success') {
      $tgt.parents('.post--comments').find('.post--comments-container').append(data.comment);
      $tgt.find('.js-comment-content').val('');
    }
    else {
      QPixel.createNotification('danger', data.message, evt.target);
    }
  }).on('ajax:error', async (evt, xhr) => {
    const data = xhr.responseJSON;
    QPixel.createNotification('danger', data.message, evt.target);
  });

  $(document).on('click', '.js-comment-edit', async evt => {
    evt.preventDefault();

    const $tgt = $(evt.target);
    const $comment = $tgt.parents('.comment');
    const commentId = $comment.attr('data-id');

    const resp = await fetch(`/comments/${commentId}`, {
      credentials: 'include',
      headers: { 'Accept': 'application/json' }
    });
    const data = await resp.json();
    const content = data.content;

    const formTemplate = `<form action="/comments/${commentId}/edit" method="POST" class="comment-edit-form" data-remote="true">
      <div class="form-group-horizontal">
        <div class="form-group">
          <label for="comment-content">Your comment</label>
          <textarea rows="3" class="form-element is-small" name="comment[content]">${content}</textarea>
        </div>
        <div class="actions">
          <input type="submit" class="button is-outlined" value="Post" />
        </div>
      </div>
    </form>`;

    $comment.html(formTemplate);
  });

  $(document).on('ajax:success', '.comment-edit-form', async (evt, data) => {
    const $tgt = $(evt.target);
    const $comment = $tgt.parents('.comment');

    if (data.status === 'success') {
      const newComment = $(data.comment);
      $comment.html(newComment[0].innerHTML);
    }
    else {
      QPixel.createNotification('danger', data.message, evt.target);
    }
  });

  $(document).on('click', '.js-comment-delete, .js-comment-undelete', async evt => {
    evt.preventDefault();

    const $tgt = $(evt.target);
    const $comment = $tgt.parents('.comment');
    const commentId = $comment.attr('data-id');
    const isDelete = !$comment.hasClass('deleted-content');

    const resp = await fetch(`/comments/${commentId}/delete`, {
      method: isDelete ? 'DELETE' : 'PATCH',
      credentials: 'include',
      headers: { 'X-CSRF-Token': QPixel.csrfToken() }
    });
    const data = await resp.json();

    if (data.status === 'success') {
      if (isDelete) {
        $comment.addClass('deleted-content');
        $tgt.removeClass('js-comment-delete').addClass('js-comment-undelete').text('undelete');
      }
      else {
        $comment.removeClass('deleted-content');
        $tgt.removeClass('js-comment-undelete').addClass('js-comment-delete').text('delete');
      }
    }
    else {
      QPixel.createNotification('danger', data.message, evt.target);
    }
  });
});