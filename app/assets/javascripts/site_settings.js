$(() => {
  /**
   * @type {Record<string, JQuery<HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement>>}
   */
  const settingEditFields = {
    'array': $(`<select class="form-element js-setting-edit" multiple></select>`),
    'string': $(`<input type="text" class="form-element js-setting-edit" />`),
    'integer': $('<input type="number" class="form-element js-setting-edit" />'),
    'float': $('<input type="number" step="0.0001" class="form-element js-setting-edit" />'),
    'boolean': $(`<select class="form-element js-setting-edit">
                    <option value></option>
                    <option value="true">true</option>
                    <option value="false">false</option>
                  </select>`),
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

    const field = settingEditFields[valueType].clone()
                                              .attr('data-name', name)
                                              .attr('data-community-id', communityId)
                                              .get(0);

    if (valueType === 'array' && field instanceof HTMLSelectElement) {
      for (const opt of value) {
        const option = document.createElement('option');
        option.textContent = opt;
        option.value = opt;
        option.selected = true;
        field.add(option);
      }
    }
    else if (valueType === 'boolean') {
      field.value = value.toString();
    }
    else {
      field.value = !!value ? value.toString() : '';
    }

    $tgt.addClass('editing')
        .html(field)
        .append(`<button class="button is-primary is-filled js-setting-submit has-display-block">Update</button>`);

    if (valueType === 'array') {
      $(field).select2();
    }
  });

  $(document).on('click', '.js-setting-submit', async (evt) => {
    const $tgt = $(evt.target);
    const $td = $tgt.parent();
    const $input = $td.find('.js-setting-edit');
    const name = $input.data('name');
    const communityId = $input.data('community-id');
    const value = $input.val();

    const body = {
      site_setting: {
        value: Array.isArray(value) ? value.join(' ') : value
      }
    };

    if (!!communityId) {
      body.community_id = communityId;
    }

    const resp = await QPixel.fetchJSON(`/admin/settings/${name}`, body);

    const data = await resp.json();

    $td.removeClass('editing').html('').text(data.setting.typed.toString());
  });
});
