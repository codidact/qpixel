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
    openThread($tgt.closest('.post--comments-thread-wrapper')[0], $tgt.attr("href"));
  });

  async function openThread(wrapper, targetUrl, showDeleted = false) {
    const resp = await fetch(`${targetUrl}?inline=true&show_deleted_comments=${showDeleted ? 1 : 0}`, {
      headers: { 'Accept': 'text/html' }
    });
    let data = await resp.text();

    data = data.split("<!-- THREAD STARTS BELOW -->")[1];
    data = data.split("<!-- THREAD ENDS ABOVE -->")[0];

    wrapper.innerHTML = data;

    $('a.show-deleted-comments').click(async evt => {
      if (evt.ctrlKey) { return; }
      evt.preventDefault();
      openThread(wrapper, targetUrl, true);
    });

    window.MathJax && MathJax.typeset();
    window.hljs && hljs.highlightAll();
  }

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
      <textarea id="comment-content" rows="6" class="form-element is-small" data-character-count=".js-character-count-comment-body" name="comment[content]">${content}</textarea>
      <input type="submit" class="button is-muted is-filled" value="Update comment" />
      <input type="button" name="js-discard-edit" data-comment-id="${commentId}" value="Discard Edit" class="button is-danger is-outlined js-discard-edit" />
      <span class="has-float-right has-font-size-caption js-character-count-comment-body"
            data-max="1000" data-min="15">
        <i class="fas fa-ellipsis-h js-character-count__icon"></i>
        <span class="js-character-count__count">${content.length} / 1000</span>
      </span>
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

  const pingable = {};
  $(document).on('keyup', '.js-comment-field', async ev => {
    if (QPixel.Popup.isSpecialKey(ev.keyCode)) {
      return;
    }

    const $tgt = $(ev.target);
    const content = $tgt.val();
    const splat = content.split(' ');
    const caretPos = $tgt[0].selectionStart;
    const [currentWord, posInWord] = QPixel.currentCaretSequence(splat, caretPos);

    const itemTemplate = $('<a href="javascript:void(0)" class="item"></a>');
    const callback = (ev, popup) => {
      const $item = $(ev.target).hasClass('item') ? $(ev.target) : $(ev.target).parents('.item');
      const id = $item.data('user-id');
      $tgt[0].selectionStart = caretPos - posInWord;
      $tgt[0].selectionEnd = (caretPos - posInWord) + currentWord.length;
      QPixel.replaceSelection($tgt, `@#${id}`);
      popup.destroy();
      $tgt.focus();
    };

    // If the word the caret is currently in starts with an @, and has at least 3 characters after that, assume it's
    // an attempt to ping another user with a username, and kick off suggestions -- unless it starts with @#, in which
    // case it's likely an already-selected ping.
    if (currentWord.startsWith('@') && !currentWord.startsWith('@#') && currentWord.length >= 4) {
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
      QPixel.Popup.getPopup(items, $tgt[0], callback);
    }
    else {
      QPixel.Popup.destroyAll();
    }
  });

  $('.js-new-thread-link').on('click', async ev => {
    ev.preventDefault();
    const $tgt = $(ev.target);
    const postId = $tgt.attr('data-post');
    const $thread = $(`#new-thread-modal-${postId}`);

    if ($thread.is(':hidden')) {
      $thread.show();
    }
    else {
      $thread.hide();
    }
  });

  $('.js-comment-permalink > .js-text').text('copy link');
  $(document).on('click', '.js-comment-permalink', ev => {
    ev.preventDefault();

    const $tgt = $(ev.target).is('a') ? $(ev.target) : $(ev.target).parents('a');
    const link = $tgt.attr('href');
    navigator.clipboard.writeText(link);
    $tgt.find('.js-text').text('copied!');
    setTimeout(() => {
      $tgt.find('.js-text').text('copy link');
    }, 1000);
  });
});
