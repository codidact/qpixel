document.addEventListener('DOMContentLoaded', () => {
  const pref = $(".community-sortable");
  const sortable = pref.find(".sortable");

  const input = pref.find(".js-user-pref");

  sortable.sortable({
    appendTo: pref,
    update: () => {
      const val = sortable.children()
        .map((_, el) => el.dataset['community'])
        .toArray()
        .join(',');

      input.val(val);
      input.trigger("change");
    }
  });
});