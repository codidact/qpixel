$(() => {
  const editField = $('<input type="number" class="form-element js-privilege-edit" />');

  $('.js-privilege-threshold').on('click', async evt => {
    const $tgt = $(evt.target);

    if ($tgt.hasClass('editing') || !$tgt.is('td')) {
      return;
    }

    const name = $tgt.data('name');
    const type = $tgt.data('type');

    const resp = await fetch(`/admin/privileges/${name}/${type}`, {
      credentials: 'include'
    });
    const data = await resp.json();
    const value = data.threshold;

    const form = editField.clone().val(value.toString()).attr('data-name', name).attr('data-type', type);
    $tgt.addClass('editing').html(form).append(`<button class="button is-filled js-privilege-submit">Update</button>`);
  });

  $(document).on('click', '.js-privilege-submit', async evt => {
    const $tgt = $(evt.target);
    const $td = $tgt.parent();
    const $input = $td.find('.js-privilege-edit');
    const name = $input.data('name');
    const type = $input.data('type');
    const value = $input.val();

    if(!value && value !== "0") { value = null }

    const resp = await fetch(`/admin/privileges/${name}/${type}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': QPixel.csrfToken() },
      body: JSON.stringify({threshold: value})
    });
    const data = await resp.json();

    $td.removeClass('editing').html('').text(data.privilege.threshold.toString());
  });
});