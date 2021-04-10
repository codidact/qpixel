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
    $tgt.parents('.post--comments').find('.js-more-comments').remove();
  });

  $('.js-more-comments').on('click', showAllComments);

  $(document).on('click', '.js-comment-edit', async evt => {
    evt.preventDefault();

    const $tgt = $(evt.target);
    const $comment = $tgt.parents('.comment');
    const commentId = $comment.attr('data-id');
    const originalComment= $comment.find('p.comment--content').clone();

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
      <input type="button" name="js-discard-edit" data-comment-id="${commentId}" value="Discard Edit" class="button is-danger is-outlined js-discard-edit" />
    </form>`;

    $comment.find(".comment--body").html(formTemplate);

    $(`.js-discard-edit[data-comment-id="${commentId}"]`).click(() => {
      $comment.html(originalComment);
    });
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

  $(document).on('click', '.js--restrict-thread, .js--unrestrict-thread', async evt => {
    evt.preventDefault();

    const $tgt = $(evt.target);
    const threadID = $tgt.data("thread")
    const action = $tgt.data("action")
    const route = $tgt.hasClass("js--restrict-thread") ? 'restrict' : 'unrestrict';

    const resp = await fetch(`/comments/thread/${threadID}/${route}`, {
      method: 'POST',
      credentials: 'include',
      headers: { 'X-CSRF-Token': QPixel.csrfToken(), 'Content-Type': 'application/x-www-form-urlencoded; charset=utf-8' },
      body: 'type=' + action
    });
    const data = await resp.json();

    if (data.status === 'success') {
      window.location.reload();
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
