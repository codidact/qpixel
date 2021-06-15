$(() => {
  const $uploadForm = $('.js-upload-form');

  const stringInsert = (str, idx, insert) => str.slice(0, idx) + insert + str.slice(idx);

  const placeholder = "![Uploading, please wait...]()";

  $uploadForm.find('input[type="file"]').on('change', async evt => {
    const $postField = $('.js-post-field');
    const postText = $postField.val();
    const cursorPos = $postField[0].selectionStart;

    $postField.val(stringInsert(postText, cursorPos, placeholder));

    const $tgt = $(evt.target);
    const $form = $tgt.parents('form');
    $form.submit();
  });

  $uploadForm.on('submit', async evt => {
    evt.preventDefault();

    const $tgt = $(evt.target);

    const $fileInput = $tgt.find('input[type="file"]');
    const files = $fileInput[0].files;
    if (files.length > 0 && files[0].size >= 2000000) {
      $tgt.find('.js-max-size').addClass('has-color-red-700 error-shake');
      const postField = $('.js-post-field');
      postField.val(postField.val().replace(placeholder, ''));
      setTimeout(() => {
        $tgt.find('.js-max-size').removeClass('error-shake');
      }, 1000);
      return;
    }
    else {
      $tgt.find('.js-max-size').removeClass('has-color-red-700');
    }

    const resp = await fetch($tgt.attr('action'), {
      method: $tgt.attr('method'),
      body: new FormData($tgt[0])
    });
    const data = await resp.json();
    if (resp.status === 200) {
      $tgt.trigger('ajax:success', data);
    }
    else {
      $tgt.trigger('ajax:failure', data);
    }
  });

  $uploadForm.on('ajax:success', async (evt, data) => {
    const $tgt = $(evt.target);
    $tgt[0].reset();

    const $postField = $('.js-post-field');
    const postText = $postField.val();
    $postField.val(postText.replace(placeholder, `![Image alt text](${data.link})`));
    $tgt.parents('.modal').removeClass('is-active');
  });

  $uploadForm.on('ajax:failure', async (evt, data) => {
    const $tgt = $(evt.target);
    const $postField = $('.js-post-field');
    const error = data['error'];
    QPixel.createNotification('danger', error);
    $tgt.parents('.modal').removeClass('is-active');
    $postField.val($postField.val().replace(placeholder, ''));
  });

  $('.js-category-select').select2({
    tags: true
  });

  const saveDraft = async (postText, $field, manual = false) => {
    const autosavePref = await QPixel.preference('autosave', true);
    if (autosavePref !== 'on' && !manual) {
      return;
    }

    const resp = await fetch('/posts/save-draft', {
      method: 'POST',
      credentials: 'include',
      headers: {
        'X-CSRF-Token': QPixel.csrfToken(),
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        post: postText,
        path: location.pathname
      })
    });
    if (resp.status === 200) {
      const $el = $(`<span>&middot; <span class="has-color-green-600">draft saved</span></span>`);
      $field.parents('.widget').find('.js-post-field-footer').append($el);
      $el.fadeOut(1500, function () { $(this).remove() });
    }
  };

  $('.js-save-draft').on('click', async ev => {
    const $tgt = $(ev.target);
    const $field = $tgt.parents('.widget').find('.js-post-field');
    const postText = $field.val();
    await saveDraft(postText, $field, true);
  });

  let featureTimeout = null;
  let draftTimeout = null;

  const postFields = $('.post-field');

  postFields.on('focus keyup markdown', evt => {
    const $tgt = $(evt.target);

    if (!window.converter) {
      window.converter = window.markdownit({
        html: true,
        breaks: false,
        linkify: true
      });
      window.converter.use(window.markdownitFootnote);
    }
    window.setTimeout(() => {
      const converter = window.converter;
      const text = $(evt.target).val();
      const unsafe_html = converter.render(text);
      const html = DOMPurify.sanitize( unsafe_html , {USE_PROFILES: {html: true}} );
      $tgt.parents('.form-group').siblings('.post-preview').html(html);
      $tgt.parents('form').find('.js-post-html[name="__html"]').val(html + '<!-- g: js, mdit -->');
    }, 0);

    if (featureTimeout) {
      clearTimeout(featureTimeout);
    }

    featureTimeout = setTimeout(() => {
      if (window['MathJax']) {
        MathJax.typeset();
      }
      if (window['hljs']) {
        hljs.highlightAll();
      }
    }, 1000);
  }).on('keyup', ev => {
    clearTimeout(draftTimeout);
    const text = $(ev.target).val();
    draftTimeout = setTimeout(() => {
      saveDraft(text, $(ev.target));
    }, 3000);
  }).trigger('markdown');

  postFields.parents('form').on('submit', async ev => {
    const $tgt = $(ev.target);
    const field = $tgt.find('.post-field');

    const draftDeleted = $tgt.attr('data-draft-deleted') === 'true';
    const isValidated = $tgt.attr('data-validated') === 'true';

    if (draftDeleted && isValidated) {
      return;
    }
    ev.preventDefault();

    // Draft handling
    if (!draftDeleted) {
      const resp = await fetch('/posts/delete-draft', {
        method: 'POST',
        credentials: 'include',
        headers: {
          'X-CSRF-Token': QPixel.csrfToken(),
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ path: location.pathname })
      });
      if (resp.status === 200) {
        $tgt.attr('data-draft-deleted', 'true');

        if (isValidated) {
          $tgt.submit();
        }
      }
      else {
        console.error('Failed to delete draft.');
      }
    }


    // Validation
    if (!isValidated) {
      const text = $(field).val();
      const validated = QPixel.validatePost(text);
      if (validated[0] === true) {
        $tgt.attr('data-validated', 'true');
        $tgt.submit();
      }
      else {
        const warnings = validated[1].filter(x => x['type'] === 'warning');
        const errors = validated[1].filter(x => x['type'] === 'error');

        if (warnings.length > 0) {
          const $warningBox = $(`<div class="notice is-warning"></div>`);
          const $warningList = $(`<ul></ul>`);
          warnings.forEach(w => {
            $warningList.append(`<li>${w['message']}</li>`);
          });
          $warningBox.append($warningList);
          $tgt.find('input[type="submit"]').before($warningBox);
        }

        if (errors.length > 0) {
          const $errorBox = $(`<div class="notice is-danger"></div>`);
          const $errorList = $(`<ul></ul>`);
          errors.forEach(e => {
            $errorList.append(`<li>${e['message']}</li>`);
          });
          $errorBox.append($errorList);
          $tgt.find('input[type="submit"]').before($errorBox);
        }

        if (warnings.length > 0 && errors.length === 0) {
          $tgt.attr('data-validated', 'true');
        }
      }

      setTimeout(() => {
        $tgt.find('input[type="submit"]').attr('disabled', false);
      }, 1000);
    }
  });

  $('.js-draft-loaded').each((i, e) => {
    $(e).parents('.widget').after(`<div class="notice is-info has-font-size-caption">
      <i class="fas fa-exclamation-circle"></i> <strong>Draft loaded.</strong>
      You've edited this post before but didn't save it. We loaded your edits here for you.
    </div>`);
  });

  $('.js-permalink > .js-text').text('Copy Link');
  $('.js-permalink').on('click', ev => {
    ev.preventDefault();

    const $tgt = $(ev.target).is('a') ? $(ev.target) : $(ev.target).parents('a');
    const link = $tgt.attr('href');
    navigator.clipboard.writeText(link);
    $tgt.find('.js-text').text('Copied!');
    setTimeout(() => {
      $tgt.find('.js-text').text('Copy Link');
    }, 1000);
  });

  $('.js-nominate-promotion').on('click', async ev => {
    ev.preventDefault();

    const $tgt = $(ev.target);
    const postId = $tgt.attr('data-post-id');
    const resp = await fetch(`/posts/${postId}/promote`, {
      method: 'POST',
      headers: {
        'Accept': 'application/json',
        'X-CSRF-Token': QPixel.csrfToken()
      }
    });
    const data = await resp.json();
    if (data.success) {
      QPixel.createNotification('success', 'Added post to promotion list.');
    }
    else {
      QPixel.createNotification('danger', `Couldn't add post to promotion list. (${resp.status})`);
    }
    $('.js-mod-tools').removeClass('is-active');
  });

  $('.js-cancel-edit').on('click', async ev => {
    ev.preventDefault();

    let $btn = $(ev.target);

    if (!confirm($btn.attr('data-question-body'))) {
      return;
    }

    await fetch('/posts/delete-draft', {
      method: 'POST',
      credentials: 'include',
      headers: {
        'X-CSRF-Token': QPixel.csrfToken(),
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ path: location.pathname })
    });

    location.href = $btn.attr('href');
  });
});