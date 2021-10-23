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
    let desc = !!tag.desc ? splitWordsMaxLength(tag.desc, 120) : '';
    const descSpan = !!tag.desc ?
      `<br/><span class="has-color-tertiary-900 has-font-size-caption">${desc[0]}${desc.length > 1 ? '...' : ''}</span>` :
      '';
    return $(tagSpan + descSpan);
  }

  $('.js-tag-select').each((i, el) => {
    const $tgt = $(el);
    let $this;
    const useIds = $tgt.attr('data-use-ids') === 'true';
    $tgt.select2({
      tags: $tgt.attr('data-create') !== 'false',
      ajax: {
        url: '/tags',
        data: function (params) {
          $this = $(this);
          // (for the tour)
          if ($this.data('tag-set') === '-1') {
            return Object.assign(params, { tag_set: "1" });
          }
          return Object.assign(params, { tag_set: $this.data('tag-set') });
        },
        headers: { 'Accept': 'application/json' },
        delay: 100,
        processResults: data => {
          // (for the tour)
          if ($this.data('tag-set') === '-1') {
            return {
              results: [
                { id: 1, text: 'hot-red-firebreather', desc: 'Very cute dragon' },
                { id: 2, text: 'training', desc: 'How to train a dragon' },
                { id: 3, text: 'behavior', desc: 'How a dragon behaves' },
                { id: 4, text: 'sapphire-blue-waterspouter', desc: 'Other cute dragon' }
              ]
            }
          }
          return {
            results: data.map(t => ({
              id: useIds ? t.id : t.name,
              text: t.name.replace(/</g, '&#x3C;').replace(/>/g, '&#x3E;'),
              desc: t.excerpt
            }))
          };
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

  $('.js-rename-tag').on('click', async ev => {
    const $tgt = $(ev.target).is('a') ? $(ev.target) : $(ev.target).parents('a');
    const categoryId = $tgt.attr('data-category');
    const tagId = $tgt.attr('data-tag');
    const tagName = $tgt.attr('data-name');

    const renameTo = prompt(`Rename tag ${tagName} to:`);
    if (!!renameTo) {
      const resp = await fetch(`/categories/${categoryId}/tags/${tagId}/rename`, {
        method: 'POST',
        credentials: 'include',
        headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': QPixel.csrfToken() },
        body: JSON.stringify({ name: renameTo })
      });
      const data = await resp.json();
      if (data.success) {
        location.reload();
      }
      else {
        console.error('Failed to rename tag, somehow');
      }
    }
  });
});