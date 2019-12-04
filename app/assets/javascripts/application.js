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
//= require jquery_ujs
//= require_tree .

window.QPixel = {
  csrfToken: () => {
    const token = $('meta[name="csrf-token"]').attr('content');
    QPixel.csrfToken = () => token;
    return token;
  },

  createNotification: function(type, message, relativeElement) {
    const offset = QPixel.offset(relativeElement);
    $("<div></div>")
      .addClass("alert alert-dismissible alert-" + type)
      .html('<button type="button" class="close" data-dismiss="alert" aria-label="Close"><span aria-hidden="true">&times;</span></button>' + message)
      .css({
        'position': 'absolute',
        'top': offset.bottom,
        'left': offset.right,
        'z-index': 100,
        'max-width': '400px',
        'box-shadow': '0 0 10px 2px #aaa',
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
  $("a.flag-link").bind("click", function(ev) {
    ev.preventDefault();
    var self = $(this);
    var data = {
      'post_id': self.data("post-id"),
      'reason': window.prompt("Why does this post require moderator attention?")
    };

    if(data['reason'].length < 10) {
      QPixel.createNotification('danger', "Please enter at least 10 characters.", self);
      return;
    }

    $.ajax({
      'type': 'POST',
      'url': '/flags/new',
      'data': data,
      'target': self
    })
    .done(function(response) {
      if(response['status'] !== 'success') {
        QPixel.createNotification('danger', '<strong>Failed:</strong> ' + response['message'], this.target);
      }
      else {
        QPixel.createNotification('info', '<strong>Thanks!</strong> A moderator will review your flag.', this.target);
      }
    })
    .fail(function(jqXHR, textStatus, errorThrown) {
      QPixel.createNotification('danger', '<strong>Failed:</strong> ' + jqXHR.status, this.target);
      console.log(jqXHR.responseText);
    });
  });

  $("a.flag-resolve").bind("click", function(ev) {
    ev.preventDefault();
    var self = $(this);
    var id = self.data("flag-id");
    var data = {
      'result': self.data("result"),
      'message': window.prompt("Add some optional feedback on this flag:")
    }

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
        $(this.el).parent().parent().fadeOut(200, function() {
          $(this).remove();
        });
      }
    })
    .fail(function(jqXHR, textStatus, errorThrown) {
      QPixel.createNotification('danger', "<strong>Failed:</strong> " + jqXHR.status, this.el);
      console.log(jqXHR.responseText);
    });
  });

});
