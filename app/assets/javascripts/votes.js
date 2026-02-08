document.addEventListener('DOMContentLoaded', () => {
  $(document).on('click', '.vote-button', async (evt) => {
    const $tgt = $(evt.target).is('button') ? $(evt.target) : $(evt.target).parents('button');
    const $post = $tgt.parents('.post');

    const $container = $post.find(".post--votes");

    const $up = $container.find('.js-upvote-count');
    const $down = $container.find('.js-downvote-count');
    const postId = $post.data('post-id');
    const voteType = $tgt.data('vote-type');
    const voted = $tgt.hasClass('is-active');

    if (voted) {
      const voteId = $tgt.attr('data-vote-id');

      const data = await QPixel.retractVote(voteId);

      QPixel.handleJSONResponse(data, (data) => {
        $up.text(`+${data.upvotes}`);
        $down.html(`&minus;${data.downvotes}`);
        $container.attr("title", `Score: ${data.score}`);
        $tgt.removeClass('is-active')
            .removeAttr('data-vote-id');
      });
    }
    else {
      const data = await QPixel.vote(postId, voteType);

      QPixel.handleJSONResponse(data, (data) => {
        $up.text(`+${data.upvotes}`);
        $down.html(`&minus;${data.downvotes}`);
        $container.attr("title", `Score: ${data.score}`);
        $tgt.addClass('is-active')
            .attr('data-vote-id', data.vote_id);

        if (data.status === 'modified') {
          const $oppositeVote = $post.find(`.vote-button[data-vote-type="${-1 * voteType}"]`);
          $oppositeVote.removeClass('is-active')
                       .removeAttr('data-vote-id');
        }
      });
    }
  });
});
