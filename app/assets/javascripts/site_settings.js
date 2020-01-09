$(() => {
  const settingEditFields = {
    'string': $(`<input type="text" class="form-control js-setting-edit" />`),
    'integer': $('<input type="number" class="form-control js-setting-edit" />'),
    'float': $('<input type="number" step="0.0001" class="form-control js-setting-edit" />'),
    'boolean': $(`<select class="form-control js-setting-edit"><option value></option><option value="true">true</option><option value="false">false</option></select>`),
    'json': $(`<textarea rows="5" cols="100" class="form-control js-setting-edit"></textarea>`),
    'text': $(`<textarea rows="5" cols="100" class="form-control js-setting-edit"></textarea>`)
  };

  $('.js-setting-value').on('click', async evt => {
    const $tgt = $(evt.target);

    if ($tgt.hasClass('editing') || !$tgt.is('td')) {
      return;
    }

    const name = $tgt.data('name');
    const valueType = $tgt.data('type');

    const resp = await fetch(`/admin/settings/${name}`, {
      credentials: 'include'
    });
    const data = await resp.json();
    const value = data.typed;

    const form = settingEditFields[valueType].clone().val(!!value ? value.toString() : '').attr('data-name', name);
    $tgt.addClass('editing').html(form).append(`<button class="btn btn-primary js-setting-submit">Update</button>`);
  });

  $(document).on('click', '.js-setting-submit', async evt => {
    const $tgt = $(evt.target);
    const $td = $tgt.parent();
    const $input = $td.find('.js-setting-edit');
    const name = $input.data('name');
    const value = $input.val();

    const resp = await fetch(`/admin/settings/${name}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': QPixel.csrfToken() },
      body: JSON.stringify({site_setting: {value}})
    });
    const data = await resp.json();

    $td.removeClass('editing').html('').text(data.setting.typed.toString());
  });
});