$(() => {
  $(".post--content pre > code").each((_, block) => {
    const wrapper = block.parentElement;

    const wrapperDiv = document.createElement('div');
    wrapperDiv.style.position = 'relative';

    const copyButton = document.createElement('button');
    copyButton.style.position = 'absolute';
    copyButton.style.right = 0;
    copyButton.classList.add('copy-button', 'button', 'is-muted', 'is-outlined', 'has-margin-2');
    copyButton.innerText = 'Copy';
    copyButton.addEventListener('click', _ => {
      navigator.clipboard.writeText(block.innerText);
      copyButton.innerText = 'Copied!';
      setTimeout(() => {
        copyButton.innerText = 'Copy';
      }, 2000);
    });

    wrapper.insertAdjacentElement('beforebegin', wrapperDiv);
    wrapperDiv.append(copyButton, wrapper);
  });
});