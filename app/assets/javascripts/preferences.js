document.addEventListener('DOMContentLoaded', () => {
  $('.js-user-pref').on('change', async (ev) => {
    const $tgt = $(ev.target);
    let value;
    if ($tgt.attr('type') === 'checkbox') {
      value = $tgt.is(':checked');
    }
    else {
      value = $tgt.val();
    }
    const prefName = $tgt.attr('data-pref');
    const community = $tgt.attr('data-community') === 'true';

    await QPixel.setPreference(prefName, value, community);
  });

  // We're not using jQuery .each() because it (& TypeScript) has problems accepting async functions.
  $('.item-list--item').find('.badge.is-tag').toArray().forEach(async e => {
    const prefValue = await QPixel.preference('favorite_tags', true);
    if (!prefValue) {
      return;
    }

    const tags = prefValue.split(/,(?: +)?/);
    if (tags.indexOf($(e).text()) > -1) {
      $(e).addClass('is-yellow');
    }
  });
});
