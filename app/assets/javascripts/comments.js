$(() => {
  $('.js-comment-form').hide();

  $('.js-add-comment').on('click', async evt => {
    // User clicked `Add a comment`.

    evt.preventDefault();

    const $form = $(evt.target).parent().find('.js-comment-form');
    $form.show();
    $form.find('.js-comment-content').focus();
  });

  const showAllComments = async evt => {
    if (evt.preventDefault) {
      evt.preventDefault();
    }

    const $tgt = $(evt.target);
    const $anchor = $tgt.is('a') ? $tgt : $tgt.parents('a');
    const postId = $anchor.attr('data-post-id');

    const resp = await fetch(`/comments/post/${postId}`, {
      headers: { 'Accept': 'text/html' }
    });
    const data = await resp.text();
    $tgt.parents('.post--comments').find('.post--comments-container').html(data).trigger('ajax:success');
    $tgt.parents('.post--comments').find('.js-more-comments').remove();
  };

  $('.js-more-comments').on('click', showAllComments);

  $('.comment-form').on('ajax:success', async (evt, data) => {
    // Comment posting is succeeded! ^_^

    const $tgt = $(evt.target);
    if (data.status === 'success') {
      await showAllComments({ target: $tgt.parent().find('.js-add-comment') });
      $tgt.find('.js-comment-content').val('');

      // On success, the `Post` button, which has been re-labeled as `Posted`, is not yet re-labeled `Post` when
      // reaching this line. The line below re-labels it back to `Post`.
      $tgt.find('input[type="submit"]').attr('value', 'Post');
      $('.js-comment-form').hide();
    }
    else {
      QPixel.createNotification('danger', data.message);
    }
  }).on('ajax:error', async (evt, xhr) => {
    // Comment posting is errored, e.g. it might be too short to be posted.

    const data = xhr.responseJSON;
    QPixel.createNotification('danger', data.message);

    // On error, the `Post` button, which has been re-labeled as `Posted`, will be re-labeled `Post` back again. There's
    // no need to do anything else at this point in this block, until proven otherwise.
  });

  $('.comment-form').find('input[value="Discard"]').on('click', function(data) {
      const $tgt = $(data.target);
      const $form = $tgt.parents('form');
      $form[0].reset();  // Clear the comment field before hiding the form for a fresh start.
      $form.hide();
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
