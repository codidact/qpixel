$(() => {
  $(".post--content pre > code")
    .parent()
    .each(function() {
      const content = $(this).text()
      $(this)
        .wrap('<div style="position:relative;"></div>')
        .parent()
        .prepend($('<button class="copy-button button is-muted is-outlined has-margin-2">Copy</button>')
          .click(function () {
            navigator.clipboard.writeText(content);
            $(this).text('Copied!');
            setTimeout(() => { $(this).text('Copy'); }, 2000);
          }))
  });
});