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
    const tagSynonyms = !!tag.synonyms ? ` <i>(${tag.synonyms})</i>` : '';
    const tagSpan = `<span>${tag.text}${tagSynonyms}</span>`;
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
      insertTag: function (data, tag) {
        tag.desc = "(Create new tag)"
        // Insert the tag at the end of the results
        data.push(tag);
      },
      ajax: {
        url: '/tags',
        data: function (params) {
          $this = $(this);
          // (for the tour)
          if (Number($this.data('tag-set')) === -1) {
            return Object.assign(params, { tag_set: '1' });
          }
          return Object.assign(params, { tag_set: $this.data('tag-set') });
        },
        headers: { 'Accept': 'application/json' },
        delay: 100,
        processResults: data => {
          // (for the tour)
          if (Number($this.data('tag-set')) === -1) {
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
              synonyms: processSynonyms($this, t.tag_synonyms),
              desc: t.excerpt
            }))
          };
        },
      },
      templateResult: template,
      allowClear: true
    });
  });

  function processSynonyms($search, synonyms) {
    if (!synonyms) return synonyms;

    let displayedSynonyms;
    if (synonyms.length > 3) {
      const searchValue = $search.data('select2').selection.$search.val().toLowerCase();
      displayedSynonyms = synonyms.filter(ts => ts.name.includes(searchValue)).slice(0, 3);
    } else {
      displayedSynonyms = synonyms;
    }
    let synonymsString = displayedSynonyms.map((ts) => `${ts.name.replace(/</g, '&#x3C;').replace(/>/g, '&#x3E;')}`).join(', ');
    if (synonyms.length > displayedSynonyms.length) {
      synonymsString += `, ${synonyms.length - displayedSynonyms.length} more synonyms`;
    }
    return synonymsString;
  }

  $('#add-tag-synonym').on('click', ev => {
    const $wrapper = $('#tag-synonyms-wrapper');
    const lastId = $wrapper.children('.tag-synonym').last().attr('data-id');
    const newId = parseInt(lastId, 10) + 1;

    //Duplicate the first element at the end of the wrapper
    const newField = $wrapper.find('.tag-synonym[data-id="0"]')[0]
                             .outerHTML
                             .replace(/data-id="0"/g, 'data-id="' + newId + '"')
                             .replace(/(?<connector>attributes(\]\[)|(_))0/g, '$<connector>' + newId)
    $wrapper.append(newField);

    //Alter the newly added tag synonym
    const $newTagSynonym = $wrapper.children().last();
    $newTagSynonym.find('.tag-synonym-name').removeAttr('value').removeAttr('readonly').removeAttr('disabled');
    $newTagSynonym.find('.destroy-tag-synonym').attr('value', 'false');
    $newTagSynonym.show();

    //Add handler for removing an element
    $newTagSynonym.find(`.remove-tag-synonym`).click(removeTagSynonym);
  });

  $('.remove-tag-synonym').click(removeTagSynonym);

  function removeTagSynonym() {
    const synonym = $(this).closest('.tag-synonym');
    synonym.find('.destroy-tag-synonym').attr('value', 'true');
    synonym.hide();
  }

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
