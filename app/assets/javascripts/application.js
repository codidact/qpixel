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

window.QPixel = {
  csrfToken: () => {
    const token = $('meta[name="csrf-token"]').attr('content');
    QPixel.csrfToken = () => token;
    return token;
  },

  createNotification: function(type, message, relativeElement) {
    $("<div></div>")
      .addClass("notice has-shadow-3 is-" + type)
      .html('<button type="button" class="button is-close-button" data-dismiss="alert" aria-label="Close"><span aria-hidden="true">&times;</span></button><p>' + message+"</p>")
      .css({
        'position': 'fixed',
        'top': "50px",
        'left': "50%",
        'transform': "translateX(-50%)",
        'z-index': 100,
        'width': '100%',
        'max-width': "800px",
        'cursor': 'pointer'
      })
      .on('click', function(ev) {
        $(this).fadeOut(200, function() {
          $(this).remove();
        });
      })
      .appendTo(document.body);
  },

  offset: function(el) {
    const topLeft = $(el).offset();
    return {
      top: topLeft.top,
      left: topLeft.left,
      bottom: topLeft.top + $(el).outerHeight(),
      right: topLeft.left + $(el).outerWidth()
    };
  }
};

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
      QPixel.createNotification('danger', "Please enter at least 10 characters.", self);
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
        QPixel.createNotification('danger', '<strong>Failed:</strong> ' + response.message, this);
      }
      else {
        QPixel.createNotification('success', '<strong>Thanks!</strong> A moderator will review your flag.', this);
        self.parents(".js-flag-box").find(".js-flag-comment").val("");
      }
      self.parents(".js-flag-box").removeClass("is-active");
    })
    .fail((jqXHR, textStatus, errorThrown) => {
      QPixel.createNotification('danger', '<strong>Failed:</strong> ' + jqXHR.status, this);
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
        QPixel.createNotification('danger', '<strong>Failed:</strong> ' + response.message, ev.target);
      }
      else {
        location.reload();
      }
    })
    .fail((jqXHR, textStatus, errorThrown) => {
      QPixel.createNotification('danger', '<strong>Failed:</strong> ' + jqXHR.status, ev.target);
      console.log(jqXHR.responseText);
    });
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
        QPixel.createNotification('danger', "<strong>Failed:</strong> " + response['message'], this.el);
      }
      else {
        $(this.el).parent().parent().parent().fadeOut(200, function() {
          $(this).remove();
        });
      }
    })
    .fail(function(jqXHR, textStatus, errorThrown) {
      QPixel.createNotification('danger', "<strong>Failed:</strong> " + jqXHR.status, this.el);
      console.log(jqXHR.responseText);
    });
  });


  $('.js-first-visit-notice').on('close.bs.alert', async () => {
    document.cookie = 'dismiss_fvn=true; path=/; expires=Fri, 31 Dec 9999 23:59:59 GMT';
  });
});
