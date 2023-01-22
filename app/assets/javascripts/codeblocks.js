$(() => {
  $(".post--content pre").each((_, block) => {
    const copyButton = document.createElement('button');
    copyButton.classList.add('button', 'is-muted', 'is-outlined', 'has-float-right');
    copyButton.innerText = 'Copy';
    copyButton.addEventListener('click', _ => {
      navigator.clipboard.writeText(block.innerText);
      copyButton.innerText = 'Copied!';
      setTimeout(() => {
        copyButton.innerText = 'Copy';
      }, 2000);
    });

    block.insertAdjacentElement('afterbegin', copyButton);
  });
});