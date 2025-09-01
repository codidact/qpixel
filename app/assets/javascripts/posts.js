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

  const $postFields = $('.post-field');

  /** @type {JQuery<HTMLFormElement>} */
  const $uploadForm = $('.js-upload-form');

  /**
   * Inserts text at a given {@link idx} in a given {@link str}
   * @param {string} str text to insert into
   * @param {number} idx position to insert at
   * @param {string} insert text to insert
   * @returns {string}
   */
  const stringInsert = (str, idx, insert) => str.slice(0, idx) + insert + str.slice(idx);

  const placeholder = "![Uploading, please wait...]()";

  $uploadForm.find('input[type="file"]').on('change', async (evt) => {
    /** @type {HTMLInputElement} */
    const postField = document.querySelector('.js-post-field');
    const postText = postField.value;
    const cursorPos = postField.selectionStart;

    postField.value = stringInsert(postText, cursorPos, placeholder);

    $uploadForm.trigger('submit')
  });

  QPixel.DOM?.watchClass('#markdown-image-upload.is-active', (target) => {
    const fileInput = target.querySelector('input[type="file"]');

    if (fileInput instanceof HTMLInputElement) {
      fileInput.focus();
    }
  });

  $uploadForm.on('submit', async (evt) => {
    evt.preventDefault();

    const $tgt = $(evt.target);

    const $fileInput = $tgt.find('input[type="file"]');
    const files = /** @type {HTMLInputElement} */ ($fileInput[0]).files;

    // TODO: MaxUploadSize is a site setting and can be changed
    if (files.length > 0 && files[0].size >= 2000000) {
      const isUploadModalOpened = $('#markdown-image-upload').hasClass('is-active');

      const postField = $('.js-post-field');
      postField.val(postField.val()?.toString().replace(placeholder, ''));

      if (!isUploadModalOpened) {
        QPixel.createNotification('danger', `Can't upload files with size more than 2MB`);
      } else {
        $tgt.find('.js-max-size').addClass('has-color-red-700 error-shake');
        setTimeout(() => {
          $tgt.find('.js-max-size').removeClass('error-shake');
        }, 1000);
      }

      return;
    }
    else {
      $tgt.find('.js-max-size').removeClass('has-color-red-700');
    }

    const resp = await fetch($tgt.attr('action'), {
      method: $tgt.attr('method'),
      body: new FormData(/** @type {HTMLFormElement} */ ($tgt[0]))
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
    /** @type {HTMLFormElement} */ ($tgt[0]).reset();

    const $postField = $('.js-post-field');
    const postText = $postField.val()?.toString();
    $postField.val(postText.replace(placeholder, `![Image_alt_text](${data.link})`));
    $tgt.parents('.modal').removeClass('is-active');

    $postFields.trigger('change')
  });

  $uploadForm.on('ajax:failure', async (evt, data) => {
    const $tgt = $(evt.target);
    const $postField = $('.js-post-field');
    const error = data['error'];
    QPixel.createNotification('danger', error);
    $tgt.parents('.modal').removeClass('is-active');
    $postField.val($postField.val()?.toString().replace(placeholder, ''));
  });

  /**
   * Temporarily displays the draft's status with a given message
   * @param {JQuery<Element>} $field draftable field
   * @param {string} message draft status message
   * @returns {void}
   */
  const flashDraftStatus = ($field, message) => {
    const $statusEl = $field.parents('.widget').find('.js-post-draft-status');

    $statusEl.text(message);
    $statusEl.removeClass('transparent');

    setTimeout(() => {
      $statusEl.addClass('transparent');
    }, 1500);
  };

  /**
   * Removes the "draft loaded" notice from the page
   * @returns {void}
   */
  const removeDraftLoadedNotice = () => {
    document.querySelector('.js-draft-notice')?.remove();
  };

  /**
   * Attempts to save a post draft
   * @param {QPixelDraft} draft post draft
   * @param {JQuery<Element>} $field draftable field
   * @param {boolean} [manual] whether manual draft saving is enabled
   * @returns {Promise<void>}
   */
  const saveDraft = async (draft, $field, manual = false) => {
    const autosavePref = await QPixel.preference('autosave', true);

    if (autosavePref !== 'on' && !manual) {
      return;
    }

    const data = await QPixel.saveDraft(draft);

    QPixel.handleJSONResponse(data, () => {
      flashDraftStatus($field, 'draft saved');
    });
  };

  /**
   * Attempts to remove a post draft
   * @param {JQuery<Element>} $field draftable field
   * @returns {Promise<boolean>}
   */
  const deleteDraft = async ($field) => {
    const data = await QPixel.deleteDraft();

    return QPixel.handleJSONResponse(data, () => {
      flashDraftStatus($field, 'draft deleted');
      removeDraftLoadedNotice();
    });
  }

  /**
   * Helper for getting draft-related elements from a given event target
   * @param {EventTarget} target post field or one of the draft buttons
   * @returns {{
   *  $form: JQuery<HTMLFormElement>,
   *  $field: JQuery<HTMLElement>
   * }}
   */
  const getDraftElements = (target) => {
    const $tgt = $(target);
    const $form = $tgt.parents('form');
    const $field = $form.find('.js-post-field');
    return { $form, $field };
  };

  /**
   * Extracts draft info from a given target
   * @param {EventTarget} target post field or one of the draft buttons
   * @returns {{
   *  draft: QPixelDraft,
   *  $field: JQuery<HTMLElement>
   * }}
   */
  const parseDraft = (target) => {
    const { $field: $bodyField, $form } = getDraftElements(target);

    const $licenseField = $form.find('.js-license-select');
    const $excerptField = $form.find('.js-tag-excerpt');
    
    const $tagsField = $form.find('#post_tags_cache');
    const $titleField = $form.find('#post_title');
    const $commentField = $form.find('#edit_comment');
    const $tagNameField = $form.find('#tag_name');

    const bodyText = $bodyField.val()?.toString();
    const commentText = $commentField.val()?.toString();
    const excerptText = $excerptField.val()?.toString();
    const license = $licenseField.val()?.toString();
    const tags = $tagsField.val();
    const titleText = $titleField.val()?.toString();
    const tagName = $tagNameField.val()?.toString();

    /** @type {QPixelDraft} */
    const draft = {
      body: bodyText,
      comment: commentText,
      excerpt: excerptText,
      license: license,
      tags: Array.isArray(tags) ? tags: [],
      tag_name: tagName,
      title: titleText,
    };

    return { draft, $field: $bodyField };
  };

  $('.js-delete-draft').on('click', async (ev) => {
    const { $field } = getDraftElements(ev.target);
    await deleteDraft($field);
  });

  $('.js-save-draft').on('click', async (ev) => {
    const { draft, $field } = parseDraft(ev.target);
    await saveDraft(draft, $field, true);
  });

  let featureTimeout = null;
  let draftTimeout = null;

  const draftFieldsSelectors = [
    '.js-post-field',
    '.js-license-select',
    '.js-tag-excerpt',
    '#edit_comment',
    '#post_tags_cache',
    '#post_title',
    '#tag_parent_id',
    '#tag_name',
  ];

  // TODO: consider merging with post fields
  $(draftFieldsSelectors.join(', ')).on('keyup change', (ev) => {
    clearTimeout(draftTimeout);
    draftTimeout = setTimeout(() => {
      const { draft, $field } = parseDraft(ev.target);
      saveDraft(draft, $field);
    }, 1000);
  });

  $postFields.on('paste', async (evt) => {
    const eventData = /** @type {ClipboardEvent} */ (evt.originalEvent);
    if (eventData.clipboardData.files.length > 0) {
      // must be called to prevent raw file name to be inserted after the placeholder
      evt.preventDefault()

      /** @type {JQuery<HTMLInputElement>} */
      const $fileInput = $uploadForm.find('input[type="file"]');
      $fileInput[0].files = eventData.clipboardData.files;
      $fileInput.trigger('change');
    }
  });

  $postFields.on('focus keyup paste change markdown', (() => {
    let previous = null;
    return (evt) => {
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
          ALLOWED_TAGS: QPixel.ALLOWED_POST_TAGS,
          ALLOWED_ATTR: QPixel.ALLOWED_POST_ATTRS
        });

        const removedElements = [...new Set(DOMPurify.removed
          .filter((entry) => entry.element && !IGNORE_UNSUPPORTED.some((ctor) => entry.element instanceof ctor))
          .map((entry) => entry.element.localName))];

        const removedAttributes = [...new Set(DOMPurify.removed
          .filter((entry) => entry.attribute)
          .map((entry) => [
            entry.attribute.name + (entry.attribute.value ? `='${entry.attribute.value}'` : ''),
            entry.from.localName
          ]))]

        $tgt.parents('form')
          .find('.rejected-elements')
          .toggleClass('hide', removedElements.length === 0 && removedAttributes.length === 0)
          .find('ul')
          .empty()
          .append(
            removedElements.map((name) => $(`<li><code>&lt;${name}&gt;</code></li>`)),
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

  $postFields.parents('form').on('submit', async (ev) => {
    const $tgt = $(ev.target);
    const $field = $tgt.find('.js-post-field');

    const draftDeleted = $tgt.attr('data-draft-deleted') === 'true';
    const isValidated = $tgt.attr('data-validated') === 'true';

    if (draftDeleted && isValidated) {
      return;
    }

    ev.preventDefault();

    // Draft handling
    if (!draftDeleted) {
      const status = await deleteDraft($field);

      if (status) {
        $tgt.attr('data-draft-deleted', 'true');

        if (isValidated) {
          $tgt.submit();
        }
      }
      else {
        QPixel.createNotification('danger', `Failed to delete post draft. (${status})`);
      }
    }


    // Validation
    if (!isValidated) {
      const text = $field.val()?.toString();
      const validated = QPixel.validatePost(text);
      if (validated[0] === true) {
        $tgt.attr('data-validated', 'true');
        $tgt.submit();
      }
      else {
        const warnings = validated[1].filter((x) => x['type'] === 'warning');
        const errors = validated[1].filter((x) => x['type'] === 'error');

        if (warnings.length > 0) {
          const $warningBox = $(`<div class="notice is-warning"></div>`);
          const $warningList = $(`<ul></ul>`);
          warnings.forEach((w) => {
            $warningList.append(`<li>${w['message']}</li>`);
          });
          $warningBox.append($warningList);
          $tgt.find('input[type="submit"]').before($warningBox);
        }

        if (errors.length > 0) {
          const $errorBox = $(`<div class="notice is-danger"></div>`);
          const $errorList = $(`<ul></ul>`);
          errors.forEach((e) => {
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
        $tgt.find('input[type="submit"]').attr('disabled', null);
      }, 1000);
    }
  });

  $('.js-draft-loaded').each((_i, e) => {
    $(e).parents('.widget').after(`<div class="notice is-info has-font-size-caption js-draft-notice">
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

    const url = $input.val()?.toString();

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

    const resp = await QPixel.fetchJSON(`/posts/${postId}/promote`, {});

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

    const { $field } = getDraftElements(ev.target);

    await deleteDraft($field);

    location.href = $btn.attr('href');
  });
});
