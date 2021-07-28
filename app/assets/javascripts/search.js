$(() => {
  let postTypes;
  const $itemTemplate = $('<a href="javascript:void(0)" class="item"></a>');

  $(document).on('keyup', 'input[name="search"]', async ev => {
    const $tgt = $(ev.target);
    const content = $tgt.val();
    const splat = content.split(' ');
    const caretPos = $tgt[0].selectionStart;
    const [currentWord, posInWord] = QPixel.currentCaretSequence(splat, caretPos);

    if (!currentWord.startsWith('post_type:')) {
      QPixel.removeTextareaPopups();
      return;
    }

    const callback = ev => {
      const $item = $(ev.target).hasClass('item') ? $(ev.target) : $(ev.target).parents('.item');
      const id = $item.data('post-type-id');
      $tgt[0].selectionStart = caretPos - posInWord;
      $tgt[0].selectionEnd = (caretPos - posInWord) + currentWord.length;
      QPixel.replaceSelection($tgt, `post_type:${id}`);
      $('.ta-popup').remove();
      $tgt.focus();
    };

    if (!postTypes) {
      const resp = await fetch(`/posts/types`, {
        method: 'GET',
        headers: {
          'Accept': 'application/json'
        }
      });
      postTypes = await resp.json();
    }

    QPixel.removeTextareaPopups();
    const items = postTypes.filter(pt => pt.name.startsWith(currentWord.substr(10))).map(pt => {
      return $itemTemplate.clone().text(pt.name).attr('data-post-type-id', pt.id);
    });
    QPixel.createTextareaPopup(items, $tgt[0], callback);
  });
});
