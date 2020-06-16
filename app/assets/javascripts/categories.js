$(() => {
  $('.js-category-tag-set-select').on('change', ev => {
    const $tgt = $(ev.target);
    const tagSetId = $tgt.val();
    const formGroups = $('.js-category-tags-group');
    if (tagSetId) {
      formGroups.each((i, el) => {
        const $el = $(el);
        const $caption = $el.find('.js-tags-group-caption');
        $caption.find('[data-state="absent"]').hide();
        $caption.find('[data-state="present"]').show();

        $el.find('.js-tag-select').attr('data-tag-set', tagSetId).attr('disabled', false);
      });
    }
    else {
      formGroups.each((i, el) => {
        const $el = $(el);
        const $caption = $el.find('.js-tags-group-caption');
        $caption.find('[data-state="absent"]').show();
        $caption.find('[data-state="present"]').hide();

        $el.find('.js-tag-select').attr('data-tag-set', null).attr('disabled', true);
      });
    }
  });

  $('.js-add-required-topic').on('click', ev => {
    const $required = $('.js-required-tags');
    const $topic = $('.js-topic-tags');
    const union = ($required.val() || []).concat($topic.val() || []);

    const options = $topic.find('option').toArray();
    const optionIds = options.map(x => $(x).attr('value'));
    const missing = union.filter(x => !optionIds.includes(x));
    const missingOptions = $required.find('option').toArray().filter(x => missing.includes($(x).attr('value')));

    missingOptions.forEach(opt => {
      const $append = $(opt).clone();
      $append.removeAttr('data-select2-id');
      $topic.append($append);
    });
    $topic.val(union).trigger('change');
  });

  $('.js-category-change-select').each((i, el) => {
    const $tgt = $(el);
    console.log('hi');
    $tgt.select2({
      ajax: {
        url: '/categories',
        headers: { 'Accept': 'application/json' },
        delay: 100,
        processResults: data => ({results: data.map(c => ({id: c.id, text: c.name}))}),
      }
    });
  });

  $('.js-change-category').on('ajax:success', ev => {
    location.reload();
  });
});