$(() => {
  const sum = (ary) => ary.reduce((a, b) => a + b, 0);

  const splitWordsMaxLength = (text, max) => {
    const words = text.split(' ');
    const splat = [[]];
    words.forEach(word => {
      if (sum(splat[splat.length - 1].map(w => w.length + 1)) > max - word.length) {
        splat.push([]);
      }
      splat[splat.length - 1].push(word);
    });
    return splat.map(s => s.join(' '));
  };

  const template = (tag) => {
    const tagSpan = `<span>${tag.text}</span>`;
    const descSpan = !!tag.desc ?
      `<br/><span class="has-color-tertiary-900 has-font-size-caption">${splitWordsMaxLength(tag.desc, 120)[0]}...</span>` :
      '';
    return $(tagSpan + descSpan);
  }

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
        processResults: data => {
          return {results: data.map(t => ({id: useIds ? t.id : t.name, text: t.name, desc: t.excerpt}))};
        },
      },
      templateResult: template
    });
  });

  $('.js-add-required-tag').on('click', ev => {
    const $tgt = $(ev.target);
    const useIds = $tgt.attr('data-use-ids') === 'true';
    const tagId = $tgt.attr('data-tag-id');
    const tagName = $tgt.attr('data-tag-name');
    const $select = $tgt.parents('.form-group').find('select');
    const existing = $select.find(`option[value=${tagId}]`);
    if (existing.length > 0) {
      $select.val([useIds ? tagId : tagName, ...($select.val() || [])]).trigger('change');
    }
    else {
      const option = new Option(tagName, useIds ? tagId : tagName, false, true);
      $tgt.parents('.form-group').find('select').append(option).trigger('change');
    }
  });
});