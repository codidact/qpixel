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

  $(document).on('click', '.post--comments-thread.is-inline a', async evt => {
    if (evt.ctrlKey) { return; }

    evt.preventDefault();
    const $tgt = $(evt.target);

    const resp = await fetch($tgt.attr("href") + '?inline=true', {
      headers: { 'Accept': 'text/html' }
    });
    let data = await resp.text();

    data = data.split("<!-- THREAD STARTS BELOW -->")[1];
    data = data.split("<!-- THREAD ENDS ABOVE -->")[0];

    $tgt.parent()[0].outerHTML = data;
    window.MathJax && MathJax.typeset();
  });

  $(document).on('click', '.js-collapse-thread', async ev => {
    const $tgt = $(ev.target);
    const $widget = $tgt.parents('.widget');
    const $embed = $tgt.parents('.post--comments-thread');

    const threadId = $widget.data('thread');
    const isDeleted = $widget.data('deleted');
    const isArchived = $widget.data('archived');
    const threadTitle = $widget.find('.js-thread-title').text();
    const replyCount = $widget.data('comments');

    const $container = $(`<div class="post--comments-thread is-inline"></div>`);
    const $link = $(`<a href="/comments/thread/${threadId}" class="js--comment-link" data-thread=${threadId}></a>`);
    $link.text(threadTitle);

    if (isDeleted) {
      $container.append(`<i class="fas fa-trash h-c-red-600 fa-fw" title="Deleted thread" aria-label="Deleted thread"></i>`);
      $container.addClass('is-deleted');
    }
    if (isArchived) {
      $container.append(`<i class="fas fa-archive fa-fw" title="Archived thread" aria-label="Archived thread"></i>`);
      $container.addClass('is-archived');
    }
    $container.append($link);
    $container.append(`(${replyCount} comment${replyCount !== 1 ? 's' : ''})`);
    $embed[0].outerHTML = $container[0].outerHTML;
  });

  $(document).on('click', '.js-comment-edit', async evt => {
    evt.preventDefault();

    const $tgt = $(evt.target);
    const $comment = $tgt.parents('.comment');
    const $commentBody = $comment.find('.comment--body');
    const commentId = $comment.attr('data-id');
    const originalComment = $commentBody.clone();

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

    $commentBody.html(formTemplate);

    $(`.js-discard-edit[data-comment-id="${commentId}"]`).click(() => {
      $commentBody.html(originalComment.html());
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

  $(document).on('click', '.js--show-followers', async evt => {
    evt.preventDefault();

    const $tgt = $(evt.target);
    const threadId = $tgt.data('thread');
    const $modal = $($tgt.data('modal'));

    const resp = await fetch(`/comments/thread/${threadId}/followers`, {
      method: 'GET',
      credentials: 'include',
      headers: { 'Accept': 'text/html' }
    });
    const data = await resp.text();
    $modal.find('.js-follower-display').html(data);
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
      headers: { 'X-CSRF-Token': QPixel.csrfToken(), 'Content-Type': 'application/json' },
      body: JSON.stringify({ type: action })
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

  const currentCaretSequence = (splat, posIdx) => {
    let searchIdx = 0;
    let splatIdx = 0;
    let posInSeq;
    let currentSequence;
    do {
      currentSequence = splat[splatIdx];
      posInSeq = posIdx - (splatIdx === 0 ? searchIdx : searchIdx + 1);
      searchIdx += currentSequence.length + (splatIdx === 0 ? 0 : 1);
      splatIdx += 1;
    } while (searchIdx < posIdx);
    return [currentSequence, posInSeq];
  };

  const pingable = {};
  $(document).on('keyup', '.js-comment-field', async ev => {
    if (ev.keyCode === 27) { return; }

    const $tgt = $(ev.target);
    const content = $tgt.val();
    const splat = content.split(' ');
    const caretPos = $tgt[0].selectionStart;
    const [currentWord, posInWord] = currentCaretSequence(splat, caretPos);

    const itemTemplate = $('<a href="javascript:void(0)" class="item"></a>');
    const callback = ev => {
      const $item = $(ev.target).hasClass('item') ? $(ev.target) : $(ev.target).parents('.item');
      const id = $item.data('user-id');
      $tgt[0].selectionStart = caretPos - posInWord;
      $tgt[0].selectionEnd = (caretPos - posInWord) + currentWord.length;
      QPixel.replaceSelection($tgt, `@#${id}`);
      $('.ta-popup').remove();
      $tgt.focus();
    };

    // If the word the caret is currently in starts with an @, and has at least 3 characters after that, assume it's
    // an attempt to ping another user with a username, and kick off suggestions -- unless it starts with @#, in which
    // case it's likely an already-selected ping.
    if (currentWord.startsWith('@') && !currentWord.startsWith('@#') && currentWord.length >= 4) {
      QPixel.removeTextareaPopups();
      const threadId = $tgt.data('thread');
      const postId = $tgt.data('post');

      if (!pingable[`${threadId}-${postId}`] || Object.keys(pingable[`${threadId}-${postId}`]).length === 0) {
        const resp = await fetch(`/comments/thread/${threadId}/pingable?post=${postId}`);
        pingable[`${threadId}-${postId}`] = await resp.json();
      }

      const items = Object.entries(pingable[`${threadId}-${postId}`]).filter(e => {
        return e[0].toLowerCase().startsWith(currentWord.substr(1).toLowerCase());
      }).map(e => {
        const username = e[0].replace(/</g, '&#x3C;').replace(/>/g, '&#x3E;');
        const id = e[1];
        return itemTemplate.clone().html(`${username} <span class="has-color-tertiary-600">#${id}</span>`)
                           .attr('data-user-id', id);
      });
      QPixel.createTextareaPopup(items, $tgt[0], callback);
    }
    else {
      QPixel.removeTextareaPopups();
    }
  });
});
