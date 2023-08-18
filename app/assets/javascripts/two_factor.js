$(() => {
   $('.js-backup-code-form').on('submit', async ev => {
      ev.preventDefault();
      const $tgt = $(ev.target);
      const $input = $tgt.find('input[name="code"]');
      const code = $input.val();
      const req = await fetch('/users/two-factor/backup', {
          method: 'POST',
          headers: {
              'X-CSRF-Token': QPixel.csrfToken(),
              'Content-Type': 'application/json'
          },
          body: JSON.stringify({ code })
      });
      const res = await req.json();

      if (res.status === 'error') {
          const $label = $tgt.find('label[for="code"]');
          $label.text(res.message);
          $input.addClass('is-danger');
          $tgt.find('input[type="submit"]').removeAttr('disabled');
      }
      else if (res.status === 'success') {
        const codeForm = $(`<details>
                              <summary>Show code</summary>
                              <label for="backup-code" class="form-element">2FA backup code</label>
                              <input class="form-element" type="text" readonly name="backup-code" id="backup-code" value="${res.code}" />
                            </details>`);
        $tgt.after(codeForm);
        $tgt.remove();
      }
   });
});
