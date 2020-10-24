// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or any plugin's vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require chartkick
//= require Chart.bundle
//= require jquery_ujs
//= require_tree .

$(document).on('ready', function() {
  $("a.flag-dialog-link").bind("click", (ev) => {
    ev.preventDefault();
    const self = $(ev.target);
    self.parents(".post--body").find(".js-flag-box").toggleClass("is-active");
  });
  $("button.flag-link").bind("click", (ev) => {
    ev.preventDefault();
    const self = $(ev.target);
    const data = {
      'post_id': self.data("post-id"),
      'reason': self.parents(".js-flag-box").find(".js-flag-comment").val()
    };

    if (data['reason'].length < 10) {
      QPixel.createNotification('danger', "Please enter at least 10 characters.");
      return;
    }

    $.ajax({
      'type': 'POST',
      'url': '/flags/new',
      'data': data,
      'target': self
    })
    .done((response) => {
      if(response.status !== 'success') {
        QPixel.createNotification('danger', '<strong>Failed:</strong> ' + response.message);
      }
      else {
        QPixel.createNotification('success', '<strong>Thanks!</strong> A moderator will review your flag.');
        self.parents(".js-flag-box").find(".js-flag-comment").val("");
      }
      self.parents(".js-flag-box").removeClass("is-active");
    })
    .fail((jqXHR, textStatus, errorThrown) => {
      QPixel.createNotification('danger', '<strong>Failed:</strong> ' + jqXHR.status);
      console.log(jqXHR.responseText);
      self.parents(".js-flag-box").removeClass("is-active");
    });
  });

  $("a.close-dialog-link").on("click", (ev) => {
    ev.preventDefault();
    const self = $(ev.target);
    console.log(self.parents(".post--body").find(".js-close-box").toggleClass("is-active"));
  });
  $("button.close-question").on("click", (ev) => {
    ev.preventDefault();
    const self = $(ev.target);
    active_radio = self.parents(".js-close-box").find("input[type='radio'][name='close-reason']:checked");
    const data = {
      'reason_id': active_radio.val(),
      'other_post': active_radio.parents(".widget--body").find(".js-close-other-post").val()
      // option will be silently discarded if no input element
    };

    if (data["other_post"]) {
      if (data["other_post"].match(/\/[0-9]+$/)) {
        data["other_post"] = data["other_post"].replace(/.*\/([0-9]+)$/, "$1");
      }
    }

    $.ajax({
      'type': 'POST',
      'url': '/questions/' + self.data("post-id") + '/close',
      'data': data,
      'target': self
    })
    .done((response) => {
      if(response.status !== 'success') {
        QPixel.createNotification('danger', '<strong>Failed:</strong> ' + response.message);
      }
      else {
        location.reload();
      }
    })
    .fail((jqXHR, textStatus, errorThrown) => {
      QPixel.createNotification('danger', '<strong>Failed:</strong> ' + jqXHR.status);
      console.log(jqXHR.responseText);
    });
  });

  $("a.show-all-flags-dialog-link").bind("click", (ev) => {
    ev.preventDefault();
    const self = $(ev.target);
    self.parents(".post--body").find(".js-flags").toggleClass("is-active");
  });

  $("a.flag-resolve").bind("click", function(ev) {
    ev.preventDefault();
    var self = $(this);
    var id = self.data("flag-id");
    var data = {
      'result': self.data("result"),
      'message': self.parent().parent().find(".flag-resolve-comment").val()
    };

    $.ajax({
      'type': 'POST',
      'url': '/mod/flags/' + id + '/resolve',
      'data': data,
      'el': self
    })
    .done(function(response) {
      if(response['status'] !== 'success') {
        QPixel.createNotification('danger', "<strong>Failed:</strong> " + response['message']);
      }
      else {
        $(this.el).parent().parent().parent().fadeOut(200, function() {
          $(this).remove();
        });
      }
    })
    .fail(function(jqXHR, textStatus, errorThrown) {
      QPixel.createNotification('danger', "<strong>Failed:</strong> " + jqXHR.status);
      console.log(jqXHR.responseText);
    });
  });


  document.getElementById("fvn-dismiss").onclick = function() {
    document.cookie = 'dismiss_fvn=true; path=/; expires=Fri, 31 Dec 9999 23:59:59 GMT';
  };
});
