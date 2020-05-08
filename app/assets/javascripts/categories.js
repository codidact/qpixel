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

        $el.find('.js-tag-select').attr('data-tag-set', tagSetId);
      });
    }
    else {
      formGroups.each((i, el) => {
        const $el = $(el);
        const $caption = $el.find('.js-tags-group-caption');
        $caption.find('[data-state="absent"]').show();
        $caption.find('[data-state="present"]').hide();

        $el.find('.js-tag-select').attr('data-tag-set', null);
      });
    }
  });
});