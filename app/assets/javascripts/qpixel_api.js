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
  },

  addEditorButton: function ($buttonHtml, shortName, callback) {
    const html = `<a href="javascript:void(0)" class="button is-muted is-outlined" title="${shortName}"
                     aria-label="${shortName}"></a>`;
    const $button = $(html).html($buttonHtml);

    const insertButton = () => {
      $('.js-markdown-tools').each((i, e) => {
        const $tgt = $(e);
        let $customGroup = $tgt.find('.button-list.js-custom-tools');
        if ($customGroup.length === 0) {
          $customGroup = $(`<div class="button-list is-gutterless js-custom-tools"></div>`);
          $customGroup.appendTo($tgt);
        }

        $button.clone().on('click', callback).appendTo($customGroup);
      });
    };

    insertButton();
  }
};