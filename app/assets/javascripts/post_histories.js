document.addEventListener('DOMContentLoaded', () => {
  const openRelevantEditOnly = () => {
    const [[, historyId]] = location.hash.split(':~:');

    document.querySelectorAll('details.history-event').forEach((el) => {
      if (el instanceof HTMLDetailsElement) {
        el.open = el.id === historyId;
      }
    });
  };

  window.addEventListener('hashchange', openRelevantEditOnly);
  openRelevantEditOnly();
});
