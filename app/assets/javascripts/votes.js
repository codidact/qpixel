$(() => {
  $(document).on('click', '.vote-button', async evt => {
    const $tgt = $(evt.target);
    const $post = $tgt.parents('.post-container');
    const $score = $post.find('.post-score');
    const voteType = $tgt.data('vote-type');
    const voted = $tgt.hasClass('voted');

    if (voted) {
      console.log($tgt, $tgt.data('vote-id'));
      const voteId = $tgt.data('vote-id');
      const resp = await fetch(`/votes/${voteId}`, {
        method: 'DELETE',
        credentials: 'include',
        headers: { 'X-CSRF-Token': QPixel.csrfToken() }
      });
      const data = await resp.json();
      if (data.status === 'OK') {
        $score.text(data.post_score);
        $tgt.attr('src', voteType === 1 ? '/assets/up-clear.png' : '/assets/down-clear.png')
            .removeClass('voted')
            .removeAttr('data-vote-id');
      }
      else {
        console.error('Vote delete failed');
        console.log(resp);
        QPixel.createNotification('danger', `<strong>Failed:</strong> ${(await resp.text())} (${resp.status})`);
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
        $score.text(data.post_score);
        $tgt.attr('src', voteType === 1 ? '/assets/up-fill.png' : '/assets/down-fill.png')
            .addClass('voted')
            .attr('data-vote-id', data.vote_id);

        if (data.status === 'modified') {
          const $oppositeVote = $post.find(`.vote-button[data-vote-type="${-1 * voteType}"]`);
          $oppositeVote.attr('src', voteType === 1 ? '/assets/down-clear.png' : '/assets/up-clear.png')
                       .removeClass('voted')
                       .removeAttr('data-vote-id');
        }
      }
      else {
        console.error('Vote create failed');
        console.log(resp);
        QPixel.createNotification('danger', `<strong>Failed:</strong> ${(await resp.text())} (${resp.status})`);
      }
    }
  });
});
