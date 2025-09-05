$(() => {
  $('.js-filter-select').toArray().forEach(async (el) => {
    const $select = $(el);
    const $form = $select.closest('form');
    const $formFilters = $form.find('.form--filter');
    const $saveButton = $form.find('.filter-save');
    const $isDefaultCheckbox = $form.find('.filter-is-default');
    const categoryId = $isDefaultCheckbox.val()?.toString();
    let defaultFilter = await QPixel.defaultFilter(categoryId);
    const $deleteButton = $form.find('.filter-delete');

    // Enables/Disables Save & Delete buttons programatically
    async function computeEnables() {
      const filters = await QPixel.filters();
      const filterName = $select.val()?.toString();

      // Nothing set
      if (!filterName) {
        $saveButton.prop('disabled', true);
        $deleteButton.prop('disabled', true);
        return;
      }

      const filter = filters[filterName]

      // New filter
      if (!filter) {
        $saveButton.prop('disabled', false);
        $deleteButton.prop('disabled', true);
        return;
      }

      // Not a new filter
      $deleteButton.prop('disabled', filter.system);

      const hasChanges = [...$formFilters].some((el) => {
        const filterValue = filter[el.dataset.name];
        let elValue = /** @type {string | undefined[]} */ ($(el).val());
        if (filterValue?.constructor == Array) {
          elValue = elValue ?? [];
          return filterValue.length != elValue.length || filterValue.some((v, i) => v[1] != elValue[i]);
        }
        else {
          return filterValue ? filterValue != elValue : elValue;
        }
      });
      const defaultStatusChanged = $isDefaultCheckbox.prop('checked') != (defaultFilter === $select.val());
      $saveButton.prop('disabled', !defaultStatusChanged && (filter.system || !hasChanges));
    }

    async function initializeSelect() {
      defaultFilter = await QPixel.defaultFilter(categoryId);
      $isDefaultCheckbox.prop('checked', defaultFilter === $select.val());
      const filters = await QPixel.filters();

      function template(option) {
        if (option.id == '') { return 'Default'; }

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
      $select.children().filter((_, /** @type{HTMLOptionElement} */ option) => {
        return option.value && !filters[option.value];
      }).detach();

      $select.select2({
        data: Object.keys(filters).map((filterName) => {
          return {
            id: filterName,
            text: filterName
          }
        }),
        tags: true,
        templateResult: template,
        templateSelection: template
      });

      $select.on('select2:select', /** @type {(event: Select2.Event) => void} */ (async (evt) => {
        const filterName = evt.params.data.id;
        const preset = filters[filterName];

        $isDefaultCheckbox.prop('checked', defaultFilter === $select.val());
        computeEnables();

        // Name is not one of the presets, i.e user is creating a new preset
        if (!preset) {
          return;
        }

        for (const [name, value] of Object.entries(preset)) {
          const $el = $form.find(`.form--filter[data-name=${name}]`);
          if (value?.constructor == Array) {
            $el.val(null);
            for (const val of value) {
              $el.append(new Option(val[0], val[1].toString(), false, true));
            }
            $el.trigger('change');
          }
          else {
            $el.val(/** @type {string} */ (value)).trigger('change');
          }
        }
      }));
      computeEnables();
    }

    initializeSelect();

    // Enable saving when the filter is changed
    $formFilters.on('change', computeEnables);
    $isDefaultCheckbox.on('change', computeEnables);

    async function saveFilter() {
      if (!$form[0].reportValidity()) { return; }

      const filter = /** @type {QPixelFilter} */({});

      for (const el of $formFilters) {
        filter[el.dataset.name] = $(el).val();
      }

      await QPixel.setFilter($select.val()?.toString(), filter, categoryId, $isDefaultCheckbox.prop('checked'));
      defaultFilter = await QPixel.defaultFilter(categoryId);

      // Reinitialize to get new options
      await initializeSelect();
    }

    $saveButton.on('click', saveFilter);

    function clear() {
      $select.val(null).trigger('change');
      $form.find('.form--filter').val(null).trigger('change');
      $isDefaultCheckbox.prop('checked', false);
      computeEnables();
    }

    $deleteButton?.on('click', async (_evt) => {
      if (confirm(`Are you sure you want to delete ${$select.val()}?`)) {
        await QPixel.deleteFilter($select.val()?.toString());
        // Reinitialize to get new options
        await initializeSelect();
        clear();
      }
    });

    $form.find('.filter-clear').on('click', clear);
  });
});
