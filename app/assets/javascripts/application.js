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
//= require jquery
//= require jquery_ujs
//= require turbolinks
//= require_tree .

$(document).on('ready page:load', function() {

  $(".vote-button").bind("click", function(ev) {
    ev.preventDefault();
    var self = $(this);

    // Vote data is stored on the element as "VoteType/PostId/PostType/VoteId".
    var vote = self.data("vote");
    var voteSplat = vote.split("/");
    var state = {
      voteType: voteSplat[0],
      postId: voteSplat[1],
      postType: voteSplat[2],
      voteId: voteSplat[3],
      target: self
    };

    console.log(state);

    if(state.voteId > -1) {
      // We've already voted; cancel the vote.
      console.log("deleting vote");
      $.ajax({
        'url': '/votes/' + state.voteId,
        'type': 'DELETE',
        'state': state
      })
      .done(function(data) {
        if(data['status'] === "OK") {
          $(this.state.target).attr('src', '/assets/' + (this.state.voteType == '1' ? 'up' : 'down') + '-clear.png');
          $(this.state.target).data('vote', this.state.voteType + '/' + this.state.postId + '/' + this.state.postType + '/-1');
          $(this.state.target).parent().siblings('.post-score').text(data['post_score']);
        }
        else {
          alert("Could not undo vote - please try again. Message: " + data);
          console.error("Vote undo failed: " + data);
        }
      })
      .fail(function(jqXHR, textStatus, errorThrown) {
        alert("Could not undo vote - please try again. Message: " + jqXHR.reponseText);
        console.error("Vote undo failed: status " + jqXHR.status);
        console.log(jqXHR);
      });
    }
    else {
      // We have yet to vote, so cast one.
      console.log("creating vote");
      $.ajax({
        'url': '/votes/new',
        'type': 'POST',
        'data': {
          'post_type': state.postType,
          'post_id': state.postId,
          'vote_type': state.voteType
        },
        'state': state
      })
      .done(function(data) {
        if(data['status'] == "OK") {
          $(this.state.target).attr('src', '/assets/' + (this.state.voteType == '1' ? 'up' : 'down') + '-fill.png');
          $(this.state.target).data('vote', this.state.voteType + '/' + this.state.postId + '/' + this.state.postType + '/' + data['vote_id']);
          $(this.state.target).parent().siblings('.post-score').text(data['post_score']);
        }
        else if(data['status'] == "modified") {
          $(this.state.target).attr('src', '/assets/' + (this.state.voteType == '1' ? 'up' : 'down') + '-fill.png');
          $(this.state.target).data('vote', this.state.voteType + '/' + this.state.postId + '/' + this.state.postType + '/' + data['vote_id']);
          $("#" + (this.state.postType == 'a' ? 'answer-' : 'question-') + this.state.postId + (this.state.voteType == 1 ? '-down' : '-up'))
            .data('vote', (1-this.state.voteType) + '/' + this.state.postId + '/' + this.state.postType + '/-1')
            .attr('src', '/assets/' + (this.state.voteType == '1' ? 'down' : 'up') + '-clear.png');
          $(this.state.target).parent().siblings('.post-score').text(data['post_score']);
        }
        else {
          alert("Could not cast vote - please try again. Message: " + data);
          console.error("Vote cast failed: " + data);
        }
      })
      .fail(function(jqXHR, textStatus, errorThrown) {
        alert("Could not cast vote - please try again. Message: " + jqXHR.responseText);
        console.error("Vote cast failed: status " + jqXHR.status);
        console.log(jqXHR);
      });
    }
  });


  // Notifications handling
  $("span.notifications").bind("click", function(ev) {
    $.ajax({
      'type': 'GET',
      'url': '/users/me/notifications.json',
      'dd': $(this)
    })
    .done(function(data) {
      $dropdown = $(this.dd).children("ul.dropdown-menu").first();
      $dropdown.html("");
      for(var i = 0; i < data.length; i++) {
        $dropdown.append("<li><a class='notification' data-id='" + data[i].id + "' href='" + data[i].link + "'>" + data[i].content + "</a></li>");
      }
    })
    .fail(function(jqXHR, textStatus, errorThrown) {
      $(this.dd).html("<li><em>Could not retrieve notifications - try again later.</em></li>");
      console.log(jqXHR.responseText);
    });
  });

  $(document).on("DOMNodeInserted", function(ev) {
    if($(ev.target).is("a.notification")) {
      $("a.notification", document).bind("click", function(ev) {
        ev.preventDefault();
        var self = $(this);
        $.ajax({
          'type': 'POST',
          'url': '/notifications/' + self.data("id") + '/read',
          'src': self
        })
        .done(function(data) {
          if(data['status'] !== 'success') {
            console.error("Failed to mark notification as read.");
          }
        })
        .fail(function(jqXHR, textStatus, errorThrown) {
          console.log(jqXHR.responseText);
        })
        .always(function(a, b, c) {
          location.href = $(this.src).attr("href");
        });
      });
    }
  });

});
