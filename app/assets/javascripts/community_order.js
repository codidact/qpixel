document.addEventListener('DOMContentLoaded', () => {
  const pref = /** @type {HTMLElement} */(document.querySelector(".community-sortable"));
  const el = /** @type {HTMLElement} */(pref.querySelector(".sortable"));
  const input = /** @type {HTMLInputElement} */(pref.querySelector(".js-user-pref"));

  const sortable = Sortable.create(el, {
    store: {
      get: () => input.value.split(','),
      set: self => {
        input.value = self.toArray().join(',');
        input.dispatchEvent(new Event("change"));
      }
    }
  });

  document.querySelectorAll('.community-sortable-list-item').forEach(el => {
    el.querySelector('.sort-up-btn')?.addEventListener('click', _ => {
      el.previousElementSibling?.insertAdjacentElement('beforebegin', el);
      sortable.save();
    });
    el.querySelector('.sort-down-btn')?.addEventListener('click', _ => {
      el.nextElementSibling?.insertAdjacentElement('afterend', el);
      sortable.save();
    });
  })
});