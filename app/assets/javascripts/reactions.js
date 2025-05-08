$(() => {
    $(".reaction-submit").on("click", async (e) => {
        e.preventDefault();
        const $this = $(e.target);
        const $rt = $this.parent().find('.reaction-type:checked');
        const $comment = $this.parent().find('.reaction-comment-field');
        const postId = $this.attr("data-post-id")

        if ($rt.length === 0) {
            QPixel.createNotification("danger", "You need to select a reaction type.");
            return;
        }

        if ($rt.is("[data-reaction-require-comment]") && !$comment.val()?.toString().trim().length) {
            QPixel.createNotification("danger", "This reaction type requires a comment with an explanation.");
            return;
        }

        const resp = await QPixel.fetchJSON('/posts/reactions/add', {
            reaction_id: $rt.val(),
            comment: $comment.val()?.toString()?.trim() || null,
            post_id: postId
        }, {
            headers: { 'Accept': 'application/json' }
        });

        const data = await resp.json();

        if (data.status === 'success') {
            window.location.reload();
        }
        else {
            QPixel.createNotification("danger", data.message);
        }
    });
    $(".reaction-retract").on("click", async (e) => {
        e.preventDefault();
        const $this = $(e.target);
        const postId = $this.attr("data-post")
        const reactionType = $this.attr("data-reaction");

        const resp = await QPixel.fetchJSON('/posts/reactions/retract', { reaction_id: reactionType, post_id: postId }, {
            headers: { 'Accept': 'application/json' }
        });

        const data = await resp.json();

        if (data.status === 'success') {
            window.location.reload();
        }
        else {
            QPixel.createNotification("danger", data.message);
        }
    });
});
