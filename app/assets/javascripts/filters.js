$(() => {
  const predefined = {
    'Positive': {
      'score-min': 0.5,
      'score-max': 1
    },
    'Unanswered': {
      'answers-min': 0,
      'answers-max': 0
    }
  };

  $('.js-filter-select').each((i, el) => {
    const $tgt = $(el);
    const $form = $tgt.closest('form');

    $tgt.select2({
      data: Object.keys(predefined),
    }).on('select2:select', evt => {
      const filterName = evt.params.data.id;
      const preset = predefined[filterName];

      for (const [name, value] of Object.entries(preset)) {
        $form.find(`.filter-${name}`).val(value);
      }
    });

    // Clear the preset when the user enters in a filter manually
    $form.find('.form--filter').each((i, filter) => {
      $(filter).on('change', _ => {
        $tgt.val(null).trigger('change');
      });
    });
  });

  $('.filter-clear').on('click', evt => {
    const $tgt = $(evt.target);
    const $form = $tgt.closest('form');

    $form.find('.form--filter').val(null).trigger('change');
  });
});