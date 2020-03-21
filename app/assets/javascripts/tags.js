$(() => {
  $('.js-tag-select').select2({
    tags: true,
    ajax: {
      url: '/tags',
      data: function (params) {
        return Object.assign(params, { tag_set: $(this).data('tag-set') });
      },
      headers: { 'Accept': 'application/json' },
      delay: 100,
      processResults: data => ({results: data.map(t => ({id: t.name, text: t.name}))}),
    }
  });
});