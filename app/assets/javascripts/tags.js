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
});