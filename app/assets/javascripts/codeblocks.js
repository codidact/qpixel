document.addEventListener('DOMContentLoaded', () => {
  const buttonTemplate = `<button class="copy-button button is-muted is-outlined has-margin-2">Copy</button>`;

  $('.post--content pre > code')
    .parent()
    .each(function () {
      const $button = $(buttonTemplate);
      const $content = $(this).text();
      const numLines = $content.trim().split(/\r?\n/).length;

      if (numLines <= 1) {
        $button.addClass('is-small');
      }

      $(this)
        .wrap('<div style="position:relative;"></div>')
        .parent()
        .prepend(
          $button.click(function () {
            navigator.clipboard.writeText($content);
            $(this).text('Copied!');
            setTimeout(() => {
              $(this).text('Copy');
            }, 2000);
          }),
        );
    });
});

