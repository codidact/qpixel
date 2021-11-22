$(() => {
  $('.js-copy-key').on('click', ev => {
    const $tgt = $(ev.target).parents('label');
    const $field = $(`#${$tgt.attr('for')}`);
    navigator.clipboard.writeText($field.val());
    $field.focus();
    $field[0].setSelectionRange(0, $field.val().length);
  });
});
