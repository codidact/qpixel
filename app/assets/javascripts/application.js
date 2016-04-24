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

    if(voteId > -1) {
      // We've already voted; cancel the vote.
      $.ajax({
        'url': '/votes/' + voteId,
        'type': 'DELETE',
        'state': state
      })
      .done(function(data) {
        if(data === "OK") {
          $(this.state.target).attr('src', '/assets/' + (voteType == '0' ? 'up' : 'down') + '-clear.png');
          $(this.state.target).data('vote', this.state.voteType + '/' + this.state.postId + '/' + this.state.postType + '/-1');
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
        if(data['status'] == "OK") {
          $(this.target).attr('src', '/assets/' + (voteType == '0' ? 'up' : 'down') + '-fill.png');
          $(this.state.target).data('vote', this.state.voteType + '/' + this.state.postId + '/' + this.state.postType + '/' + data['vote_id']);
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

});
