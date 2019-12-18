$(() => {
  $('.js-tag-select').select2({
    tags: true,
    ajax: {
      url: '/tags',
      headers: { 'Accept': 'application/json' },
      delay: 100,
      processResults: data => ({results: data.map(t => ({id: t.name, text: t.name}))}),
    }
  });
});