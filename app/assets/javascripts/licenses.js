$(() => {
  $('.js-license-autofill').on('click', ev => {
    const $tgt = $(ev.target);
    const $input = $tgt.parents('.form-group').find('select');
    const licenseId = $tgt.attr('data-license-id');
    const licenseName = $tgt.attr('data-license-name');
    if (!!licenseId) {
      $input.val(licenseId).trigger('change');
    }
    else {
      const option = $input.find('option').toArray().filter(o => $(o).text() === licenseName)[0];
      $input.val($(option).attr('value')).trigger('change');
    }
  });

  $('.js-license-select').select2({
    templateResult: option => {
      if (option.element) {
        const title = $(option.element).attr('data-title');
        const description = !!title ? title :
          "You've opted to be required to choose a license explicitly for every post."
        return $(`<div>
                    ${option.text}<br/>
                    <span class="has-font-size-caption has-color-tertiary-600">
                      ${description}
                    </span>
                  </div>`);
      }
      else {
        return option.text;
      }
    }
  });
});