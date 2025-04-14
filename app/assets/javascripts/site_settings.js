$(() => {
  const settingEditFields = {
    'string': $(`<input type="text" class="form-element js-setting-edit" />`),
    'integer': $('<input type="number" class="form-element js-setting-edit" />'),
    'float': $('<input type="number" step="0.0001" class="form-element js-setting-edit" />'),
    'boolean': $(`<select class="form-element js-setting-edit"><option value></option><option value="true">true</option><option value="false">false</option></select>`),
    'json': $(`<textarea rows="5" cols="100" class="form-element js-setting-edit"></textarea>`),
    'text': $(`<textarea rows="5" cols="100" class="form-element js-setting-edit"></textarea>`)
  };

  $('.js-setting-value').on('click', async (evt) => {
    const $tgt = $(evt.target);

    if ($tgt.hasClass('editing') || !$tgt.is('td')) {
      return;
    }

    const name = $tgt.data('name');
    const valueType = $tgt.data('type');
    const communityId = $tgt.data('community-id');

    const resp = await fetch(`/admin/settings/${name}${!!communityId ? '?community_id=' + communityId : ''}`, {
      credentials: 'include'
    });
    const data = await resp.json();
    const value = data.typed;

    const form = settingEditFields[valueType].clone().val(!!value ? value.toString() : '')
                                             .attr('data-name', name).attr('data-community-id', communityId);
    $tgt.addClass('editing').html(form).append(`<button class="button is-primary is-filled js-setting-submit">Update</button>`);
  });

  $(document).on('click', '.js-setting-submit', async (evt) => {
    const $tgt = $(evt.target);
    const $td = $tgt.parent();
    const $input = $td.find('.js-setting-edit');
    const name = $input.data('name');
    const communityId = $input.data('community-id');
    const value = $input.val();

    let body = {site_setting: {value}};
    if (!!communityId) {
      body = Object.assign(body, {community_id: communityId});
    }

    const resp = await fetch(`/admin/settings/${name}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': QPixel.csrfToken() },
      body: JSON.stringify(body)
    });
    const data = await resp.json();

    $td.removeClass('editing').html('').text(data.setting.typed.toString());
  });
});
