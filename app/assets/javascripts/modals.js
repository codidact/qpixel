document.addEventListener('DOMContentLoaded', () => {
  document.addEventListener('keyup', (ev) => {
    if (ev.code === 'Escape' && !ev.metaKey && !ev.ctrlKey) {
      document.querySelectorAll('.modal, .droppanel').forEach((el) => {
        el.classList.remove('is-active');
      });
    }
  });
});
