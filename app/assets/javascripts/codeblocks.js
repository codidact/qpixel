$(() => {
  $(".post--content pre").each((_, block) => {
    const copyButton = document.createElement('button');
    copyButton.innerText = 'Copy';
    copyButton.addEventListener('click', _ => {
      navigator.clipboard.writeText(block.innerText);
    });

    block.insertAdjacentElement('afterend', copyButton);
  });
});