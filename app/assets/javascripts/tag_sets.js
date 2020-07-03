$(() => {
  $(document).on('click', '.js-tag-set-name', async ev => {
    const $tgt = $(ev.target);
    const tagSetId = $tgt.data('set-id');
    const response = await fetch(`/admin/tag-sets/${tagSetId}`, {
      headers: {
        'Accept': 'application/json'
      }
    });
    const data = await response.json();
    const name = data.name;
    const $form = `<input type="text" class="js-edit-set-name form-element" value="${name}" />
                   <input type="button" class="js-edit-name-submit button is-filled" data-set-id="${tagSetId}" value="Update" />`;
    $tgt.html($form);
  });

  $(document).on('click', '.js-edit-set-name, .js-edit-name-submit', ev => {
    ev.stopPropagation();
  });

  $(document).on('click', '.js-edit-name-submit', async ev => {
    const $tgt = $(ev.target);
    console.log($tgt);
    const tagSetId = $tgt.data('set-id');
    const $name = $tgt.parents('.js-tag-set-name');
    const newName = $tgt.parent().children('.js-edit-set-name').val();
    const response = await fetch(`/admin/tag-sets/${tagSetId}/edit`, {
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'X-CSRF-Token': QPixel.csrfToken()
      },
      method: 'POST',
      body: JSON.stringify({ name: newName })
    });
    const data = await response.json();

    if (data.status === 'success') {
      $name.text(data.tag_set.name);
    }
    else {
      QPixel.createNotification('danger', `Failed to change name (${response.status})`);
    }
  });
});