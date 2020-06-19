$(() => {
  $('.js-tag-select').each((i, el) => {
    const $tgt = $(el);
    const useIds = $tgt.attr('data-use-ids') === 'true';
    $tgt.select2({
      tags: $tgt.attr('data-create') !== 'false',
      ajax: {
        url: '/tags',
        data: function (params) {
          return Object.assign(params, { tag_set: $(this).data('tag-set') });
        },
        headers: { 'Accept': 'application/json' },
        delay: 100,
        processResults: data => ({results: data.map(t => ({id: useIds ? t.id : t.name, text: t.name}))}),
      }
    });
  });

  $('.js-add-required-tag').on('click', ev => {
    const $tgt = $(ev.target);
    const tagId = $tgt.attr('data-tag-id');
    const tagName = $tgt.attr('data-tag-name');
    const $select = $tgt.parents('.form-group').find('select');
    const existing = $select.find(`option[value=${tagId}]`);
    if (existing.length > 0) {
      $select.val([tagId, ...($select.val() || [])]).trigger('change');
    }
    else {
      const option = new Option(tagName, tagId, false, true);
      $tgt.parents('.form-group').find('select').append(option).trigger('change');
    }
  });
});