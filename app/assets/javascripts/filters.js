$(() => {
  QPixel.filters().then(filters => {
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

    $('.js-filter-select').each((i, el) => {
      const $tgt = $(el);
      const $form = $tgt.closest('form');
      const $saveButton = $('.filter-save');

      $tgt.select2({
        data: Object.keys(filters),
        tags: true,

        templateResult: template,
        templateSelection: template
      }).on('select2:select', evt => {
        const filterName = evt.params.data.id;
        const preset = filters[filterName];

        // Name is not one of the presets, i.e user is creating a new preset
        if (!preset) { return; }

        $saveButton.prop('disabled', true);

        for (const [name, value] of Object.entries(preset)) {
          $form.find(`.form--filter[name=${name}]`).val(value);
        }
      });

      // Enable saving when the filter is changed
      $form.find('.form--filter').each((i, filter) => {
        $(filter).on('change', _ => {
          $saveButton.prop('disabled', false);
        });
      });

      $saveButton.on('click', async evt => {
        if (!$form[0].reportValidity()) {
          return;
        }

        const filter = {};

        for (const el of $('.form--filter')) {
          filter[el.name] = el.value;
        }
        await QPixel.setFilter($tgt.val(), filter);
        $saveButton.prop('disabled', true);
      });

      $form.find('.filter-clear').on('click', _ => {
        $tgt.val(null).trigger('change');
        $form.find('.form--filter').val(null).trigger('change');
      });
    });
  });
});