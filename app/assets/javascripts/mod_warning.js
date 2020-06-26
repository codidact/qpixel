$(function () {
    $(".js--warning-template-selection").on("input", (e) => {
        const $this = $(e.target);
        $(".js--warning-template-target textarea").val(atob($this.val()));
    });
})