document.addEventListener('DOMContentLoaded', () => {
  document.addEventListener('keypress', (ev) => {
    if (ev.code === 'Escape') {
      document.querySelectorAll('.modal').forEach((el) => el.classList.remove('is-active'));
    }
  });
});
