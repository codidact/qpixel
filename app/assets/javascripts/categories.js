$(() => {
  $('.js-category-tag-set-select').on('change', ev => {
    const $tgt = $(ev.target);
    const tagSetId = $tgt.val();
    const formGroups = $('.js-category-tags-group');
    if (tagSetId) {
      formGroups.each((i, el) => {
        const $el = $(el);
        const $caption = $el.find('.js-tags-group-caption');
        $caption.find('[data-state="absent"]').hide();
        $caption.find('[data-state="present"]').show();

        $el.find('.js-tag-select').attr('data-tag-set', tagSetId).attr('disabled', false);
      });
    }
    else {
      formGroups.each((i, el) => {
        const $el = $(el);
        const $caption = $el.find('.js-tags-group-caption');
        $caption.find('[data-state="absent"]').show();
        $caption.find('[data-state="present"]').hide();

        $el.find('.js-tag-select').attr('data-tag-set', null).attr('disabled', true);
      });
    }
  });

  $('.js-add-required-topic').on('click', ev => {
    const $required = $('.js-required-tags');
    const $topic = $('.js-topic-tags');
    const union = ($required.val() || []).concat($topic.val() || []);

    const options = $topic.find('option').toArray();
    const optionIds = options.map(x => $(x).attr('value'));
    const missing = union.filter(x => !optionIds.includes(x));
    const missingOptions = $required.find('option').toArray().filter(x => missing.includes($(x).attr('value')));

    missingOptions.forEach(opt => {
      const $append = $(opt).clone();
      $append.removeAttr('data-select2-id');
      $topic.append($append);
    });
    $topic.val(union).trigger('change');
  });

  $('.js-category-change-select').each((i, el) => {
    const $tgt = $(el);
    $tgt.select2({
      ajax: {
        url: '/categories',
        headers: { 'Accept': 'application/json' },
        delay: 100,
        processResults: data => ({results: data.map(c => ({id: c.id, text: c.name}))}),
      }
    });
  });

  $('.js-change-category').on('ajax:success', ev => {
    location.reload();
  }).on('ajax:error', (ev, xhr) => {
    const data = xhr.responseJSON;
    QPixel.createNotification('danger', `Failed (${xhr.status}): ${data.errors.join(', ')}`);
  });

  $(document).on('click', '.js-update-cpt', async ev => {
    const $tgt = $(ev.target);
    const $widget = $tgt.parents('.widget');
    const categoryId = $tgt.attr('data-category');
    const postTypeId = parseInt($widget.find('.js-cpt-post-type').val(), 10) || null;
    const upvoteRep = parseInt($widget.find('.js-cpt-upvote-rep').val(), 10) || 0;
    const downvoteRep = parseInt($widget.find('.js-cpt-downvote-rep').val(), 10) || 0;

    const resp = await fetch(`/categories/${categoryId}/edit/post-types`, {
      method: 'POST',
      credentials: 'include',
      body: JSON.stringify({ post_type: postTypeId, upvote_rep: upvoteRep, downvote_rep: downvoteRep }),
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': QPixel.csrfToken()
      }
    });
    const data = await resp.json();
    const status = resp.status;

    if (![200, 201].includes(status) || data.status !== 'success') {
      QPixel.createNotification('danger', `Update failed: ${data.message || status}`);
    }
    else if (status === 200) {
      QPixel.createNotification('success', 'Updated successfully');
    }
    else if (status === 201) {
      $('.js-cpt-list').append(data.html);
      QPixel.createNotification('success', 'Added successfully');
    }
  });

  $(document).on('click', '.js-delete-cpt', async ev => {
    const $tgt = $(ev.target);
    const categoryId = $tgt.attr('data-category');
    const postTypeId = $tgt.attr('data-post-type');

    await fetch(`/categories/${categoryId}/edit/post-types`, {
      method: 'DELETE',
      credentials: 'include',
      body: JSON.stringify({ post_type: postTypeId }),
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': QPixel.csrfToken()
      }
    });
    $tgt.parents('.widget').fadeOut(200, function () {
      $(this).remove();
    });
  });
});