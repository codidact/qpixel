$(() => {
  $(document).on('click', '.js-tag-set-name', async (ev) => {
    const $tgt = $(ev.target);
    const tagSetId = $tgt.data('set-id');

    const resp = await QPixel.getJSON(`/admin/tag-sets/${tagSetId}`);

    const data = await resp.json();

    const name = data.name;
    const $form = `<input type="text" class="js-edit-set-name form-element" value="${name}" />
                   <input type="button" class="js-edit-name-submit button is-filled" data-set-id="${tagSetId}" value="Update" />`;
    $tgt.html($form);
  });

  $(document).on('click', '.js-edit-set-name, .js-edit-name-submit', (ev) => {
    ev.stopPropagation();
  });

  $(document).on('click', '.js-edit-name-submit', async (ev) => {
    const $tgt = $(ev.target);
    const tagSetId = $tgt.data('set-id');
    const $name = $tgt.parents('.js-tag-set-name');
    const newName = $tgt.parent().children('.js-edit-set-name').val();

    const response = await QPixel.fetchJSON(`/admin/tag-sets/${tagSetId}/edit`, { name: newName }, {
      headers: { 'Accept': 'application/json' }
    });

    const data = await response.json();

    QPixel.handleJSONResponse(data, (data) => {
      $name.text(data.tag_set.name);
    });
  });
});
