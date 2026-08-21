document.addEventListener('DOMContentLoaded', () => {
  const pref = /** @type {HTMLElement} */(document.querySelector(".community-sortable"));
  const sortable = /** @type {HTMLElement} */(pref.querySelector(".sortable"));
  const input = /** @type {HTMLInputElement} */(pref.querySelector(".js-user-pref"));

  Sortable.create(sortable, {
    onSort: () => {
      const val = [...sortable.children]
        .map(el => /** @type {HTMLElement} */(el).dataset['community'])
        .join(',');

      input.value = val;
      input.dispatchEvent(new Event("change"));
    }
  });
});