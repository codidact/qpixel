$(() => {
  $('.js-user-pref').on('change', async ev => {
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
});