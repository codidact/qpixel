$(() => {
  $('.js-more-comments').on('click', async evt => {
    evt.preventDefault();
    const $tgt = $(evt.target);
    const $anchor = $tgt.is('a') ? $tgt : $tgt.parents('a');
    const postId = $anchor.attr('data-post-id');

    const resp = await fetch(`/comments/post/${postId}`, {
      headers: { 'Accept': 'text/html' }
    });
    const data = await resp.text();
    $tgt.parents('.post--comments').find('.post--comments-container').html(data).trigger('ajax:success');
    $anchor.remove();
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
      <label for="comment-content" class="form-element">Comment body:</label>
      <textarea id="comment-content" rows="3" class="form-element is-small" name="comment[content]">${content}</textarea>
      <input type="submit" class="button is-muted is-filled" value="Update comment" />
    </form>`;

    $comment.find(".comment--body").html(formTemplate);
  });

  $(document).on('ajax:success', '.comment-edit-form', async (evt, data) => {
    const $tgt = $(evt.target);
    const $comment = $tgt.parents('.comment');

    if (data.status === 'success') {
      const newComment = $(data.comment);
      $comment.html(newComment[0].innerHTML);
    }
    else {
      QPixel.createNotification('danger', data.message);
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
      QPixel.createNotification('danger', data.message);
    }
  });

  $(document).on('click', '.comment-form input[type="submit"]', async evt => {
      // Comment posting has been clicked.
      $(evt.target).attr('data-disable-with', 'Posting...');
  });
});
