$(() => {
  $(document).on('click', '.js-more-comments', async (evt) => {
    evt.preventDefault();
    const $tgt = $(evt.target);
    const $anchor = $tgt.is('a') ? $tgt : $tgt.parents('a');
    const postId = $anchor.attr('data-post-id');

    const data = await QPixel.getThreadsListContent(postId);

    $tgt.parents('.post--comments').find('.post--comments-container').html(data).trigger('ajax:success');
    $tgt.parents('.post--comments').find('.js-more-comments').remove();
  });

  $(document).on('click', '.post--comments-thread.is-inline a', async (evt) => {
    if (evt.ctrlKey) { return; }

    evt.preventDefault();

    const $tgt = $(evt.target);
    const $threadId = $tgt.data('thread');

    openThread($tgt.closest('.post--comments-thread-wrapper')[0], $threadId);
  });

  /**
   * @param {HTMLElement} wrapper
   * @param {string} threadId
   * @param {boolean} [showDeleted]
   */
  async function openThread(wrapper, threadId, showDeleted = false) {
    const data = await QPixel.getThreadContent(threadId, { showDeleted });

    wrapper.innerHTML = data;

    $('a.show-deleted-comments').click(async (evt) => {
      if (evt.ctrlKey) { return; }
      evt.preventDefault();
      openThread(wrapper, threadId, true);
    });

    window.MathJax && MathJax.typeset();
    window.hljs && hljs.highlightAll();
  }

  $(document).on('click', '.js-collapse-thread', async (ev) => {
    const $tgt = $(ev.target);
    const $widget = $tgt.parents('.widget');
    const $embed = $tgt.parents('.post--comments-thread');

    const threadId = $widget.data('thread');
    const isLocked = $widget.data('locked');
    const isDeleted = $widget.data('deleted');
    const isArchived = $widget.data('archived');
    const threadTitle = $widget.find('.js-thread-title').text();
    const replyCount = $widget.data('comments');

    const $container = $(`<div class="post--comments-thread is-inline"></div>`);
    const $link = $(`<a href="/comments/thread/${threadId}" class="js--comment-link" data-thread=${threadId}></a>`);
    $link.text(threadTitle);

    if (isLocked) {
      $container.append(`<i class="fas fa-lock fa-fw" title="Locked thread" aria-label="Locked thread"></i>`);
      $container.addClass('is-locked');
    }

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

  $(document).on('click', '.js-comment-edit', async (evt) => {
    evt.preventDefault();

    const $tgt = $(evt.target);
    const $comment = $tgt.parents('.comment');
    const $commentBody = $comment.find('.comment--body');
    const $thread = $comment.parents('.thread');

    const commentId = $comment.attr('data-id');
    const postId = $thread.attr('data-post');
    const threadId = $thread.attr('data-thread');

    // if this matches, this means we are already in edit mode
    if ($(`.js-discard-edit[data-comment-id="${commentId}"]`).length) {
      return;
    }

    const originalComment = $commentBody.clone();

    const data = await QPixel.getComment(commentId);

    const formTemplate = `<form action="/comments/${commentId}/edit" method="POST" class="comment-edit-form" data-remote="true">
      <label for="comment-content" class="form-element">Comment body:</label>
      <textarea id="comment-content"
                class="form-element is-small"
                data-character-count=".js-character-count-comment-body"
                data-post="${postId}"
                data-thread="${threadId}"
                name="comment[content]"
                rows="6">${data.content}</textarea>
      <input type="submit" class="button is-muted is-filled" value="Update comment" />
      <input type="button"
             class="button is-danger is-outlined js-discard-edit"
             data-comment-id="${commentId}"
             name="js-discard-edit"
             value="Discard Edit" />
      <span class="has-float-right has-font-size-caption js-character-count-comment-body"
            data-max="1000" data-min="15">
        <i class="fas fa-ellipsis-h js-character-count__icon"></i>
        <span class="js-character-count__count">${data.content.length} / 1000</span>
      </span>
    </form>`;

    $commentBody.html(formTemplate);
    $commentBody.find('textarea#comment-content').trigger('focus');

    $commentBody.find(`#comment-content`).on('keyup', pingable_popup);

    $(`.js-discard-edit[data-comment-id="${commentId}"]`).on('click', () => {
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

  $(document).on('click', '.js-comment-delete, .js-comment-undelete', async (evt) => {
    evt.preventDefault();

    const $tgt = $(evt.target);
    const $comment = $tgt.parents('.comment');
    const commentId = $comment.attr('data-id');
    const isDelete = !$comment.hasClass('deleted-content');

    const data = await (isDelete ? QPixel.deleteComment(commentId) : QPixel.undeleteComment(commentId));

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

  $(document).on('click', '.js--show-followers', async (evt) => {
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

  $(document).on('click', '[class*=js--lock-thread] form', async (evt) => {
    evt.preventDefault();

    const $tgt = $(evt.target);
    const threadID = $tgt.data("thread");

    const data = await QPixel.lockThread(threadID);

    if (data.status === 'success') {
      window.location.reload();
    }
    else {
      QPixel.createNotification('danger', data.message);
    }
  });

  $(document).on('click', '.js--restrict-thread, .js--unrestrict-thread', async (evt) => {
    evt.preventDefault();

    const $tgt = $(evt.target);
    const threadID = $tgt.data("thread");
    const action = $tgt.data("action");
    const route = $tgt.hasClass("js--restrict-thread") ? 'restrict' : 'unrestrict';

    const resp = await QPixel.fetchJSON(`/comments/thread/${threadID}/${route}`, { type: action });

    const data = await resp.json();

    if (data.status === 'success') {
      window.location.reload();
    }
    else {
      QPixel.createNotification('danger', data.message);
    }
  });

  $(document).on('click', '.comment-form input[type="submit"]', async (evt) => {
    // Comment posting has been clicked.
    $(evt.target).attr('data-disable-with', 'Posting...');
  });

  /**
   * @type {Record<`${number}-${number}`, Record<string, number>>}
   */
  const pingable = {};
  $(document).on('keyup', '.js-comment-field', pingable_popup);

  /**
   * @type {QPixelPingablePopupCallback}
   */
  async function pingable_popup(ev) {
    if (QPixel.Popup.isSpecialKey(ev.keyCode)) {
      return;
    }

    const $tgt = $(ev.target);
    const content = $tgt.val();
    const splat = content.split(' ');
    const caretPos = $tgt[0].selectionStart;
    const [currentWord, posInWord] = QPixel.currentCaretSequence(splat, caretPos);

    const itemTemplate = $('<a href="javascript:void(0)" class="item"></a>');

    /**
     * @type {QPixelPopupCallback}
     */
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

      const items = Object.entries(pingable[`${threadId}-${postId}`]).filter((e) => {
        return e[0].toLowerCase().startsWith(currentWord.substr(1).toLowerCase());
      }).map((e) => {
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
  }

  $(document).on('click', '.js-new-thread-link', async (ev) => {
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

  $(document).on('click', '.js-reply-to-thread-link', async (ev) => {
    ev.preventDefault();
    const $tgt = $(ev.target);
    const postId = $tgt.attr('data-post');
    const $reply = $(`#reply-to-thread-form-${postId}`);

    if ($reply.is(':hidden')) {
      $reply.show();
    }
    else {
      $reply.hide();
    }
  });

  $('.js-comment-permalink > .js-text').text('copy link');
  $(document).on('click', '.js-comment-permalink', (ev) => {
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
