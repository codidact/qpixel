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

  $('.post-field').on('keyup markdown', evt => {
    if (!window.converter) {
      window.converter = new showdown.Converter();
      window.converter.setFlavor('github');
    }
    window.setTimeout(() => {
      const converter = window.converter;
      const text = $(evt.target).val();
      const html = converter.makeHtml(text);
      $(evt.target).parents('.form-group').siblings('.post-preview').html(html);
    }, 0);
  });
});