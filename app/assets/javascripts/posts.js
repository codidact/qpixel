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
    $tgt.trigger('ajax:success', data);
  });

  $uploadForm.on('ajax:success', async (evt, data) => {
    const $tgt = $(evt.target);
    $tgt[0].reset();

    const $postField = $('.js-post-field');
    const postText = $postField.val();
    $postField.val(postText.replace(placeholder, `![Image alt text](${data.link})`));
    $tgt.parents('.modal').removeClass('is-active');
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
      MathJax.typeset();
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
});