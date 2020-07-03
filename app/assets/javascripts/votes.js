$(() => {
  $(document).on('click', '.vote-button', async evt => {
    const $tgt = $(evt.target).is('button') ? $(evt.target) : $(evt.target).parents('button');
    const $post = $tgt.parents('.post');
    const $up = $post.find('.post--votes').find('.js-upvote-count');
    const $down = $post.find('.post--votes').find('.js-downvote-count');
    const voteType = $tgt.data('vote-type');
    const voted = $tgt.hasClass('is-active');

    if (voted) {
      const voteId = $tgt.attr('data-vote-id');
      const resp = await fetch(`/votes/${voteId}`, {
        method: 'DELETE',
        credentials: 'include',
        headers: { 'X-CSRF-Token': QPixel.csrfToken() }
      });
      const data = await resp.json();
      if (data.status === 'OK') {
        $up.text(`+${data.upvotes}`);
        $down.html(`&minus;${data.downvotes}`);
        $tgt.removeClass('is-active')
            .removeAttr('data-vote-id');
      }
      else {
        console.error('Vote delete failed');
        console.log(resp);
        QPixel.createNotification('danger', `<strong>Failed:</strong> ${data.message} (${resp.status})`);
      }
    }
    else {
      const resp = await fetch('/votes/new', {
        method: 'POST',
        credentials: 'include',
        headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': QPixel.csrfToken() },
        body: JSON.stringify({post_id: $post.data('post-id'), vote_type: voteType})
      });
      const data = await resp.json();
      if (data.status === 'modified' || data.status === 'OK') {
        $up.text(`+${data.upvotes}`);
        $down.html(`&minus;${data.downvotes}`);
        $tgt.addClass('is-active')
            .attr('data-vote-id', data.vote_id);

        if (data.status === 'modified') {
          const $oppositeVote = $post.find(`.vote-button[data-vote-type="${-1 * voteType}"]`);
          $oppositeVote.removeClass('is-active')
                       .removeAttr('data-vote-id');
        }
      }
      else {
        console.error('Vote create failed');
        console.log(resp);
        QPixel.createNotification('danger', `<strong>Failed:</strong> ${data.message} (${resp.status})`);
      }
    }
  });
});
