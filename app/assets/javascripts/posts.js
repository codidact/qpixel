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

  const saveDraft = async (postText, $field) => {
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
      const $el = $(`<span class="has-color-green-600">Draft saved</span>`);
      $field.parents('.widget').after($el);
      $el.fadeOut(1500, function () { $(this).remove() });
    }
  };

  let mathjaxTimeout = null;
  let draftTimeout = null;

  const postFields = $('.post-field');

  postFields.on('focus keyup markdown', evt => {
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
      const html = converter.render(text);
      $(evt.target).parents('.form-group').siblings('.post-preview').html(html);
    }, 0);

    if (mathjaxTimeout) {
      clearTimeout(mathjaxTimeout);
    }

    mathjaxTimeout = setTimeout(() => {
      if (window['MathJax']) {
        MathJax.typeset();
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
    if ($tgt.attr('data-draft-deleted') !== 'true') {
      ev.preventDefault();
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
        $tgt.attr('data-draft-deleted', 'true').submit();
      }
      else {
        console.error('Failed to delete draft.');
      }
    }
  });

  $('.js-draft-loaded').each((i, e) => {
    $(e).parents('.widget').after(`<div class="notice is-info has-font-size-caption">
      <i class="fas fa-exclamation-circle"></i> <strong>Draft loaded.</strong>
      You've edited this post before but didn't save it. We loaded your edits here for you.
    </div>`);
  });

  postFields.each((i, field) => {
    $(field).parents('form').on('submit', ev => {
      const $tgt = $(ev.target);
      if ($tgt.attr('data-validated') === 'true') {
        return;
      }

      ev.preventDefault();

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
    });
  });
});