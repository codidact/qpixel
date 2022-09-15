$(() => {
  $('.js-filter-select').each((_, el) => {
    const $select = $(el);
    const $form = $select.closest('form');
    const $saveButton = $form.find('.filter-save');
    const $deleteButton = $form.find('.filter-delete');

    async function initializeSelect() {
      const filters = await QPixel.filters();

      function template(option) {
        if (option.id == '') { return 'None'; }

        const filter = filters[option.id];
        const name = `<span>${option.text}</span>`;
        const systemIndicator = filter?.system
          ? ' <span has-font-size-caption">(System)</span>'
          : '';
        const newIndicator = !filter
          ? ' <span has-font-size-caption">(New)</span>'
          : '';
        return $(name + systemIndicator + newIndicator);
      }

      // Clear out any old options
      $select.children().filter((_, option) => !filters[option.value]).detach();
      $select.select2({
        data: Object.keys(filters),
        tags: true,

        templateResult: template,
        templateSelection: template
      }).on('select2:select', evt => {
        const filterName = evt.params.data.id;
        const preset = filters[filterName];

        // Name is not one of the presets, i.e user is creating a new preset
        if (!preset) {
          $saveButton.prop('disabled', false);
          $deleteButton.prop('disabled', true);
          return;
        }
        $saveButton.prop('disabled', true);
        $deleteButton.prop('disabled', preset.system);

        for (const [name, value] of Object.entries(preset)) {
          $form.find(`.form--filter[name=${name}]`).val(value);
        }
      });
      $saveButton.prop('disabled', true);
      $deleteButton.prop('disabled', true);
    }

    initializeSelect();

    // Enable saving when the filter is changed
    $form.find('.form--filter').on('change', _ => {
      $saveButton.prop('disabled', false);
    });

    $saveButton.on('click', async evt => {
      if (!$form[0].reportValidity()) { return; }

      const filter = {};

      for (const el of $('.form--filter')) {
        filter[el.name] = el.value;
      }

      await QPixel.setFilter($select.val(), filter);
      // Reinitialize to get new options
      await initializeSelect();
      $saveButton.prop('disabled', true);
      $deleteButton.prop('disabled', false);
    });

    $deleteButton?.on('click', async evt => {
      if (confirm(`Are you sure you want to delete ${$select.val()}?`)) {
        await QPixel.deleteFilter($select.val());
        // Reinitialize to get new options
        await initializeSelect();
        $saveButton.prop('disabled', true);
        $deleteButton.prop('disabled', true);
      }
    });

    $form.find('.filter-clear').on('click', _ => {
      $select.val(null).trigger('change');
      $form.find('.form--filter').val(null).trigger('change');
      $saveButton.prop('disabled', true);
      $deleteButton.prop('disabled', true);
    });
  });
});