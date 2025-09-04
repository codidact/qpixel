const tour = {
    badAnswerTimeout: null,
    firstAnswerTimeout: null,

    firstAnswer: function () {
        $(".js-good-answer").removeClass("hide");
        $(".js-answer-counter").text("1 answer");
        $(".step-1").addClass("hide");
        $(".step-2").removeClass("hide");
    },
    firstAnswerUpvote: function (self) {
        $(self).addClass("is-active");
        $(".step-3").addClass("hide");
        $(".step-4").removeClass("hide");
        $(".js-good-answer .js-upvote-count").text("+1");
        $(".js-good-answer .js-upvote-count").text("+1");

        tour.badAnswerTimeout = window.setTimeout(() => {
            tour.secondAnswer();
            tour.badAnswerTimeout = null;
        }, 4000);
    },
    secondAnswer: function () {
        $(".js-bad-answer").removeClass("hide");
        $(".js-answer-counter").text("2 answers");
        $(".step-4").addClass("hide");
        $(".step-5").removeClass("hide");
    },
    secondAnswerFlag: function () {
        $(".step-5").addClass("hide");
        $(".step-6").removeClass("hide");
        $(".js-flag-box").addClass("hide");

        QPixel.createNotification('success', "Thanks for your report. We'll look into it.");
        
        window.setTimeout(() => {
            $(".js-answer-counter").text("1 answer");
            $(".js-bad-answer").addClass("deleted-content");
        }, 4000);

        window.setTimeout(() => {
            $(".js-bad-answer").addClass("hide");
        }, 6000);
    }
}

$(() => {
    if ($(".js-tour-trigger-qa-page").length) {
        tour.firstAnswerTimeout = window.setTimeout(() => {
            tour.firstAnswer();
            tour.firstAnswerTimeout = null;
        }, 8000);
    }

    $(document).on('click', '.js-tour-scroll-to-post', (ev) => {
        const post = $(ev.target).data('post');

        switch (post) {
            case 'bad-answer':
                $('.js-bad-answer').get(0)?.scrollIntoView({ behavior: 'smooth' });
                break;
            case 'first-answer':
                $('.step-3').removeClass('hide');
                $('.step-2').addClass('hide');
                $('.js-good-answer').get(0)?.scrollIntoView({ behavior: 'smooth' });
                break;
        }
    });

    $(document).on('click', '.js-tour-skip-wait', (ev) => {
        const timeout = $(ev.target).data('timeout');

        switch (timeout) {
            case 'bad-answer':
                clearTimeout(tour.badAnswerTimeout);
                tour.badAnswerTimeout = null;
                tour.secondAnswer();
                break;
            case 'first-answer':
                clearTimeout(tour.firstAnswerTimeout);
                tour.firstAnswerTimeout = null;
                tour.firstAnswer();
                break;
        }
    });

    $("[data-step-from][data-step-to]").click((e) => {
        const $this = $(e.target);
        $($this.attr("data-step-from")).toggleClass("hide");
        $($this.attr("data-step-to")).toggleClass("hide");
    });
});
