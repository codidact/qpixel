const tour = {
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
        window.setTimeout(() => {
            tour.secondAnswer();
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
        $(".tour-flag-success").removeClass("hide");
        $(".js-flag-box").addClass("hide");
        
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
        window.setTimeout(() => {
            tour.firstAnswer();
        }, 8000);
    }

    $("[data-step-from][data-step-to]").click((e) => {
        $this = $(e.target);
        $($this.attr("data-step-from")).toggleClass("hide");
        $($this.attr("data-step-to")).toggleClass("hide");
    });
});