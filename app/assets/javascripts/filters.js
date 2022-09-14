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

        for (const [name, value] of Object.entries(preset)) {
          $form.find(`.form--filter[name=${name}]`).val(value);
        }
      });

      // Clear the preset when the user enters in a filter manually
      $form.find('.form--filter').each((i, filter) => {
        $(filter).on('change', _ => {
          $tgt.val(null).trigger('change');
        });
      });

      $('.filter-save').on('click', evt => {
        const filter = {};

        for (const el of $('.form--filter')) {
          filter[el.name] = el.value;
        }
        QPixel.setFilter($tgt.val(), filter)
      });
    });
  });
  $('.filter-clear').on('click', evt => {
    const $tgt = $(evt.target);
    const $form = $tgt.closest('form');

    $form.find('.form--filter').val(null).trigger('change');
  });
});