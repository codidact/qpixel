// IF YOU CHANGE THESE VALUES YOU MUST ALSO CHANGE app/helpers/posts_helper.rb
const ALLOWED_TAGS = ['a', 'p', 'span', 'b', 'i', 'em', 'strong', 'hr', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6',
  'blockquote', 'img', 'strike', 'del', 'code', 'pre', 'br', 'ul', 'ol', 'li', 'sup', 'sub', 'section', 'details',
  'summary', 'ins', 'table', 'thead', 'tbody', 'tr', 'th', 'td', 's'];
const ALLOWED_ATTR = ['id', 'class', 'href', 'title', 'src', 'height', 'width', 'alt', 'rowspan', 'colspan', 'lang',
  'start', 'dir'];
// this is a list of constructors to ignore even if they are removed by sanitizer (mostly comments & body)
const IGNORE_UNSUPPORTED = [Comment, HTMLBodyElement];

$(() => {
  DOMPurify.addHook("uponSanitizeAttribute", (node, event) => {
    const rowspan = node.getAttribute("rowspan");
    const colspan = node.getAttribute("colspan");

    if (rowspan && Number.isNaN(+rowspan)) {
      event.keepAttr = false;
    }

    if (colspan && Number.isNaN(+colspan)) {
      event.keepAttr = false;
    }
  });

  const $uploadForm = $('.js-upload-form');

  const stringInsert = (str, idx, insert) => str.slice(0, idx) + insert + str.slice(idx);

  const placeholder = "![Uploading, please wait...]()";

  $uploadForm.find('input[type="file"]').on('change', async (evt) => {
    const $postField = $('.js-post-field');
    const postText = $postField.val();
    const cursorPos = $postField[0].selectionStart;

    $postField.val(stringInsert(postText, cursorPos, placeholder));

    const $tgt = $(evt.target);
    const $form = $tgt.parents('form');
    $form.submit();
  });

  $uploadForm.on('submit', async (evt) => {
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
    $postField.val(postText.replace(placeholder, `![Image_alt_text](${data.link})`));
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

  /**
   * @typedef {{
   *  body: string
   *  comment?: string
   *  excerpt?: string
   *  license?: string
   *  tags?: string[]
   *  title?: string
   * }} PostDraft
   * 
   * Attempts to save a post draft
   * @param {PostDraft} draft post draft
   * @param {JQuery<Element>} $field body input element
   * @param {boolean} [manual] whether manual draft saving is enabled
   * @returns {Promise<void>}
   */
  const saveDraft = async (draft, $field, manual = false) => {
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
      body: JSON.stringify({ ...draft, path: location.pathname })
    });

    if (resp.status === 200) {
      const $statusEl = $field.parents('.widget').find('.js-post-draft-status');

      $statusEl.removeClass('transparent');

      setTimeout(() => {
        $statusEl.addClass('transparent');
      }, 1500);
    }
  };

  /**
   * Extracts draft info from a given target
   * @param {EventTarget} target post input field or "save draft" button
   * @returns {{ draft: PostDraft, field: any }}
   */
  const parseDraft = (target) => {
    const $tgt = $(target);
    const $form = $tgt.parents('form');

    const $bodyField = $form.find('.js-post-field');
    const $licenseField = $form.find('.js-license-select');
    const $excerptField = $form.find('.js-tag-excerpt');
    
    const $tagsField = $form.find('#post_tags_cache');
    const $titleField = $form.find('#post_title');
    const $commentField = $form.find('#edit_comment');

    const bodyText = $bodyField.val();
    const commentText = $commentField.val();
    const excerptText = $excerptField.val();
    const license = $licenseField.val();
    const tags = $tagsField.val();
    const titleText = $titleField.val();

    /** @type {PostDraft} */
    const draft = {
      body: bodyText,
      comment: commentText,
      excerpt: excerptText,
      license: license,
      tags: tags,
      title: titleText,
    };

    return { draft, field: $bodyField };
  };

  $('.js-save-draft').on('click', async (ev) => {
    const { draft, field } = parseDraft(ev.target);
    await saveDraft(draft, field, true);
  });

  let featureTimeout = null;
  let draftTimeout = null;

  const postFields = $('.post-field');

  const draftFieldsSelectors = [
    '.js-post-field',
    '.js-license-select',
    '.js-tag-excerpt',
    '#edit_comment',
    '#post_tags_cache',
    '#post_title',
    '#tag_parent_id',
  ];

  // TODO: consider merging with post fields
  $(draftFieldsSelectors.join(', ')).on('keyup change', (ev) => {
    clearTimeout(draftTimeout);
    draftTimeout = setTimeout(() => {
      const { draft, field } = parseDraft(ev.target);
      saveDraft(draft, field);
    }, 3000);
  });

  postFields.on('paste', async (evt) => {
    if (evt.originalEvent.clipboardData.files.length > 0) {
      const $fileInput = $uploadForm.find('input[type="file"]');
      $fileInput[0].files = evt.originalEvent.clipboardData.files;
      $fileInput.trigger('change');
    }
  });

  postFields.on('focus keyup paste change markdown', (() => {
    let previous = null;
    return evt => {
      const $tgt = $(evt.target);
      const text = $(evt.target).val();
      // Don't bother re-rendering if nothing's changed
      if (text === previous) { return; }
      previous = text;
      if (!window.converter) {
        window.converter = window.markdownit({
          html: true,
          breaks: false,
          linkify: true
        });
        window.converter.use(window.markdownitFootnote);
        window.converter.use(window.latexEscape);
      }
      window.setTimeout(() => {
        const converter = window.converter;
        const unsafe_html = converter.render(text);
        const html = DOMPurify.sanitize(unsafe_html, {
          ALLOWED_TAGS,
          ALLOWED_ATTR
        });

        const removedElements = [...new Set(DOMPurify.removed
          .filter(entry => entry.element && !IGNORE_UNSUPPORTED.some((ctor) => entry.element instanceof ctor))
          .map(entry => entry.element.localName))];

        const removedAttributes = [...new Set(DOMPurify.removed
          .filter(entry => entry.attribute)
          .map(entry => [
            entry.attribute.name + (entry.attribute.value ? `='${entry.attribute.value}'` : ''),
            entry.from.localName
          ]))]

        $tgt.parents('form')
          .find('.rejected-elements')
          .toggleClass('hide', removedElements.length === 0 && removedAttributes.length === 0)
          .find('ul')
          .empty()
          .append(
            removedElements.map(name => $(`<li><code>&lt;${name}&gt;</code></li>`)),
            removedAttributes.map(([attr, elName]) => $(`<li><code>${attr}</code> (in <code>&lt;${elName}&gt;</code>)</li>`)));

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
    };
  })()).trigger('markdown');

  postFields.parents('form').on('submit', async (ev) => {
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
      You had edited this before but haven't saved it. We loaded the edits for you.
    </div>`);
  });

  const setCopyButtonState = ($button, state) => {
    const isSuccess = state === "success";
    const buttonClass = isSuccess ? "is-green" : "is-danger";
    const iconClass = isSuccess ? "fa-check" : "fa-times";

    const $icon = $button.find(".fa");

    $icon.removeClass("fa-copy");
    $icon.addClass(iconClass);
    $button.addClass(buttonClass);

    setTimeout(() => {
      $icon.removeClass(iconClass);
      $button.removeClass(buttonClass);
      $icon.addClass("fa-copy");
    }, 1e3);
  };

  $(".js-permalink-trigger").removeAttr("hidden");

  $(".js-permalink-copy").on("click", async (ev) => {
    ev.preventDefault();

    const $tgt = $(ev.target);

    const $button = $tgt.hasClass("js-permalink-copy")
      ? $tgt
      : $tgt.parents(".js-permalink-copy");

    const postId = $button.data("post-id");
    const linkType = $button.data("link-type");

    if (!postId || !linkType) {
      return;
    }

    const $input = $(`#permalink-${postId}-${linkType}`);

    const url = $input.val();

    if (!url) {
      return;
    }

    try {
      await navigator.clipboard.writeText(url);
      setCopyButtonState($button, "success");
    }
    catch (_e) {
      setCopyButtonState($button, "error");
    }
  });

  $('.js-nominate-promotion').on('click', async (ev) => {
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

  $('.js-cancel-edit').on('click', async (ev) => {
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
