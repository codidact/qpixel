$(() => {
  $('.js-license-autofill').on('click', ev => {
    const $tgt = $(ev.target);
    const $input = $tgt.parents('.form-group').find('select');
    const licenseId = $tgt.attr('data-license-id');
    $input.val(licenseId).trigger('change');
  });
});