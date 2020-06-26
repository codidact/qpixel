$(function () {
    $(".js--warning-template-selection").on("input", (e) => {
        $this = $(e.target);
        $(".js--warning-template-target textarea").val(atob($this.val()));
    });
})