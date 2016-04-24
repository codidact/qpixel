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
    var voteType = voteSplat[0],
        postId = voteSplat[1],
        postType = voteSplat[2],
        voteId = voteSplat[3];

    if(voteId > -1) {
      // We've already voted; cancel the vote.
      $.ajax({
        'url': '/votes/' + voteId,
        'type': 'DELETE',
        'target': self
      })
      .done(function(data) {
        if(data === "OK") {
          $(this.target).attr('src', '/assets/' + (voteType == '0' ? 'up' : 'down') + '_clear.png');
        }
        else {
          alert("Could not undo vote - please try again.");
          console.error("Vote undo failed: " + data);
        }
      })
      .fail(function(jqXHR, textStatus, errorThrown) {
        alert("Could not undo vote - please try again.");
        console.error("Vote undo failed: status " + jqXHR.status);
        console.log(jqXHR);
      });
    }
    else {
      // We have yet to vote, so cast one.
      $.ajax({
        'url': '/votes/new',
        'type': 'POST',
        'data': {
          'post_type': postType,
          'post_id': postId,
          'vote_type': voteType
        },
        'target': self
      })
      .done(function(data) {
        if(data === "OK") {
          $(this.target).attr('src', '/assets/' + (voteType == '0' ? 'up' : 'down') + '_fill.png');
        }
        else {
          alert("Could not cast vote - please try again.");
          console.error("Vote cast failed: " + data);
        }
      })
      .fail(function(jqXHR, textStatus, errorThrown) {
        alert("Could not cast vote - please try again.");
        console.error("Vote cast failed: status " + jqXHR.status);
        console.log(jqXHR);
      });
    }
  });

});
